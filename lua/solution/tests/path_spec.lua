-- The plugin itself does not require the plenary.nvim plugjn
-- However the tests require the library. The tests should never
-- be called during normal use and thus should not cause an error.
--
-- To execute the tests issue the following command inside vim
-- :PlenaryBustedFile %
--
-- From CLI:
-- nvim --headless -c 'PlenaryBustedDirectory . {minimal_init = "./minimal_init.lua"}'


describe("Path Module Lua",function()
    it("Can be required", function()
        require("solution.path")
    end)
end)

describe("Path Module Windows:",function()
    it("Returns Root", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("C:\\","\\")
        assert.equals("C:\\",result)
    end)

    it("Returns Root with seperator", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("C:\\\\","\\")
        assert.equals("C:\\",result)
    end)

    it("Correct Directory", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("C:\\Dir1\\Dir2","\\")
        assert.equals("C:\\Dir1",result)
    end)

    it("Correct Directory Seperator End", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("C:\\Dir1\\Dir2\\","\\")
        assert.equals("C:\\Dir1",result)
    end)

    it("Return Root Drive", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("C:\\Dir1","\\")
        assert.equals("C:\\",result)
    end)

    it("Returnss Root Drive Seperator", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("C:\\Dir1\\","\\")
        assert.equals("C:\\",result)
    end)

end)

--describe("Path Module Linux:",function()
--    it("Correct Directory", function()
--        local m = require("solution.path")
--        local result = m.GetParrentDirectory("/home/aris","/")
--        assert.equals("/home",result)
--    end)
--
--    it("Correct Directory Seperator End", function()
--        local m = require("solution.path")
--        local result = m.GetParrentDirectory("/home/aris/","/")
--        assert.equals("/home",result)
--    end)
--
--end)
