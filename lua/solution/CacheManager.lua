local OSUtils = require("solution.osutils")

local CacheManager = {}

local State = {
    CacheRootInitialized = false
}


-- All persitent data is stored inside the cache directory. Each solution file has it's own
-- directory where any persistent data for this solution is stored. We chose a directory and
-- not a file because we want to be flexible on what we can store.
--
-- The directory where the data is stored is calculated based on a hash function. Inside the
-- directory there exists a file named index.json. This file stores some basic data for the
-- solution. Such as the solution path and modification dates. Based on that information a
-- hash colision is detected. If there is a colition then the next directory that is used is
-- the <HashCode>_1 <HashCode>_2 ... <HashCode>_n


CacheManager.CacheRootLocation = vim.fn.stdpath("cache").. OSUtils.seperator() .. "solution.nvim"


CacheManager.ProvidePath = function(SolutionPath,file)
    return CacheManager.CacheRootLocation .. OSUtils.seperator() .. CacheManager.HashString(SolutionPath) .. OSUtils.seperator() .. file
end
--CacheManager.CacheRootLocation = function()
--    local cacheRoot = vim.fn.stdpath("cache").. OSUtils.seperator() .. "solution.nvim"
--    return cacheRoot
--end


CacheManager.CreateCacheRoot = function()
    local cacheDirectory = CacheManager.CacheRootLocation
    local r = vim.fn.mkdir(cacheDirectory,"p")
    -- Windows code 0 is sucess and 1 if the directory aloready exists
    if(r ~= 0 and r ~= 1) then
        print("Failed to create directory: "..cacheDirectory)
        return
    end
    print("Cache Directory located at:"..cacheDirectory)
    State.CacheRootInitialized = true
end

--- Sets up the cache for the the given solution path
-- @param SolutionPath The path of the solution
CacheManager.SetupCache = function(SolutionPath)
    if(State.CacheRootInitialized == false) then
        print("Cache Root is not initalized doing nothing")
        return
    end
    local location = CacheManager.CacheRootLocation .. OSUtils.seperator() .. CacheManager.HashString(SolutionPath)

    local r = vim.fn.mkdir(location,"p")
    print(string.format("Creation result for deiractory %s is %d",location,r))
    -- Directory already exists. Check if this is really ours or we are experiencing a colision
    if(r == 1) then
        print("Directory:".. location .." exists")
        local tab = CacheManager.ReadIndexFile(location)
        if (tab == nil) then
            --No index file exists. It appears that the directory was just created!
            CacheManager.WriteIndexFile(location,SolutionPath)
            return
        end
        if tab.SolutionPath == SolutionPath then
            -- We are on the corect path and the solution is already setup nothing to do here
            print("Index verified nothing more to do")
            return
        end
        print("Colision Detected!")
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
    end
    -- Windows code 0 is sucess and 1 if the directory aloready exists
    -- There was sucess creating the directory.
    --if( r == 0 ) then
    --    print("Directory:".. location .." created")
    --    CacheManager.WriteIndexFile(location,SolutionPath)
    --end
    print("Failed to setup cache directory: "..location)
end

--- Returns the cache directory location for the given solution path.
-- @param SolutionPath The path of the solution
--CacheManager.GetCacheLocation = function(SolutionPath)
--    local startLocation = CacheManager.CacheRootLocation() .. OSUtils.seperator() .. CacheManager.HashString(SolutionPath)
--    -- Read the file in the result and check the solution path there. If it not the same this means that we have a
--    -- colision. Append a _<number> postfix and retry. If we read the correct path then return the location of this
--    -- file.
--    local indexfile = startLocation .. OSUtils.seperator() .. "index.json"
--    local f = io.open(indexfile,"r")
--    if (f==nil) then
--        -- We could not open the file we can assume that the file does not
--        -- exist and thus we can use this location for our cache.
--        return startLocation
--    end
--end


CacheManager.WriteIndexFile = function(SolutionCacheDirectory, SolutionPath)
    local indexfile = SolutionCacheDirectory .. OSUtils.seperator() .. "index.json"

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

CacheManager.ReadIndexFile = function(SolutionCacheDirectory)
    local indexfile = SolutionCacheDirectory .. OSUtils.seperator() .. "index.json"

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
        vim.notify("Cache Data Loaded",vim.log.levels.WARN,{title = "Solution.nvim"})
        return json
    end
end

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
