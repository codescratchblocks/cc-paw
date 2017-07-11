local v = dofile "/lib/semver.lua"
local util = dofile "/lib/cc-paw-util.lua"
local p, e, a = util.p, util.e, util.a

local ccpaw = {
  v = v"0.6.0",
  verbose = false
}

local cache = "/var/cache/cc-paw/"
local sources = "/etc/cc-paw/sources.list"
local sCache = cache.."sources/"
local iCache = cache.."installed/"
local rCache = cache.."removed/"
local dCache = cache.."provides/"

util.logFile = "/var/log/cc-paw.log"
util.errFile = "/var/log/cc-paw-errors.log"

local function read(file)
  return a(fs.open(file,'r'), "Could not read "..file)
end

local function readAll(file)
  file = read(file)
  local result = file.readAll()
  file.close()
  return result
end

function ccpaw.vlog(...)
  if ccpaw.verbose then
    p(...)
  end
end

local function write(file, data)
  vlog("Writing to "..file)
  file = fs.open(file, 'w')
  file.write(data)
  file.close()
end

-- get file content by http://, https://, or file://
local function get(url)
  local response
  if (url:sub(1,7) == "http://") or (url:sub(1,8) == "https://") then
    response = a(http.get(url, {["User-Agent"]="cc-paw "..tostring(ccpaw.v)}), "Error opening connection to "..url)
    local status = response.getResponseCode()
    if not (status == 200) then
      e("GET "..url.." : "..status)
    end
  elseif url:sub(1,7) == "file://" then
    response = read(url:sub(8))
  end

  local result = response.readAll()
  response.close()
  return result
end

local function fpairs(tab, fn)
  if tab then
    for a,b in pairs(tab) do fn(a,b) end
  end
end

local function script(str, name)
  if str then
    p("Running "..name.." script...")
    util.script(str)
  end
end

local function getPackageRootAndVersion(name, options)
  local root, sLine, version
  -- if options.root then
  --   root = options.root
  --   -- TODO get packages.list from root, parse and find our version
  --   -- need to get a file, and read lines until we find our package and its version
  --   local data = get(root.."/packages.list")
  --   -- TODO write iterator for strings based on lines within them
  -- else
    p "Reading sources..."

    for _, fName in ipairs(fs.list(sCache)) do
      local file = read(sCache..fName)
      local line = file.readLine()
      --NOTE document how the first source found is returned
      while line and line:len() > 0 do
        if line:sub(1, line:find("=") - 1) == name then
          sLine = fName -- remember that cache file names are also line number from sources.list
          version = v(line:sub(line:find("=") + 1))
          break
        end
        line = file.readLine()
      end
      file.close()
    end

    a(sLine, "Package "..name..' not found.\n(Try "cc-paw update" first?)')

    local file = read(sources)
    for i=1,sLine do
      root = file.readLine()
    end
    file.close()
  --end

  return root, version
end

local function writeDependencyCache(pkg, ver)
  local provides = {}
  if fs.exists(dCache..pkg) then
    provides = textutils.unserialize(readAll(dCache..pkg))
  end
  provides[name] = ver
  write(dCache..pkg, textutils.serialize(provides))
end

-- install package by name
-- version is optional
-- options.force (bool) will allow installation of incompatible versions
-- options.exact (bool) will force installing specified version instead of trying to install compatible upgrades TODO not fully implemented
-- options.root (string) allows specifying an alternate root to install from TODO fix/finish feature
-- options.ignoreInst (bool) will ignore already installed packages instead of erroring
function ccpaw.install(name, version, options)
  if version then
    version = v(version)
  end
  if not options then
    options = {}
  end

  if fs.exists(iCache..name) then
    if options.ignoreInst and version then --TODO document version is required with ignoreInst option
      local package = textutils.unserialize(readAll(iCache..name))

      if options.exact then
        if v(package.version) == version then
          return true
        else
          e("Package "..name.." EXACT version "..tostring(version).." required, but v"..package.version.." installed.")
        end
      else
        if v(package.version) >= version and version ^ v(package.version) then
          return true
        else
          e("Package "..name.." v"..tostring(version).." required, but incompatible v"..package.version.." installed.")
        end
      end

    else
      e("Package "..name.." already installed.\n(Perhaps you meant to upgrade?)")
    end
  end

  local root, pkgVersion = getPackageRootAndVersion(name, options)

  if options.exact then
    --TODO somehow we need to choose a different version than what getPackageRootAndVersion() selected
    -- this also involves selecting a different root potentially
    pkgVersion = version
    -- super lazy right now assumes the root is valid
  end

  -- if asking for specific version, selected version is not an upgrade of that version, and not force-installing..
  if version and not version ^ pkgVersion and not options.force then
    e(name.." v"..tostring(version).." requested, but only v"..tostring(pkgVersion).." is available, and not compatible.")
  end

  p("Getting package info ("..name..")...")

  --TODO I really feel like pkg.lua should be package.lua
  local package = textutils.unserialize(get(root..name.."/"..tostring(pkgVersion).."pkg.lua"))

  a(package.confVersion > 1, "Version 1 package configurations are not supported. Please contact the package maintainer.")
  a(package.confVersion == 2, "You must upgrade cc-paw to install this package.")

  if package.depends or package.dependsExact then
    p("Installing dependencies for "..name)
    fpairs(package.depends, function(pkg, ver)
      ccpaw.install(pkg, ver, {ignoreInst=true,force=options.force})
      writeDependencyCache(pkg, true)
    end)
    fpairs(package.dependsExact, function(pkg, ver)
      ccpaw.install(pkg, ver, {exact=true,ignoreInst=true,force=options.force})
      writeDependencyCache(pkg, ver)
    end)
  end

  p("Installing "..name)
  script(package.preinst, "pre-install")

  fpairs(package.files, function(file, source)
    if fs.exists(file) and not options.force then
      e(name..' needs to install a file to "'..file..'" but that file exists. Installation aborted.')
    else
      write(file, get(root..name.."/"..tostring(pkgVersion).."/"..source))
  end)
  fpairs(package.filesOnce, function(file, source)
    if not fs.exists(file) then
      write(file, get(root..name.."/"..tostring(pkgVersion).."/"..source))
    end
  end)

  script(package.postinst, "post-install")

  package.preinst = nil
  package.postinst = nil
  write(iCache..name, textutils.serialize(package))
  if fs.exists(rCache..name) then
    fs.delete(rCache..name)
  end

  return true
