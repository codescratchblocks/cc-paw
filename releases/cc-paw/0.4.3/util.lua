local util = {}

util.quiet = false
util.log = true

local logFile = "/var/log/cc-paw.log"
local errFile = "/var/log/cc-paw-errors.log"

-- print() with output toggling and logging
function util.p(...)
    if not util.quiet then
        print(...)
    end

    if util.log then
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

-- error() with logging
function util.e(msg)
    local file = fs.open(errFile, fs.exists(errFile) and 'a' or 'w')

    file.write(msg.."\n")
    file.close()

    error(msg)
end

-- assert() using our error function
function util.a(truthy, errMsg)
    if truthy then
        return truthy
    else
        e(errMsg)
    end
end

local p, e, a = util.p, util.e, util.a

-- run pre/post install/upgrade/remove/purge scripts
function util.script(pkg, id, msg)
    if package[id] then
        p("Running "..msg.." script...")

        ok, result, errMsg = pcall(loadstring(pkg[id])())

        if not ok then
            e(msg..'" script errored: "'..result..'"\nAborting.')
        end
        if not result == 0 then
            e(msg..'" script failed: "'..errMsg..'"\nAborting.')
        end
    end
end

return util
