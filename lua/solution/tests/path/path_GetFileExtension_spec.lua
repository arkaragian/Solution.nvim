-- The plugin itself does not require the plenary.nvim plugjn
-- However the tests require the library. The tests should never
-- be called during normal use and thus should not cause an error.
--
-- To execute the tests issue the following command inside vim
-- :PlenaryBustedFile %
--
-- From CLI:
-- nvim --headless -c 'PlenaryBustedDirectory . {minimal_init = "./minimal_init.lua"}'

-- import the luassert.mock module
local mock = require('luassert.mock')
local stub = require('luassert.stub')


describe("File Extension Tests:",function()
    it("file", function()
        local m = require("solution.path")
        local r = m.GetFileExtension("file")
        assert.equal(nil,r)
    end)

    it("file.txt", function()
        local m = require("solution.path")
        local r = m.GetFileExtension("file.txt")
        assert.equal(".txt",r)
    end)

    it("file.a.b", function()
        local m = require("solution.path")
        local r = m.GetFileExtension("file.a.b")
        assert.equal(".b",r)
    end)

end)
