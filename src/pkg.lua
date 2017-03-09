{
  name = "cc-paw",
  title = "ComputerCraft Package Administration Worker",
  description = "A package manager for ComputerCraft.",
  author = "Guard13007 <paul.liverman.iii@gmail.com>",
  license = "MIT",
  source = "https://github.com/cc-paw/cc-paw",
  version = "0.5.0",
  confVersion = 2,
  files = {
    ["/bin/cc-paw"] = "bin.lua",
    ["/lib/cc-paw.lua"] = "lib.lua",
    ["/lib/cc-paw-util.lua"] = "util.lua",
    ["/startup"] = "../common/startup.lua",
    ["/autorun/fakeUnixFHS.lua"] = "../common/autorun.lua",
    ["/usr/man/cc-paw"] = "manual.txt"
  },
  filesOnce = {
    ["/etc/cc-paw/sources.list"] = "../common/sources.list"
  },
  depends = {
    ["semver"] = "1.2.1"
  },
  postpurge = [[
    shell.run("rm", "/etc/cc-paw*")
    shell.run("rm", "/var/cache/cc-paw*")
    shell.run("rm", "/var/log/cc-paw*")
    return 0
  ]]
}
