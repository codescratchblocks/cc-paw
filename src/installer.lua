-- This file is available at http://pastebin.com/VmqguQeA
--  Or, to install CC-PAW, use "pastebin run VmqguQeA" :)

local ccpaw = {}

ccpaw.v = "0.4.0"
ccpaw.quiet = true
ccpaw.log = true

local sCache = "/var/cache/cc-paw/sources/"
local iCache = "/var/cache/cc-paw/installed/"
local logFile = "/var/log/cc-paw.log"
local errFile = "/var/log/cc-paw-errors.log"

local function p(...)
    if not ccpaw.quiet then
        print(...)
    end

    if ccpaw.log then
        local args = {...}
        local out = ""

        for i = 1, #args do
            out = out .. "\t" .. args[i]
        end

        local file = fs.open(logFile, fs.exists(logFile) and 'a' or 'w')

        file.write(out .."\n")
        file.close()
    end
end

local function e(msg)
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

local function open(file, mode)
    if mode == 'r' then
        return a(fs.open(file, mode), 'Could not open "'..file..'" for reading.')
    elseif mode == 'w' then
        return a(fs.open(file, mode), 'Cound not open "'..file..'" for writing.')
    else
        return a(fs.open(file, mode), 'Could not open "'..file..'"')
    end
end

local function write(fName, data)
    local file = open(fName, 'w')
    file.write(data)
    file.close()
end

local function get(url)
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

function ccpaw.install(pkgName)
    local root, pkgVersion = "https://cc-paw.github.io/cc-paw/releases/", "0.4.0"

    local file = open(sCache.."1", 'r')

    local line = file.readLine()
    while line do
        if line:sub(1, line:find("=")-1) == pkgName then
            pkgVersion = line:sub(line:find("=")+1)
        end
        line = file.readLine()
    end

    file.close()

    local pkgData = get(root..pkgName.."/"..pkgVersion.."/pkg.lua")
    local package = textutils.unserialize(pkgData)

    a(package.confVersion > 1, "Something impossible happened, start over entirely: https://cc-paw.github.io/")
    a(package.confVersion == 2, "You must download a newer installer: https://cc-paw.github.io/")

    if package.depends then
        for pkg, vers in pairs(package.depends) do
            ccpaw.install(pkg)
        end
    end

    if package.dependsExact then
        for pkg, vers in pairs(package.dependsExact) do
            ccpaw.install(pkg)
        end
    end

    if package.preinst then
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
        ok, result, msg = pcall(loadstring(package.postinst)())

        if not ok then
            e('Post-install script errored: "'..result..'"\nAborting installation.')
        end
        if not result == 0 then
            e('Post-install script failed: "'..msg..'"\nAborting installation.')
        end
    end

    write(iCache..pkgName, pkgData)
end

function ccpaw.update()
    local data = get("https://cc-paw.github.io/cc-paw/releases/packages.list")
    write(sCache.."1", data)
end

print "Installing CC-PAW..."
ccpaw.update()
ccpaw.install("cc-paw")
shell.run("/startup")
print "Done. :D"
