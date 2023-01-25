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

return ProjectParser
