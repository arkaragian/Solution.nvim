-- Simple utilities that are used throughout the plugin
local utils = {}

utils.Length = function(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

utils.StringStartsWith = function(theString, thePattern)
    -- Takes a chunk equal to the length of the pattern starting
    -- form the start of the string. If the chunk is equal to the
    -- pattern then we return true
   return string.sub(theString,1,string.len(thePattern))==thePattern
end

utils.StringTrimWhiteSpace = function(s)
   return s:gsub("^[%s\t]+", ""):gsub("[%s\t]+$", "")
end

utils.StringIsNullOrWhiteSpace = function(s)
    if (s is nil) then
        return true
    end

    if (string.len(s) == 0) then
        return true
    end

    local i,_ = string.find(s,"%w")
    if(i ~= nil) then
        return false
    end
end


return utils
