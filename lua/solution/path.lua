-- Path is a central module that helps the editor localize within
-- the filesystem. It's goal is to provide functions that will help
-- us locate our solution files.
--
-- this file should be called as follows from other plugin code:
-- local Path = require("solution.path")
local Path = {}


--- Return the parent directory for a given path
-- @param path The input path
-- @param seperator The directory seperator
Path.GetParrentDirectory = function(path,seperator)
    -- TODO: Handle windows
    if(string.lower(jit.os) == "windows") then
        -- If we have reached the drive. such as: C:\ Z:\ or whatever
        if(string.sub(path,1,3) == path) then
            return path
        end
    else
        if(path == "/") then
            return path
        end
    end

    local lastSeperatorIndex = 0;
    for i=1,string.len(path) do
        -- Get a character
        local c = string.sub(path,i,i)
        if(c == seperator) then
            lastSeperatorIndex = i
        end
    end
    return string.sub(path,1,lastSeperatorIndex-1)
end

--- Determines if the given directory contains any files of the given extension
-- @param dir The directory path to check
-- @param extension The extension to check for
Path.DirectoryContainsExtension = function(directory,extension)
    local dir_sep
    if package.config:sub(1,1) == '/' then
        dir_sep = '/'
    else
        dir_sep = '\\'
    end
    -- TODO: Hande windows and linux here
    local command = 'dir "' .. directory .. dir_sep .. '*.' .. extension .. '" /b'
    --for file in io.popen('dir "' .. dir .. dir_sep .. '*.' .. extension .. '" /b'):lines() do
    -- search for files in the directory that have the given extension
    for file in io.popen(command):lines() do
        print(file)
        -- file was found, return true
        return true
    end
    -- no files were found, return false
    return false
end

--- Returns all files of the given extension in the specified directory
-- @param directory the directory to look for the files
-- @param extension the extension to look for 
Path.GetFilesByExtension = function(directory,extension)
    --TODO: if windows or linux
    local files = {}
    local command
    if(string.lower(jit.os) == "windows") then
        --List only the files of a given extension
        command = "dir " .. directory .. "*." .. extension .. "/b"
    else
        -- TODO: Specify directory
        command = "ls -1 " .. directory .. "/*." .. extension
    end

    local counter = 1
    -- Fill in a table with the  files.
    --for file in io.popen(command):lines() do
    --    files[counter] = file
    --    counter = counter + 1
    --end
    --return files
end

--- Find the given filename starting from cwd and moving upwards
-- @param filename The filename to look for
Path.FindFile = function(filename)
    local cur_dir = vim.fn.getcwd()
    local dir_sep = nil
    -- Determine the seperator for our operating system
    if package.config:sub(1,1) == '/' then
        dir_sep = '/'
    else
        dir_sep = '\\'
    end

    if(dir_sep == nil) then
        print("Your system directory seperator is not supported. Supported systems are unix like operating systems")
        return nil;
    end

    while true do
        -- fileOrPattern is a specific filename, check if it exists
        local file_path = cur_dir .. dir_sep .. filename
        local f = io.open(file_path)
        if f ~= nil then
            -- file was found, set the flag to true and return the current directory
            f:close()
            return file_path
        else
            -- If the file does not reside in the root folder then the file does not exist
            -- return nil
            -- TODO: C:\ is not always true in windows. Could be Z:\
            if(cur_dir == '/' or cur_dir == 'C:\\') then
                return nil
            end
            cur_dir = Path.GetParrentDirectory(cur_dir, dir_sep)
        end
    end
end

--- Retuens the first file that exists within our path with the given extension
-- @param extension The extension of the file
Path.FindFirstOccurenceOfExtension = function(extension)
    print("Finding First Occurence With Extension ".. extension)
    local cur_dir = vim.fn.getcwd()
    local dir_sep = nil
    -- Determine the seperator for our operating system
    if package.config:sub(1,1) == '/' then
        dir_sep = '/'
    else
        dir_sep = '\\'
    end

    if(dir_sep == nil) then
        print("Your system directory seperator is not supported. Supported systems are unix like operating systems")
        return nil;
    end

    if(cur_dir == nil) then
        return nil
    end

    local counter = 1;
    --TODO: Fix this. This does not return
    while true do
        counter = counter + 1
        if(counter == 20) then
            return
        end
        -- fileOrPattern is a specific filename, check if it exists
        if(Path.DirectoryContainsExtension(cur_dir,extension)) then
            local files = Path.GetFilesByExtension(cur_dir,extension)
            -- file was found, set the flag to true and return the current directory
            return files[1]
        else
            print(cur_dir)
            -- If the file does not reside in the root folder then the file does not exist
            -- return nil
            -- TODO: C:\ is not always true in windows. Could be Z:\
            if(cur_dir == '/' or cur_dir == 'C:') then
                return nil
            end
            cur_dir = Path.GetParrentDirectory(cur_dir, dir_sep)
        end
    end
end

return Path
