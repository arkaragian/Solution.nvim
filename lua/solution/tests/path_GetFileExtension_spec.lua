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


describe("Path Module Lua",function()
    it("OS Requirement", function()
        require("solution.osutils")
    end)

    it("Path Requirement", function()
        require("solution.path")
    end)
end)

describe("Path Module Windows:",function()
    -- Set the os regardless of where we are
    jit.os = "windows"
    print(jit.os)

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

    it("Returns Root Drive Seperator", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("C:\\Dir1\\","\\")
        assert.equals("C:\\",result)
    end)

    it("Returns Root Drive Seperator", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("C:\\a","\\")
        assert.equals("C:\\",result)
    end)

    it("Returns Root Drive Seperator", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("C:\\a\\","\\")
        assert.equals("C:\\",result)
    end)

    it("Returns Root Drive Seperator", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("C:\\a\\b","\\")
        assert.equals("C:\\a",result)
    end)

    it("Returns Root Drive Seperator", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("C:\\a\\b\\","\\")
        assert.equals("C:\\a",result)
    end)

end)

describe("Path Module Linux:",function()
    -- TODO: Will this work??
    --jit.os = "linux"

      -- mock the jit api
      --local api = mock(jit.os, true)
      --api.os.returns("linux")

    it("Return Root", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("/","/")
        assert.equals("/",result)
        --assert.stub(api.os).equals("/",result)
    end)

    it("Return Root With Seperator", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("//","/")
        assert.equals("/",result)
        --assert.stub(api.os).equals("/",result)
    end)

    it("Correct Directory 1", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("/home/aris","/")
        assert.equals("/home",result)
        --assert.stub(api.os).equals("/home",result)
    end)

    it("Correct Directory 2", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("/home/aris/","/")
        assert.equals("/home",result)
        --assert.stub(api.os).equals("/home",result)
    end)

    it("Correct Directory 3", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("/a/b","/")
        assert.equals("/a",result)
        --assert.stub(api.os).equals("/a",result)
    end)

    it("Correct Directory 4", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("/a/b/","/")
        assert.equals("/a",result)
        --assert.stub(api.os).equals("/a",result)
    end)

    it("Correct Directory 5", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("/a","/")
        assert.equals("/",result)
        --assert.stub(api.os).equals("/",result)
    end)

    it("Correct Directory 6", function()
        local m = require("solution.path")
        local result = m.GetParrentDirectory("/a/","/")
        assert.equals("/",result)
        --assert.stub(api.os).equals("/",result)
    end)

end)
