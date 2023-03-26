-- This module handles the reading ana writing of cache data.
-- The cache is structired as follows
-- RootCacheDirectory
-- |
-- |- solution.log
-- |
-- |- hash1
-- |    |
-- |    |- index.json
-- |    |- CacheData.json
-- |
-- |- hash2
--      |
--      |- index.json
--      |- CacheData.json
--
-- Each hash is produced by a hacsh code function with input the path of the solution file
-- thus ensuring that each solution location has it's own data.
--
-- Inside the directory there exists a file named index.json. This file stores some
-- basic data for the solution. Such as the solution path. Based on that information a
-- hash colision is detected. If there is a colition then the next directory that is
-- used is the <HashCode>_1 <HashCode>_2 ... <HashCode>_n
local OSUtils = require("solution.osutils")
local log = require("solution.log")

local CacheManager = {}

local State = {
    CacheRootInitialized = false
}


CacheManager.CacheRootLocation = vim.fn.stdpath("cache").. OSUtils.seperator .. "solution.nvim"


--- Provides a path inside the cache directory of the given solution path.
CacheManager.ProvidePath = function(SolutionPath,file)
    return CacheManager.CacheRootLocation .. OSUtils.seperator .. CacheManager.HashString(SolutionPath) .. OSUtils.seperator .. file
end


--- Creates the cache directory. This function should produce a result when it is
--the first time that this plugin is activated or when 
CacheManager.CreateCacheRoot = function()
    local cacheDirectory = CacheManager.CacheRootLocation
    local r = vim.fn.mkdir(cacheDirectory,"p")
    -- Windows code 0 is sucess and 1 if the directory aloready exists
    if(r ~= 0 and r ~= 1) then
        print("Failed to create directory: "..cacheDirectory)
        return
    end
    -- Create the log file
    CacheManager.LogInit()
    print("Cache Directory located at:"..cacheDirectory)
    State.CacheRootInitialized = true
end

CacheManager.LogInit = function()
    local filename = CacheManager.CacheRootLocation .. OSUtils.seperator .. "solution.log"
    local d = os.date("%d-%b-%Y %H:%M:%S",os.time())
    local s = string.format("[%s][%s] %s","INFO",d,"Log initialised\n")
    local f = io.open(filename,"w")
    if(f ~= nil) then
        f:write(s)
        f:close()
    end
end

--- Sets up the cache for the the given solution path
-- @param SolutionPath The path of the solution
CacheManager.SetupCache = function(SolutionPath)
    if(State.CacheRootInitialized == false) then
        print("Cache Root is not initalized doing nothing")
        return
    end
    local location = CacheManager.CacheRootLocation .. OSUtils.seperator .. CacheManager.HashString(SolutionPath)

    local r = vim.fn.mkdir(location,"p")
    --log.information(string.format("Creation result for directory %s is %d",location,r))
    -- Directory already exists. Check if this is really ours or we are experiencing a colision
    if(r == 1) then
        --print("Directory:".. location .." exists")
        local tab = CacheManager.ReadIndexFile(location)
        if (tab == nil) then
            --No index file exists. It appears that the directory was just created!
            CacheManager.WriteIndexFile(location,SolutionPath)
            return
        end
        if tab.SolutionPath == SolutionPath then
            -- We are on the corect path and the solution is already setup nothing to do here
            print("Index verified nothing more to do")
            log.information(string.format("Index verified for %s nothing more to do",tab.SolutionPath))
            return
        end
        --print("Colision Detected!")
        -- We have a colision. Try the next name with the postfix with a loop
        local posfixNumber = 1
        local newLoc = location .. "_"..posfixNumber
        repeat
            newLoc = location .. "_"..posfixNumber
            r = vim.fn.mkdir(newLoc,"p")
            if(r == 1) then
                tab = CacheManager.ReadIndexFile(newLoc)
                posfixNumber = posfixNumber + 1
            elseif (r == 0) then
                CacheManager.WriteIndexFile(newLoc,SolutionPath)
                tab = CacheManager.ReadIndexFile(newLoc)
            end
        until(tab.SolutionPath == SolutionPath)
        log.information(string.format("After colision resolution, index for %s verified at %s",tab.SolutionPath,newLoc))
    end
    -- Windows code 0 is sucess and 1 if the directory aloready exists
    -- There was sucess creating the directory.
    --if( r == 0 ) then
    --    print("Directory:".. location .." created")
    --    CacheManager.WriteIndexFile(location,SolutionPath)
    --end
    print("Failed to setup cache directory: "..location)
end


--- Writes the index file in the cache directory
CacheManager.WriteIndexFile = function(SolutionCacheDirectory, SolutionPath)
    local indexfile = SolutionCacheDirectory .. OSUtils.seperator .. "index.json"

    local indexData = {
        SolutionPath = SolutionPath,
    }
    local indf = io.open(indexfile,"w")
    if (indf ~= nil) then
        local json = vim.json.encode(indexData)
        indf:write(json)
        io.close(indf)
    end
end

--- Read the contents of the index file for a given solution cache directory
-- @param SolutionCacheDirectory The path for a solution cache directory
CacheManager.ReadIndexFile = function(SolutionCacheDirectory)
    local indexfile = SolutionCacheDirectory .. OSUtils.seperator .. "index.json"

    local indf = io.open(indexfile,"r")
    if(indf == nil) then
        print("Could not read file:"..indexfile)
        return
    end
    local jsonData = indf:read("*a")
    local jsonTab = vim.json.decode(jsonData)
    io.close(indf)
    return jsonTab
end


--- Writes the cache data to the solution cache directory
-- @param SolutionPath The path of the solution for which we are writting cache data
-- @param CacheData A lua table that represents all the cache data that is written
CacheManager.WriteCacheData = function(SolutionPath,CacheData)
    if(SolutionPath == nil) then
        return
    end
    local location = CacheManager.ProvidePath(SolutionPath,"CacheData.json")

    local json = vim.json.encode(CacheData)

    local file = io.open(location, "w")

    if(file ~= nil) then
        -- Write the string to the file
        file:write(json)

        -- Close the file
        file:close()
    else
        vim.notify("Cache Data Updated",vim.log.levels.ERROR,{title="Solution.nvim"})
    end
end


--- Reads the cache data for the given solution path and returns them as a lua table
-- @param SolutionPath The path of the solution for which we are reading cache data
CacheManager.ReadCacheData = function(SolutionPath)
    if(SolutionPath == nil) then
        return
    end
    local location = CacheManager.ProvidePath(SolutionPath,"CacheData.json")

    local file = io.open(location, "r")

    if(file == nil) then
        return nil
    end

    local jsonData = file:read("*a")

    local json = vim.json.decode(jsonData)
    -- Close the file
    file:close()

    if(json ~= nil) then
        --vim.notify("Cache Data Loaded",vim.log.levels.INFO,{title = "Solution.nvim"})
        return json
    end
end

--- Calculates a hash code for a given string
--@param str The string for which we write a hash code
CacheManager.HashString = function(str)
    local hash = 0
    --local bit32 = require("bit32")
    for i = 1, #str do
        local char = string.byte(str, i)
        hash = hash + char
        -- Version 1
        --hash = ((hash << 5) - hash) + char -- hashcode implementation
        --hash = hash & hash -- ensure 32-bit integer
        -- Version 2
        --hash = bit32.bxor(bit32.lshift(hash, 5) - hash, char) -- hashcode implementation
        --hash = bit32.band(hash, hash) -- ensure 32-bit integer
    end
    return hash
end


return CacheManager