end

-- options.force (bool) will allow removal of required packages
function ccpaw.remove(name, options)
  -- is it installed?
  if not fs.exists(iCache..name) then
    e(name.." not installed.")
  end
  -- check that nothing depends on it
  local provides = textutils.unserialize(readAll(dCache..name))
  if not options.force then
    fpairs(provides, function(pkg, ver)
      if fs.exists(iCache..pkg) then
        e(name.." is required for "..pkg)
      end
    end)
  end

  p("Removing "..name)

  local package = textutils.unserialize(readAll(iCache..name))

  script(package.prerm, "pre-remove")

  fpairs(package.files, function(file)
    fs.delete(file)
  end)

  script(package.postrm, "post-remove")

  package.prerm = nil
  package.postrm = nil
  package.files = nil
  fs.delete(iCache..name)
  fs.delete(dCache..name) --NOTE does this error if it doesn't exist?
  write(rCache..name, textutils.serialize(package))

  p(name.." removed.")
  return true
end

-- options.force (bool) will allow purging required packages
function ccpaw.purge(name, options)
  if fs.exists(iCache..name) then
    if not ccpaw.remove(name, options) then
      return false
    end
  end

  p("Purging "..name)

  local package = textutils.unserialize(readAll(rCache..name))

  script(package.prepurge, "pre-purge")
  fpairs(package.filesOnce, function(file)
    fs.delete(file)
  end)
  script(package.postpurge, "post-purge")

  fs.delete(rCache..name)

  -- prevents cc-paw from writing files after purging itself
  if name == "cc-paw" then
    print("cc-paw purged.")
  else
    p(name.." purged.")
  end

  return true
end

--TODO allow specifying a line number to update only that source ?
function ccpaw.update()
  p "Updating sources..."

  local file = read(sources)

  local line = file.readLine()
  local cFile = 1   -- cache file names are their line number from sources.list

  while line and line:len() > 0 do
    local data = get(line.."/packages.list")
    write(sCache..cFile, data)

    line = file.readLine()
    cFile = cFile + 1
  end

  file.close()

  return true
end

--TODO prevent upgrading packages required to be an exact version
--TODO system wide incompatible upgrades
--TODO see if any common code between this and install can be broken out
-- installs available, compatible upgrades
-- options.force (bool) will allow installation of incompatible upgrades
function ccpaw.upgrade(name, options)
  if not options then
    options = {}
  end

  if not name then
    p "Upgrading all packages."
    for _, package in ipairs(fs.list(iCache)) do
      ccpaw.upgrade(package)
    end
    p "Upgrades complete."
    return true
  end

  local root, version = getPackageRootAndVersion(name, options)
  local package = textutils.unserialize(readAll(iCache..name))

  if version == v(package.version) then
    return false
  else
    -- if upgradable or forced
    if v(package.version) ^ version or options.force then

      if package.depends or package.dependsExact then
        p("Checking dependencies for "..name)
        fpairs(package.depends, function(pkg, ver)
          ccpaw.install(pkg, ver, {ignoreInst=true,force=options.force})
        end)
        fpairs(package.dependsExact, function(pkg, ver)
          ccpaw.install(pkg, ver, {exact=true,ignoreInst=true,force=options.force})
        end)
      end

      p("Upgrading "..name)
      script(package.preupgd, "pre-upgrade")

      fpairs(package.files, function(file, source)
        write(file, get(root..name.."/"..tostring(version).."/"..location))
      end)
      fpairs(package.filesOnce, function(file, source)
        if not fs.exists(file) then
          write(file, get(root..name.."/"..tostring(version).."/"..location))
        end
      end)

      script(package.postupgd, "post-upgrade")
      p(name.." upgraded.")

      return true
    else
      -- this "error" uses print because it needs to be acceptable within a loop of upgrades
      --NOTE current mechanisms do not allow for a host to store info of multiple versions available
      --      this can be a problem in the future...
      p("Package "..name.." hend at v"..package.version.." because update candidate is incompatible v"..tostring(version))
      return false
    end
  end
end

return ccpaw
