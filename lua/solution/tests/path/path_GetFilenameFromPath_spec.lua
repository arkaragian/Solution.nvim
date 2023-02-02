-- The plugin itself does not require the plenary.nvim plugjn
-- However the tests require the library. The tests should never
-- be called during normal use and thus should not cause an error.
--
-- To execute the tests issue the following command inside vim
-- :PlenaryBustedFile %
--
-- From CLI:
-- nvim --headless -c 'PlenaryBustedDirectory . {minimal_init = "./minimal_init.lua"}'

-- import the luasseGetFilenameFromPath.mock module
local mock = require('luassert.mock')
local stub = require('luassert.stub')

describe("File Extension Tests:",function()

    it("C:\\home\\arisis\\file.txt", function()
        local m = require("solution.path")
        local r = m.GetFilenameFromPath("C:\\home\\arisis\\file.txt", true)
        assert.equal("file.txt",r)
    end)

    it("C:\\home\\arisis\\file.txt", function()
        local m = require("solution.path")
        local r = m.GetFilenameFromPath("C:\\home\\arisis\\file.txt", false)
        assert.equal("file",r)
    end)

end)
