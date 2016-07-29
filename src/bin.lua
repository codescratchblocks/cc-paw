local ccpaw = dofile "/lib/cc-paw.lua"

local args = {...}

local function usage()
  print("cc-paw version " .. ccpaw.v .. ". Usage:")
  print("cc-paw install <package>")
  print("cc-paw remove <package>")
  print("cc-paw update")
  print("cc-paw upgrade")
  print("For more usage information, type \"man cc-paw\"")
end

local function enoughArgs(minimum)
  if #args < minimum then
    print("Invalid command syntax.")
    usage()
    return false
  else
    return true
  end
end

if (args[1] == "install") then
  if enoughArgs(2) then
    ccpaw.install(args[2])
  end
elseif (args[1] == "remove") then
  if enoughArgs(2) then
    ccpaw.remove(args[2])
  end
elseif (args[1] == "update") then
  ccpaw.update()
elseif (args[1] == "upgrade") then
  ccpaw.upgrade()
elseif (args[1] == "-v") or (args[1] == "--version") then
  print("cc-paw version " .. ccpaw.v)
else
  print("Invalid command: \"" .. args[1] .. "\"")
  usage()
end
