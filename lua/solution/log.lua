local OSUtils = require("solution.osutils")

local log = {}


log.LogLocation = vim.fn.stdpath("cache").. OSUtils.seperator() .. "solution.nvim" .. OSUtils.seperator() .. "solution.log"


log.information = function(string)
    log.WriteGeneric("INFO",string)
end

log.warning = function(string)
    log.WriteGeneric("WRN",string)
end

log.error = function(string)
    log.WriteGeneric("ERR",string)
end

log.WriteGeneric = function(level, message)
    local d = os.date("%d-%b-%Y %H:%M:%S",os.time())
    local s = string.format("[%s][%s] %s\n",level,d,message)
    local f = io.open(log.LogLocation,"a+")
    if(f ~= nil) then
        f:write(s)
        f:close()
    end
end


return log
