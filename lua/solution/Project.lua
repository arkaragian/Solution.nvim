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

Project.GetProjectProfiles = function(ProjectPath)
    --From the project path find the project "Properties" directory
    --Decode the Json and list the tiems alphabeticaly(?)
    local pd = path.GetParrentDirectory(ProjectPath,os.seperator())
    local lsfile = pd .. os.seperator() .. "Properties" .. os.seperator() .. "launchSettings.json"

    local f = io.open(lsfile, "r")
    if (f == nil) then
        return
    end

    local json = f:read("*a")
    local jsonTab = vim.json.decode(json)

    if(jsonTab == nil or jsonTab.profiles == nil) then
        return
    end

    -- Since json does not have numeric keys we need to generate
    -- those ourselves. We add each key and then sort the result.
    local ordered_keys = {}
    for k in pairs(jsonTab.profiles) do
        table.insert(ordered_keys, k)
    end

    table.sort(ordered_keys)
    -- We now have numbers for our keys
    for i = 1, #ordered_keys do
        local k  = ordered_keys[i]
        local v = jsonTab.profiles[k]
        P(k)
        P(v)
    end
end

Project.GetArgStringFromProfile = function(profile)
    return profile.commandLineArgs
end


Project.LaunchProject = function(ProjectPath,profile)
    -- In order to execute a project we need the following:
    -- 1 The launch profile that supplies the command line arguments
    -- 2 
    local command = string.format("!dotnet run --project %s --launch-profile %s<CR>",ProjectPath,profile)
    vim.cmd(command)
    --local _ = vim.fn.jobstart(command,{
        --on_stderr = on_event,
        --on_stdout = on_event,
        --on_exit = on_event,
        --stdout_buffered = true,
        --stderr_buffered = true,
    --})
end

return Project
