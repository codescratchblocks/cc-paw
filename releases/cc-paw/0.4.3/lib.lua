local v = dofile "/lib/semver.lua"
local util = dofile "/lib/cc-paw-util.lua"
local p, e, a, script = util.p, util.e, util.a, util.script

local ccpaw = {}

ccpaw.v = v"0.4.3"

local sources = "/etc/cc-paw/sources.list"
local sCache = "/var/cache/cc-paw/sources/"
local iCache = "/var/cache/cc-paw/installed/"
local rCache = "/var/cache/cc-paw/removed/"

-- fs.open() with error messaging! :D
local function open(file, mode)
    return a(fs.open(file, mode), 'Could not open "'..file..'" in "'..mode..'" mode.')
end

-- wrapper to write a file
local function write(fName, data)
    local file = open(fName, 'w')
    file.write(data)
    file.close()
end

-- get file content by URL
local function get(url)
    --NOTE for now, assumes HTTP API must be used, in the future, local gets will be possible
    local response = a(http.get(url, {["User-Agent"] = "cc-paw "..tostring(ccpaw.v)}), 'Error opening "' .. url .. '"')

    local status = response.getResponseCode()
    if status == 200 then
        local result = response.readAll()
        response.close()
        return result
    else
        e('GET ' .. url .. ' : ' .. status)
    end
end

-- install a package by its name
-- version is a string representing the version you want to install, optional
-- options.force (bool) will allow installation of incompatible updates
-- options.exact (bool) will force installation to attempt installing the exact specified version from whichever repo has a version
-- options.root (string) will allow specifying where to install from (NOTE NOT IMPLEMENTED!)
-- options.ignoreInst (bool) will ignore an already installed package instead of erroring
function ccpaw.install(pkgName, version, options)
    if version then
        version = v(version)
    end

    if not options then
        options = {}
    end

    if fs.exists(iCache..pkgName) then
        if options.ignoreInst then
            local file = open(iCache..pkgName, 'r')
            local package = textutils.unserialize(file.readAll())
            file.close()

            if options.exact then
                if v(package.version) == version then
                    return true
                else
                    e("Package "..pkgName.." EXACT version "..tostring(version).." required, but v"..package.version.." installed.")
                end
            else
                -- if our version is better or equal, and compatible..
                if v(package.version) >= version and version ^ v(package.version) then
                    return true
                else
                    e("Package "..pkgName.." v"..tostring(version).." required, but incompatible v"..package.version.." installed.")
                end
            end

        else
            e("Package "..pkgName.." already installed.\n(Perhaps you meant to upgrade?)")
        end
    end

    p "Reading sources..."

    -- root to grab files from, line of sources to read from, package version to install
    local root, sLine, pkgVersion

    for _, fName in ipairs(fs.list(sCache)) do
        local file = open(sCache .. fName, 'r')

        local line = file.readLine()
        --NOTE see how a source lower in the sources list is chosen over one higher in the list !
        while line and line:len() > 0 do
            if line:sub(1, line:find("=")-1) == pkgName then
                sLine = fName -- this file name is the line number it came from in sources
                pkgVersion = v(line:sub(line:find("=")+1))
            end
            line = file.readLine()
        end

        file.close()
    end

    a(sLine, 'Package '..pkgName..' not found.\n(Try "cc-paw update" first?)')

    if options.exact then
        pkgVersion = version
    end

    if version and not version ^ pkgVersion and not options.force then
        e(pkgName.." v"..tostring(version).." requested, but only v"..tostring(pkgVersion).." is available, and not compatible.")
    end

    local file = open(sources, 'r')
    for i=1,sLine do
        root = file.readLine()
    end
    file.close()

    p("Getting package info ("..pkgName..")...")

    local pkgData = get(root..pkgName.."/"..tostring(pkgVersion).."/pkg.lua")
    local package = textutils.unserialize(pkgData)

    a(package.confVersion > 1, "Version 1 package configurations are not supported. Please contact the package maintainer.")
    a(package.confVersion == 2, "You must upgrade cc-paw to install this package.")

    if package.depends then
        p("Installing dependencies for "..pkgName.."...")
        for pkg, vers in pairs(package.depends) do
            ccpaw.install(pkg, vers, {ignoreInst = true, force = options.force})
        end
    end

    if package.dependsExact then
        p("Installing dependencies for "..pkgName.."...")
        for pkg, vers in pairs(package.dependsExact) do
            ccpaw.install(pkg, vers, {exact = true, ignoreInst = true, force = options.force})
        end
    end

    p("Installing "..pkgName.."...")

    script(package, "preinst", "pre-install")

    if package.files then
        for fName, location in pairs(package.files) do
            local data = get(root..pkgName.."/"..tostring(pkgVersion).."/"..location)
            write(fName, data)
        end
    end

    if package.filesOnce then
        for fName, location in pairs(package.filesOnce) do
            if not fs.exists(fName) then
                local data = get(root..pkgName.."/"..tostring(pkgVersion).."/"..location)
                write(fName, data)
            end
        end
    end

    script(package, "postinst", "post-install")

    write(iCache..pkgName, pkgData)
    if fs.exists(rCache..pkgName) then
        fs.delete(rCache..pkgName)
    end

    p(pkgName.." installed.")

    return true
