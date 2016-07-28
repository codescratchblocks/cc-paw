-- A repo has a defined ROOT (ex: https://cc-repo.guard13007.com/ ) which contains a "packages.list" file.
-- This file is a list of names representing what packages are available here and their latest version (ex: example-package=2.3.9-dev ).
-- Each version of a package is defined by a file located at ROOT .. NAME .. "/" .. VERSION .. "/pkg.lua"
--  where NAME and VERSION are as defined in "packages.list" (ex: https://cc-repo.guard13007.com/example-package/2.3.9-dev/pkg.lua ).

-- This file represents a particular version of a package (a pkg.lua file). It contains some info about the package,
--  as well as files and scripts to execute for installing and uninstalling this version of the package.

{ -- note that the version is not included, since it comes from the URL used to fetch this package
  name = "example-package",     -- used internally to identify packages
  title = "An Example Package", -- a human readable title / brief description of the package
  description = "An example package.",
  author = "Example Name <email@example.com>", -- note: email address not required!
  confVersion = 2,                             -- the version of this config format
  -- NOTE: Anything below here is optional, depending on what a particular package needs to define.
  files = {
    ["/local/location"] = "example.file"   -- this is retrieved from ROOT .. NAME .. "/" .. VERSION .. "/" .. FILE (as defined here)
  },
  filesOnce = {
    ["/local/location"] = "example.file"   -- same as files, but these will not overwrite an existing file
  },
  depends = {
    ["cc-paw"] = "0.4.0"   -- depends on a specific version (or compatible upgrade) of a package
  },
  preinst = [[]],  -- a script to execute before installing this package (return non-zero number and a message to indicate failure)
  postinst = [[]], -- a script to execute after installing this package (return non-zero number and a message to indicate failure)
  prerm = [[]],    -- a script to execute before removing this package (return non-zero number and a message to indicate failure)
  postrm = [[]]    -- a script to execute after removing this package (return non-zero number and a message to indicate failure)
}
