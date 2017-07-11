local util = {}

util.quiet = false -- disable printing
util.log = true    -- disable logging
util.logFile = "/var/log/util.log"
util.errFile = "/var/log/util-errors.log"

local function f(file, data)
  local file = fs.open(file, fs.exists(file) and 'a' or 'w')
  file.write(data.."\n")
  file.close()
end

-- toggleable print() w logging
function util.p(...)
  if not util.quiet then
    print(...)
  end

  if util.log then
    local args = {...}
    local out = ""

    for i=1, #args do
      out = out.."\t"..args[i]
    end

    f(out)
  end
end

-- error() w logging
function util.e(msg)
  f(msg)
  error(msg)
end

local p, e = util.p, util.e

-- assert() using our error function
function util.a(truthy, errMsg)
  if truthy then
    return truthy
  else
    e(errMsg)
  end
end

-- run script string
function util.script(str)
  local ok, result, err = pcall(loadstring(str))
  if not ok then
    e(result)
  end
  if not (result == 0) and err then
    e(err)
  end
end

-- -- run pre/post install/upgrade/remove/purge scripts
-- function util.script(pkg, sID, msg)
--   if pkg[sID] then
--     p("Running "..msg.." script...")
--
--     local ok, result, errMsg = pcall(loadstring(pkg[sID]))
--
--     if not ok then
--       e(msg..'" script errored: "'..result..'"\nAborting.')
--     end
--     if not result == 0 then
--       e(msg..'" script failed: "'..errMsg..'"\nAborting.')
--     end
--   end
-- end

return util
