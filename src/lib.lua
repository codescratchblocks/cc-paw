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

local function e(msg)
    local errFile = "/var/log/cc-paw-errors.log"
    local file = fs.open(errFile, fs.exists(errFile) and 'a' or 'w')
    file.write(msg.."\n")
    file.close()
    error(msg)
end

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
--TODO force option is about forcing an install of specified version, will attempt to use source where package is found, but specified version instead of latest
function ccpaw.install(pkgName, version, force)
    if version then
        version = v(version)
    end

    if fs.exists(iCache..pkgName) then
        e("Package already installed.\n(Perhaps you meant to upgrade?)")
    end

    p "Reading sources..."

    local root, sLine, pkgVersion

    for _, fName in ipairs(fs.list(sCache)) do
        local file = open(sCache .. fName, 'r')

        local line = file.readLine()
        while line do
            if line:sub(1, line:find("=")-1) == pkgName then
                sLine = fName -- the line number in sources will be this file's name
                pkgVersion = v(line:sub(line:find("=")+1))
            end
        end

        file.close()
    end

    a(sLine, 'Package not found.\n(Try "cc-paw update" first?)')

    if version and not version ^ pkgVersion then
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
            ccpaw.install(pkg, vers)
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
            local file = open(fName, 'w')
            file.write(data)
            file.close()
        end
    end

    if package.filesOnce then
        for fName, location in pairs(package.files) do
            if not fs.exists(fName) then
                local data = get(root..pkgName.."/"..pkgVersion.."/"..location)
                local file = open(fName, 'w')
                file.write(data)
                file.close()
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

    --TODO save iCache
    --fs.exists(iCache..pkgName) then
    local file = open(iCache..pkgName, 'w')
    file.write(pkgData)
    file.close()

    p pkgName.." installed."
end

function ccpaw.remove(pkgName)
    --
end

function ccpaw.update()
    p "Updating sources..."

    local file = open(sources, 'r')

    local line = file.readLine()
    local count = 1

    while line do
        local data = get(line)
        local list = open(sCache .. count, 'w')

        list.write(data)
        list.close()

        line = file.readLine()
        count = count + 1
    end

    file.close()

    p "Done."
end

function ccpaw.upgrade()
    --
end

return ccpaw
