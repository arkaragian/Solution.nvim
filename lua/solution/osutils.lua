local osutils = {}

local seperator = nil

if package.config:sub(1,1) == '/' then
    seperator = '/'
else
    seperator = '\\'
end




--- Returns the current operating system
osutils.system = function()
    return string.lower(jit.os)
end

--- Returns the seperator for the current operating system
osutils.seperator = seperator
return osutils
