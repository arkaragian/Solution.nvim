local xml2lua = require("xml2lua")
local handler = require("xml2lua.xmlhandler.tree")

local path = require("solution.path")
local os = require("solution.osutils")


local ProjectParser = {}

--- Parses the xml structure of a project
-- @param filename The filename of the project
ProjectParser.ParseProject = function(filename)

    --Uses a handler that converts the XML to a Lua table
    local xml = xml2lua.loadFile(filename)

    --Instantiates the XML parser
    local parser = xml2lua.parser(handler)
    parser:parse(xml)

    return handler.root
end

ProjectParser.GetBinaryOutput = function(filename, configuration, platform)
    -- asume we receive a csproj as a filename
    local parent = path.GetParrentDirectory(filename,os.seperator())
    -- Without extension
    local projName = path.GetFilenameFromPath(filename, false)

    -- TODO: handle debug and release
    -- TODO: handle net6.0 net7.0
    -- The output is the patent directory of the project /bin/configuration/platform/projectname.dll
    --
    local output = parent .. os.seperator() .. "bin" .. os.seperator() .. configuration .. os.seperator() .. platform .. projName .. ".dll"
    print("Output:" .. output)
    return output
end

return ProjectParser
