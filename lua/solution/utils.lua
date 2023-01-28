-- Simple utilities that are used throughout the plugin
local utils = {}

utils.Length = function(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end


return utils
