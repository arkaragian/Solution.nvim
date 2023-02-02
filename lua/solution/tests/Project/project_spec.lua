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


describe("Project:",function()

    it("Get Binary output directory", function()
        local m = require("solution.ProjectParser")
        local result = m.GetBinaryOutput("C:\\home\\aris\\project\\project.csproj")
        if(result == nil) then
            print("Nill Result")
            return
        end
        assert.equals("C:\\home\\aris\\project\\bin\\project.dll",result)
    end)
end)

