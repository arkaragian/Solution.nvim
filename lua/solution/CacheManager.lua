local OSUtils = require("solution.osutils")

local CacheManager = {}
-- All persitent data is stored inside the cache directory. Each solution file has it's own
-- directory where any persistent data for this solution is stored. We chose a directory and
-- not a file because we want to be flexible on what we can store.
--
-- The directory where the data is stored is calculated based on a hash function. Inside the
-- directory there exists a file named index.json. This file stores some basic data for the
-- solution. Such as the solution path and modification dates. Based on that information a
-- hash colision is detected. If there is a colition then the next directory that is used is
-- the <HashCode>_1 <HashCode>_2 ... <HashCode>_n

CacheManager.CacheRootLocation = function()
    local cacheRoot = vim.fn.stdpath("cache").. OSUtils.seperator() .. "solution.nvim"
    return cacheRoot
end

--- Sets up the cache for the the given solution path
-- @param SolutionPath The path of the solution
CacheManager.SetupCache = function(SolutionPath)
    local startLocation = CacheManager.CacheRootLocation() .. OSUtils.seperator() .. CacheManager.HashString(SolutionPath)
    local indexfile = startLocation .. OSUtils.seperator() .. "index.json"

    local r = vim.fn.mkdir(cacheDirectory,"p")
    if( r==1 ) then
        local tab = CacheManager.ReadIndexFile(startLocation)
        if tab.SolutionPath == SolutionPath then
            -- We are on the corect path and the solution is already setup nothing to do here
            return
        end
        -- We have a colision. Try the next name maybe in a loop
    end
    -- Windows code 0 is sucess and 1 if the directory aloready exists
    if(r == 0 ) then
        local indexData = {
            SolutionPath = SolutionPath,
        }
        local indf = file.open(indexfile,"w")
        if (indf ~= nil) then
            --local jsonData = io.read(indf,"*a")
            local json = vim.json.encode(indexData)
            io.write(indf,json)
        end
    end
    print("Failed to create directory: "..cacheDirectory)
end

--- Returns the cache directory location for the given solution path.
-- @param SolutionPath The path of the solution
CacheManager.GetCacheLocation = function(SolutionPath)
    local startLocation = CacheManager.CacheRootLocation() .. OSUtils.seperator() .. CacheManager.HashString(SolutionPath)
    -- Read the file in the result and check the solution path there. If it not the same this means that we have a
    -- colision. Append a _<number> postfix and retry. If we read the correct path then return the location of this
    -- file.
    local indexfile = startLocation .. OSUtils.seperator() .. "index.json"
    local f = io.open(indexfile,"r")
    if (f==nil) then
        -- We could not open the file we can assume that the file does not
        -- exist and thus we can use this location for our cache.
        return startLocation
    end
end

CacheManager.ReadIndexFile = function(SolutionCacheDirectory)
    local indexfile = SolutionCacheDirectory .. OSUtils.seperator() .. "index.json"

    local indf = file.open(indexfile,"r")
    if(indf == nil) then
        print("Could not read file:"..indexfile)
        return
    end
    local jsonData = io.read(indf,"*a")
    local jsonTab = vim.json.decode(jsonData)
    return jsonTab
end

CacheManager.HashString = function(str)
    local hash = 0
    for i = 1, #str do
        local char = string.byte(str, i)
        hash = ((hash << 5) - hash) + char -- hashcode implementation
        hash = hash & hash -- ensure 32-bit integer
    end
    return hash
end

end


return CacheManager
