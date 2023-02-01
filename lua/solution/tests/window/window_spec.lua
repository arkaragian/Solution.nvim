-- import the luassert.mock module
local mock = require('luassert.mock')
local stub = require('luassert.stub')


describe("File Extension Tests:",function()
    it("CanBeRequired", function()
        local m = require("solution.window")
        _ = m
    end)

    it("Create Window With Nil", function()
        local api = mock(vim.api,true)
        api.nvim_create_buf.returns(500)


        local m = require("solution.window")
        local instance = m.new()
        assert.stub(api.nvim_create_buf).was_called_with(false,true)

        mock.revert(api)
        --assert.equal(nil,instance.BufferNumber)
        --assert.equal(nil,instance.BorderBufferNumber)
        --assert.equal(nil,instance.WindowHandle)
        --assert.equal(nil,instance.Title)
    end)

    it("Create Window With Values", function()
        local m = require("solution.window")
        local instance = m.new(1,"Hello")
        assert.equal(1,instance.BufferNumber)
        assert.equal("Hello",instance.Title)
    end)


    it("Set Window Dimensions", function()
        local m = require("solution.window")
        local instance = m.new()
        instance.SetWidth(100)
        instance.SetHeight(200)
        assert.equal(100,instance.BorderWindowOptions.Width)
        assert.equal(200,instance.BorderWindowOptions.Height)
    end)

end)
