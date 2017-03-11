local ccpaw = dofile "/lib/cc-paw.lua"

local args = {...}

local function usage()
  print("cc-paw version " .. tostring(ccpaw.v) .. ". Usage:")
  print("cc-paw install <package> [-f]")
  print("cc-paw remove <package> [-f]")
  print("cc-paw purge <package> [-f]")
  print("cc-paw update")
  print("cc-paw upgrade [-f]")
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
    ccpaw.install(args[2], nil, {force = (args[3] == "-f") or (args[3] == "--force")})
  end
elseif (args[1] == "remove") then
  if enoughArgs(2) then
    ccpaw.remove(args[2], {force = (args[3] == "-f") or (args[3] == "--force")})
  end
elseif (args[1] == "purge") then
  if enoughArgs(2) then
    ccpaw.purge(args[2], {force = (args[3] == "-f") or (args[3] == "--force")})
  end
elseif (args[1] == "update") then
  ccpaw.update()
elseif (args[1] == "upgrade") then
  local force = (args[2] == "-f") or (args[2] == "--force")
  if ccpaw.upgrade("cc-paw", {force = force}) then
    print("CC-PAW upgraded, please run \"cc-paw upgrade\" again to upgrade packages.")
  else
    ccpaw.upgrade(nil, {force = force})
  end
elseif (args[1] == "-v") or (args[1] == "--version") then
  print("cc-paw version " .. tostring(ccpaw.v))
else
  print("Invalid command: \"" .. tostring(args[1]) .. "\"")
  usage()
end
