-- A repo has a defined ROOT (ex: https://cc-repo.guard13007.com/ ) which contains a "packages.list" file.
-- This file is a list of names representing what packages are available here and their latest version.
--  ( ex: example-package=2.3.9-dev )
-- Each version of a package is defined by a file located at ROOT .. NAME .. "/" .. VERSION .. "/pkg.lua"
--  where NAME and VERSION are as defined in "packages.list".
--  ( ex: https://cc-repo.guard13007.com/example-package/2.3.9-dev/pkg.lua )

-- This file represents a particular version of a package (a pkg.lua file). It contains some info about the package,
--  as well as files and scripts to execute for installing and uninstalling this version of the package.

{
  name = "example-package",     -- used internally to identify packages
  version = "1.0.0", -- all packages use Semantic Versioning (see http://semver.org/)
  confVersion = 2,                                 -- the version of this config format
  -- NOTE: Anything below here is optional, depending on what a particular package needs to define.
  title = "An Example Package",                    -- a human readable title / brief description of the package
  description = "An example package.",
  author = "Example Name <email@example.com>",     -- (created the source) note: email address not required!
  maintainer = "Example Name <email@example.com>", -- (maintains the package) note: email address not required
  license = "MIT",                                 -- a URL or brief piece of info about the license of this package
  source = "https://github.com/cc-paw/cc-paw",     -- a URL to the source of this package
  files = {
    ["/local/location"] = "example.file"   -- this is retrieved from ROOT .. NAME .. "/" .. VERSION .. "/" .. FILE (as defined here)
  },
  filesOnce = {
    ["/local/location"] = "example.file"   -- same as files, but these will not overwrite an existing file
                                           -- (these will also not be removed when a package is removed)
  },
  depends = {
    ["cc-paw"] = "0.4.0"   -- depends on a specific version (or compatible upgrade) of a package
  },
  dependsExact = {         -- depends on an EXACT version of a package
    ["example"] = "1.0.0"  -- NOTE NOT FULLY IMPLEMENTED !! EXACT DEPENDENCIES CURRENTLY CAN BE UPGRADED !!
  },
  preinst = [[]],  -- a script to execute before installing this package (return non-zero number and a message to abort)
  postinst = [[]], -- a script to execute after installing this package (return non-zero number and a message to indicate failure)
  preupgd = [[]],  -- a script to execute before upgrading this package (return non-zero number and a message to abort)
  postupgd = [[]], -- a script to execute after upgrading this package (return non-zero number and a message to indicate failure)
  prerm = [[]],    -- a script to execute before removing this package (return non-zero number and a message to abort)
  postrm = [[]],   -- a script to execute after removing this package (return non-zero number and a message to indicate failure)
  prepurge = [[]], -- a script to execute before purging this package (return non-zero number and a message to abort)
  postpurge = [[]] -- a script to execute after purging this package (return non-zero number and a message to indicate failure)
}
