-- run multiple programs at startup
local function runFiles(fList,dir)
  for _,f in ipairs(fList) do
    if fs.isDir(dir.."/"..f) then
      runFiles(fs.list(f),dir.."/"..f)
    else
      shell.run(dir.."/"..f)
    end
  end
end
runFiles(fs.list('/autorun'),'/autorun')
