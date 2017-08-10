-- run multiple programs at startup
local function runFiles(list, dir)
  for _, file in ipairs(list) do
    local path = dir.."/"..file
    if fs.isDir(path) then
      runFiles(fs.list(path), path)
    else
      shell.run(path)
    end
  end
end
runFiles(fs.list('/autorun'), '/autorun')
