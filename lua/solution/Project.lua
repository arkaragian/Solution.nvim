local xml2lua = require("xml2lua")
local handler = require("xml2lua.xmlhandler.tree")

local path = require("solution.path")
local os = require("solution.osutils")


local Project = {}

--- Parses the xml structure of a project
-- @param filename The filename of the project
Project.ParseProject = function(filename)

    --Uses a handler that converts the XML to a Lua table
    local xml = xml2lua.loadFile(filename)

    --Instantiates the XML parser
    local parser = xml2lua.parser(handler)
    parser:parse(xml)

    return handler.root
end


Project.LaunchProject = function(ProjectPath,profile)
    local command = string.format("dotnet run --project %s --launch-profile %s",ProjectPath,profile)
    local _ = vim.fn.jobstart(command,{
        --on_stderr = on_event,
        --on_stdout = on_event,
        --on_exit = on_event,
        --stdout_buffered = true,
        --stderr_buffered = true,
    })
end

return Project
