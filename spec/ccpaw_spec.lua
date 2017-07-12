expose("fs API", function()
  _G.fs = require "spec/fs"
end)

describe("CC-PAW", function()
  it("loads without errors", function()
    assert.has_no.errors(function() dofile "src/bin.lua" end)
  end)
end)
