expose "fs API", ->
  _G.fs = require "spec/fs"

describe "CC-PAW", ->
  it "loads without errors", ->
    assert.has_no.errors -> dofile "src/bin.lua"
