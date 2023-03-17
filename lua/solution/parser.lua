-- Path is a central module that helps the editor localize within
-- the filesystem. It's goal is to provide functions that will help
-- us locate our solution files.
--
-- this file should be called as follows from other plugin code:
-- local Path = require("solution.path")
local Parser = {}

local os = require("solution.osutils")
local utils = require("solution.utils")


Parser.ParseOutputDirectory = function(line,OutputTable)
    local i,j = string.find(line,"->")
    if(i ~= nil and j~= nil) then
        local project = string.sub(line,1,i-1)
        local output = string.sub(line,j+1,string.len(line))
        -- TODO: Trim
        local entry = {
            Project = utils.StringTrimWhiteSpace(project),
            OutputLocation = utils.StringTrimWhiteSpace(output)
        }
        local index = #OutputTable + 1
        OutputTable[index] = entry
    end
    return OutputTable
end

--- Indicates if a line should be added to the quickfix list
-- The lines that are added is
Parser.ParseLine = function(line)
    if(type(line) ~= "string") then
        print("Input is not string. Returning nil")
        return nil
    end
    -- A Sample error line is:
    -- C:\users\Admin\source\repos\test\Program.cs(7,35): error CS1002: ; expected [C:\users\Admin\source\repos\test\test.csproj]
    --
    -- A Sample warning line is:
    -- C:\Users\Admin\source\repos\MVEnc\MVEnc\RTSPServer.cs(1540,29): warning CS0162: Unreachable code detected [C:\Users\Admin\source\repos\MVEnc\MVEnc\MVEnc.csproj]

    -- Find the first parenthesis and the first comma
    -- In Lua some characters in pattern matching are considered magic. Thus
    -- they require escaping by % in order to be matched.
    local poIndex,_ = string.find(line,"%(") -- parenthesis open index
    local cIndex,_ = string.find(line,"%,") -- parenthesis comma index
    local pcIndex,_ = string.find(line,"%)") -- parenthesis close index

    -- If we cannot find those characters we cannot continue
    if not poIndex or not cIndex or not pcIndex then
        return nil
    end

    -- Find the : characters. As those deliniate if warning or error as well as
    -- the error number.
    local twoDotsOne
    if(os.system() == "windows") then
        -- In windows Paths start with C:\ D:\ etc we don't want to match that.
        twoDotsOne,_= string.find(line,":",3)
    else
        twoDotsOne,_= string.find(line,":")
    end

    -- Could be used to display the module name.
    -- TODO: We need this to be user configurable
    local bracketOpen,_= string.find(line,"%[") -- parenthesis closse index
    --local bracketClose,_= string.find(line,"]") -- parenthesis closse index
    --
    -- If we cannot find those characters we cannot continue
    if not twoDotsOne or not bracketOpen then
        return nil
    end

    local theFile = string.sub(line,1,poIndex-1)
    local lineNumber = tonumber(string.sub(line,poIndex+1,cIndex-1))
    local columnNumber = tonumber(string.sub(line,cIndex+1,pcIndex-1))

    local message = string.sub(line,twoDotsOne+1,bracketOpen-2)

    -- Check if we have error or warning. But we search for the " error " pattern
    -- because a user could have the word error in his code filenames. If we
    -- find a match then we have an error. Otherwise we have a warning.
    -- Note: space is a magic char thus it is matched by %s
    local match = string.match(line,"%serror%s")
    local errorOrWarning
    if not match then
        errorOrWarning = 'W'
    else
        errorOrWarning = 'E'
    end

    local item = {
        filename = theFile,
        --module = moduleName,
        lnum = lineNumber,
        col = columnNumber,
        --nr = "CS1000", -- .net uses alphanumeric errors. We need only numbers to be usable
        text = message,
        type = errorOrWarning
    }

    return item

end


return Parser
