local v = dofile "/lib/semver.lua"

local ccpaw = {}

ccpaw.v = v"0.4.0"
ccpaw.print = true

local sources = "/etc/cc-paw/sources.list"
local sCache = "/var/cache/cc-paw/sources/"
local iCache = "/var/cache/cc-paw/installed/"

-- our own print function to allow toggling output with ccpaw.print
local function p(...)
    if ccpaw.print then
        print(...)
    end
end

-- our own error function to log errors
local function e(msg)
    local errFile = "/var/log/cc-paw-errors.log"
    local file = fs.open(errFile, fs.exists(errFile) and 'a' or 'w')
    file.write(msg.."\n")
    file.close()
    error(msg)
end

-- our own assert to make sure our own error is used
local function a(truthy, errMsg)
    if truthy then
        return truthy
    else
        e(errMsg)
    end
end

-- open a file, error on failure
local function open(file, mode)
    if mode == 'r' then
        return a(fs.open(file, mode), 'Could not open "'..file..'" for reading.')
    elseif mode == 'w' then
        return a(fs.open(file, mode), 'Cound not open "'..file..'" for writing.')
    else
        return a(fs.open(file, mode), 'Could not open "'..file..'"')
    end
end

-- wrapper for basic file writing
local function write(fName, data)
    local file = open(fName, 'w')
    file.write(data)
    file.close()
end

-- gets a file's content (as a string)
local function get(url)
    --NOTE for now, assumes HTTP API must be used, in the future, local gets will be possible
    local response = a(http.get(url, {["User-Agent"] = "cc-paw "..ccpaw.v}), 'Error opening "' .. url .. '"')

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
-- options.root (string) will allow specifying where to install from (NOT IMPLEMENTED!)
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
            --TODO CHECK COMPATIBILITY (installed needs to be greater than requested and a compatible upgrade from requested)
            --TODO CHECK EXACT COMPATIBILITY (if options.exact, then needs to be exactly equal version !!)
            return true
        else
            e("Package already installed.\n(Perhaps you meant to upgrade?)")
        end
    end

    p "Reading sources..."

    -- root to grab files from, line of sources to read from, package version to install
    local root, sLine, pkgVersion

    for _, fName in ipairs(fs.list(sCache)) do
        local file = open(sCache .. fName, 'r')

        local line = file.readLine()
        --NOTE see how a source lower in the sources list is chosen over one higher in the list !
        while line do
            if line:sub(1, line:find("=")-1) == pkgName then
                sLine = fName -- this file name is the line number it came from in sources
                pkgVersion = v(line:sub(line:find("=")+1))
            end
            line = file.readLine()
        end

        file.close()
    end

    a(sLine, 'Package not found.\n(Try "cc-paw update" first?)')

    if options.exact then
        pkgVersion = version
    end

    if version and not version ^ pkgVersion and not options.force then
        e(pkgName.." v"..version.." requested, but only v"..pkgVersion.." is available, and not compatible.")
    end

    local file = open(sources, 'r')
    for i=1,sLine do
        root = file.readLine()
    end
    file.close()

    p "Getting package info ("..pkgName..")..."

    local pkgData = get(root..pkgName.."/"..pkgVersion.."/pkg.lua")
    local package = textutils.unserialize(pkgData)

    a(package.confVersion == 2, "You must upgrade cc-paw to install this package.")

    if package.depends then
        p "Installing dependencies for "..pkgName.."..."
        for pkg, vers in pairs(package.depends) do
            ccpaw.install(pkg, vers, {ignoreInst = true})
        end
    end

    if package.dependsExact then
        p "Installing dependencies for "..pkgName.."..."
        for pkg, vers in pairs(package.dependsExact) do
            ccpaw.install(pkg, vers, {exact = true, ignoreInst = true})
        end
    end

    p "Installing "..pkgName.."..."

    if package.preinst then
        p "Running pre-install script..."

        ok, result, msg = pcall(loadstring(package.preinst)())

        if not ok then
            e('Pre-install script errored: "'..result..'"\nAborting installation.')
        end
        if not result == 0 then
            e('Pre-install script failed: "'..msg..'"\nAborting installation.')
        end
    end

    if package.files then
        for fName, location in pairs(package.files) do
            local data = get(root..pkgName.."/"..pkgVersion.."/"..location)
            write(fName, data)
        end
    end

    if package.filesOnce then
        for fName, location in pairs(package.files) do
            if not fs.exists(fName) then
                local data = get(root..pkgName.."/"..pkgVersion.."/"..location)
                write(fName, data)
            end
        end
    end

    if package.postinst then
        p "Running post-install script..."

        ok, result, msg = pcall(loadstring(package.postinst)())

        if not ok then
            e('Post-install script errored: "'..result..'"\nAborting installation.')
            --TODO undo changes ! (which means I can't use error!)
        end
        if not result == 0 then
            e('Post-install script failed: "'..msg..'"\nAborting installation.')
            --TODO undo changes ! (which means I can't use error!)
        end
    end

    write(iCache..pkgName, pkgData)

    p(pkgName.." installed.")

    return true
end

function ccpaw.remove(pkgName)
    p "Removing "..pkgName.."..."

    local file = open(iCache..pkgName, 'r')
    local package = textutils.unserialize(file.readAll())
    file.close()

    --TODO ACTUALLY REMOVE STUFF

    p(pkgName.." removed.")

    return true
end

function ccpaw.update()
    p "Updating sources..."

    local file = open(sources, 'r')

    local line = file.readLine()
    local cFile = 1   -- cache file names are their line in sources

    while line do
        local data = get(line)
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
function ccpaw.upgrade()
    --
end

return ccpaw