end

function ccpaw.remove(pkgName)
    p("Removing "..pkgName.."...")

    local file = open(iCache..pkgName, 'r')
    local package = textutils.unserialize(file.readAll())
    file.close()

    script(package, "prerm", "pre-remove")

    if package.files then
        for fName, _ in pairs(package.files) do
            fs.delete(fName)
        end
    end

    script(package, "postrm", "post-remove")

    fs.move(iCache..pkgName, rCache..pkgName)   -- now is a removed package

    p(pkgName.." removed.")

    return true
end

function ccpaw.purge(pkgName)
    ccpaw.remove(pkgName)

    p("Purging "..pkgName.."...")

    local file = open(rCache..pkgName, 'r')
    local package = textutils.unserialize(file.readAll())
    file.close()

    script(package, "prepurge", "pre-purge")

    if package.filesOnce then
        for fName, _ in pairs(package.files) do
            fs.delete(fName)
        end
    end

    script(package, "postpurge", "post-purge")

    fs.delete(rCache..pkgName)

    p(pkgName.." purged.")

    return true
end

function ccpaw.update()   --TODO allow specifying a line number to update from ?
    p "Updating sources..."

    local file = open(sources, 'r')

    local line = file.readLine()
    local cFile = 1   -- cache file names are their line in sources

    while line and line:len() > 0 do
        local data = get(line.."/packages.list")
        write(sCache..cFile, data)

        line = file.readLine()
        cFile = cFile + 1
    end

    file.close()

    p "Done."

    return true
end

--TODO upgrades need to prevent upgrading of packages where an exact version is depended on by another package
--TODO upgrades need to be smart enough to complete system wide incompatible upgrades
-- installs available and compatible upgrades
-- options.force (bool) will allow installation of incompatible updates
function ccpaw.upgrade(pkgName, options)
    if not options then
        options = {}
    end

    if not pkgName then
        p "Upgrading all packages."

        for _, package in ipairs(fs.list(iCache)) do
            ccpaw.upgrade(package)
        end

        p "Upgrades complete."

        return true
    end

    p "Reading sources..."

    -- NOTE how this is a literal copy from another part of this code, fix this !
    -- root to grab files from, line of sources to read from, package version to install
    local root, sLine, pkgVersion

    for _, fName in ipairs(fs.list(sCache)) do
        local file = open(sCache .. fName, 'r')

        local line = file.readLine()
        --NOTE see how a source lower in the sources list is chosen over one higher in the list !
        while line and line:len() > 0 do
            if line:sub(1, line:find("=")-1) == pkgName then
                sLine = fName -- this file name is the line number it came from in sources
                pkgVersion = v(line:sub(line:find("=")+1))
            end
            line = file.readLine()
        end

        file.close()
    end

    a(sLine, 'Package '..pkgName..' not found.\n(Try "cc-paw update" first?)')
    -- END where I literally copied from

    local file = open(sources, 'r')
    for i=1,sLine do
        root = file.readLine()
    end
    file.close()

    local file = open(iCache..pkgName, 'r')
    local pkgData = file.readAll()
    local package = textutils.unserialize(pkgData)
    file.close()

    if pkgVersion == v(package.version) then
        return false
    else
        if v(package.version) ^ pkgVersion or options.force then

            -- Almost completely copied massive section
            if package.depends then
                p("Checking dependencies for "..pkgName.."...")
                for pkg, vers in pairs(package.depends) do
                    ccpaw.install(pkg, vers, {ignoreInst = true, force = options.force})
                end
            end

            if package.dependsExact then
                p("Checking dependencies for "..pkgName.."...")
                for pkg, vers in pairs(package.dependsExact) do
                    ccpaw.install(pkg, vers, {exact = true, ignoreInst = true, force = options.force})
                end
            end

            p("Upgrading "..pkgName.."...")

            script(package, "preupgd", "pre-upgrade")

            if package.files then
                for fName, location in pairs(package.files) do
                    local data = get(root..pkgName.."/"..tostring(pkgVersion).."/"..location)
                    write(fName, data)
                end
            end

            if package.filesOnce then
                for fName, location in pairs(package.filesOnce) do
                    if not fs.exists(fName) then
                        local data = get(root..pkgName.."/"..tostring(pkgVersion).."/"..location)
                        write(fName, data)
                    end
                end
            end

            script(package, "postupgd", "post-upgrade")

            write(iCache..pkgName, pkgData)

            p(pkgName.." upgraded.")
            -- End almost completely copied massive section.

            return true
        else
            --e("Package "..pkgName.." held at v"..package.version.." because update candidate is incompatible v"..pkgVersion)
            -- the only error that doesn't actually error, because this needs to be acceptable within a loop of upgrades
            p("Package "..pkgName.." held at v"..package.version.." because update candidate is incompatible v"..tostring(pkgVersion))
            return false
        end
    end
end

return ccpaw
