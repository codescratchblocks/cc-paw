expose "fs API", ->
  _G.fs = require "spec/fs"

expose "dofile shim", ->
  real_dofile = dofile
  _G.dofile = (path) ->
    path = path\sub 1, -5
    switch(path)
      -- when "bin"
      --   --real_dofile "src/bin.lua" <-- can't pass arguments
      --   loadfile("src/bin.lua")(...)
      --   --require "bin" <-- passes bin as an argument
      when "/lib/cc-paw"
        require "lib"
      when "/lib/semver"
        require "lib.semver"
      when "/lib/cc-paw-util"
        require "util"
      else
        error "dofile shim not defined for \"#{path}\""

expose "run shim", ->
  _G.run = (...) ->
    loadfile("src/bin.lua")(...)

describe "CC-PAW", ->

  describe "binary", ->
    it "loads without errors", ->
      assert.has_no.errors -> run!

    pending "parses arguments correctly", ->

  describe "library", ->

    expose "ccpaw library", ->
      _G.ccpaw = require "lib"

    describe "install", ->

      pending "with version and exact option", ->
        it "returns true when the package is installed with the correct version", ->
          assert.is_true ccpaw.install "installed_exactly", "1.0.0", {exact:true}
        it "errors when the package is installed with a different version", ->
          assert.has_error ccpaw.install "installed_non_exactly", "1.0.0", {exact:true}

      describe "with version and ignoreInst & exact options", ->
        it "returns true when the package is installed with the correct version", ->
          assert.is_true ccpaw.install "installed_exactly", "1.0.0", {ignoreInst:true,exact:true}
        it "errors when the package is installed with a different version", ->
          assert.has_error ccpaw.install "installed_non_exactly", "1.0.0", {ignoreInst:true,exact:true}

      describe "with version and ignoreInst option", ->
        it "returns true when the package is already installed and compatible with requested version", ->
          assert.is_true ccpaw.install "installed_compatible", "1.0.0", {ignoreInst:true}
          assert.is_true ccpaw.install "installed_compatible", "1.1.0", {ignoreInst:true}
        it "errors when an incompatible version is installed", ->
          assert.has_error ccpaw.install "installed_incompatible", "1.0.0", {ignoreInst:true}

      describe "without extra arguments", ->
        it "errors if the package is installed", ->
          assert.has_error ccpaw.install "installed"
