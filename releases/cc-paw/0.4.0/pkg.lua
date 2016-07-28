{
  name = "cc-paw",
  title = "ComputerCraft Package Administration Worker",
  description = "A package manager for ComputerCraft.",
  author = "Guard13007",
  confVersion = 2,
  files = {
    ["/bin/cc-paw"] = "cc-paw.lua"
  },
  filesOnce = {
    ["/etc/cc-paw/sources.list"] = "../common/sources.list"
  },
  depends = {
    ["semver"] = "1.2.0"
  }
}
