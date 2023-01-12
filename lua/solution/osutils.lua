local osutils = {}


--- Returns the current operating system
osutils.system = function()
    return string.lower(jit.os)
end

--- Returns the seperator for the current operating system
osutils.seperator = function()
    if package.config:sub(1,1) == '/' then
        return '/'
    else
        return '\\'
    end
end

return osutils
