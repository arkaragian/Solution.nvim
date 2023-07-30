--- Project Module
-- This module provides functionality to manage and interact with .NET projects.
-- It includes functions for launching projects, retrieving project profile names,
-- parsing project XML files, and getting command-line arguments from a profile.
-- @module Project

local xml2lua = require("xml2lua")
local handler = require("xml2lua.xmlhandler.tree")

local path = require("solution.path")
local os = require("solution.osutils")


local Project = {}

--- Parses a given XML project file into a Lua table.
-- This function reads the specified XML file and uses an XML handler to convert
-- the XML content into a Lua table, representing the root element of the XML.
-- @function Project.ParseProject
-- @tparam string filename The path to the XML file that needs to be parsed.
-- @treturn table The root element of the parsed XML as a Lua table.
-- @usage local projectRoot = Project.ParseProject("/path/to/project.xml")
Project.ParseProject = function(filename)

    --Uses a handler that converts the XML to a Lua table
    local xml = xml2lua.loadFile(filename)

    --Instantiates the XML parser
    local parser = xml2lua.parser(handler)
    parser:parse(xml)

    return handler.root
end

--- Retrieves the project profile names from a specified .NET project.
-- This function looks for a `launchSettings.json` file in the "Properties" directory of the given project path.
-- It then decodes the JSON content and extracts the profile names, sorting them alphabetically.
-- @function Project.GetProjectProfileNames
-- @tparam string ProjectPath The path to the .NET project for which profile names are to be retrieved.
-- @treturn table|nil An ordered table of profile names or `nil` if the file does not exist or profiles are not found.
-- @usage local profiles = Project.GetProjectProfileNames("/path/to/project")
Project.GetProjectProfileNames = function(ProjectPath)
    --From the project path find the project "Properties" directory
    --Decode the Json and list the tiems alphabeticaly(?)
    local pd = path.GetParrentDirectory(ProjectPath,os.seperator)
    local lsfile = pd .. os.seperator .. "Properties" .. os.seperator .. "launchSettings.json"

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
    --for i = 1, #ordered_keys do
    --    local k  = ordered_keys[i]
    --    local v = jsonTab.profiles[k]
    --end
    return ordered_keys
end

Project.GetArgStringFromProfile = function(profile)
    return profile.commandLineArgs
end


--- Launches a specified .NET project using the given launch profile.
-- This function will run the .NET project by constructing a command string
-- with the project path and launch profile, and then executing the command
-- using Vim's command-line interface.
-- @function Project.LaunchProject
-- @tparam string ProjectPath The path to the .NET project to be launched.
-- @tparam string profile The launch profile that supplies the command-line arguments.
-- @usage Project.LaunchProject("/path/to/project", "Development")
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
