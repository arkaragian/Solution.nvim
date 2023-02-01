local xml2lua = require("xml2lua")
local handler = require("xml2lua.xmlhandler.tree")

local ProjectParser = {}

--- Parses an xml project project file
ProjectParser.ParseProject = function(filename)

    --Uses a handler that converts the XML to a Lua table
    local xml = xml2lua.loadFile(filename)

    --Instantiates the XML parser
    local parser = xml2lua.parser(handler)
    parser:parse(xml)

    return handler.root
end

ProjectParser.GetBinaryOutput = function(filename)
    local path = require("solution.path")
    local os = require("solution.osutils")
    -- asume we receive a csproj as a filename
    local parent = path.GetParrentDirectory(filename)
    print("Parent:" .. parent)
    local projName = path.GetFilenameFromPath(filename)
    print("Name:" .. projName)

    local output = parent .. os.seperator() .. "bin" .. os.seperator() .. projName .. ".dll"
    print("Output:" .. output)
    return output
end

return ProjectParser
