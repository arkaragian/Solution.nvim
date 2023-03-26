-- Path is a central module that helps the editor localize within
-- the filesystem. It's goal is to provide functions that will help
-- us locate our solution files.
--
-- this file should be called as follows from other plugin code:
-- local Path = require("solution.path")
local Path = {}

local os = require("solution.osutils")

Path.GetFilenameFromPath = function(filepath,withExtension)
    -- The filename is between the os seperator and the dot in the file if it
    -- exists
    local start, finish = filepath:find('[%w%s!-={-|]+[_%.].+')
    local filename =filepath:sub(start,finish)
    if(withExtension) then
        return filename
    else
        -- dot is magic character needs to be escaped.
        local i,_ = string.find(filename,"%.")
        return string.sub(filename,1,i-1)
    end
end

--- Returns the extension of a given filename 
-- The function will return nill if the file does not have an extension
-- @param filename the filename e.g main.c
Path.GetFileExtension = function(filename)
    local dotIndex = -1
    local len = string.len(filename)
    -- # operator returns the lenght of string
    for i = len,1,-1 do
        local c = string.sub(filename,i,i)
        if(c == '.') then
            dotIndex = i
            break
        end
    end
    if (dotIndex > 0) then
        return string.sub(filename,dotIndex,len)
    else
        return nil
    end
end

--- Return the parent directory for a given path
-- @param path The input path
-- @param seperator The directory seperator
Path.GetParrentDirectory = function(path,seperator)
    local len =string.len(path)
    -- If the path ends in the seperator character, just remove the seprator character
    -- In linux os the root is "/" and ends in a seperator. So we keep that in mind.
    if (string.sub(path,len,len) == seperator and len > 1) then
        path =string.sub(path,1,len-1)
        len = len -1;
    end

    -- The parent of the root directory is the root directory. So before starting
    -- to make any processing check if we are at the root. If so just return the
    -- root.
    --if(string.lower(jit.os) == "windows") then
    if(os.system() == "windows") then
        -- Windows are complicated to handle because we don't really know the
        -- root. Could be C:\ D:\ etc. So check we get the first elements of the
        -- path and compare with the path itself.

        local start -- The starting part of the path.
        if (len >= 3) then
            start =string.sub(path,1,3)
        else
            start =string.sub(path,1,2)
        end


        -- If we have reached the drive. such as: C:\ D:\ or whatever
        if(start == path) then
            if( len == 3) then
                return path
            elseif (len == 2) then
                -- If the input is C: return C:\ instead.
                return path .. seperator
            end
        end
    else
        -- Linux handling is simple
        if(path == "/" or path == "//") then
            return "/"
        end
    end


    -- Get last seperator position
    local lastSeperatorIndex = 0;
    for i=1,string.len(path) do
        -- Get a character by extracting from i to i
        local c = string.sub(path,i,i)
        if(c == seperator) then
            lastSeperatorIndex = i
        end
    end

    -- The parent path is from the start up to the position before the last seperator.
    local parent =  string.sub(path,1,lastSeperatorIndex-1)
    len = string.len(parent)

    if(len == 2 and os.system() == "windows") then
        -- Again in windows when we split at the seperator we may get a path like
        -- C:
        return parent .. seperator
    end
    -- If there is no special case just return the path.
    return parent
end

--- Determines if the given directory contains any files of the given extension
-- @param dir The directory path to check
-- @param extension The extension to check for
Path.GetFilesByExtension = function(directory,extension)

    local command
    local isWin = (os.system() == "windows")
    local sep = os.seperator
    if(isWin) then
        -- The CMD command is: dir /b /a-d <path> lists only files or File Not Found
        -- This will list the files only Or "file not found"
        command = 'dir /b /a-d "' .. directory .. '"'
    else
        -- This will list the files and directories. But the directories appended with "/"
        command = 'ls -1p ' .. directory
    end

    local filesList = {}
    local index = 1
    -- search for files in the directory that have the given extension
    for file in io.popen(command):lines() do
        if(isWin) then
            if file == "File Not Found" then
                return {}
            end

            if (Path.GetFileExtension(file) == extension) then
                filesList[index] = directory .. sep .. file
                index = index + 1
            end
        else
            if (Path.GetFileExtension(file) == extension) then
                filesList[index] = directory .. sep .. file
                index = index + 1
            end
        end
    end
    return filesList
end

--- Gets all the directories in the given directory
-- @param dir The directory to list 
Path.Directories = function(directory)

    local command
    local isWin = (os.system() == "windows")
    local sep = os.seperator
    if(isWin) then
        -- The CMD command is: dir /b /ad <path>
        -- List in bare format (name only)
        -- List only items with the directory attribute
        -- If there is no directory the following two will be returned
        -- .  (Current)
        -- .. (Parrent)
        command = 'dir /b /ad "' .. directory .. '"'
    else
        -- This will list the files and directories. But the directories appended with "/"
        command = 'ls -1p ' .. directory
    end

    local filesList = {}
    local index = 1
    -- search for files in the directory that have the given extension
    for file in io.popen(command):lines() do
        if(isWin) then
            if (file == "." or file == "..") then
                goto wincontinue
            end

            filesList[index] = file
            index = index + 1

            ::wincontinue::
        else
            filesList[index] = file
            index = index + 1
        end
    end
    return filesList
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

--- Returns the files by a specific extension that are contained the CDW
--- or upstream directories.
-- @param extension The extension of the file
Path.FindUpstreamFilesByExtension = function(extension)
    if( extension == nil ) then
        print("Extension is nil. Returning empty table")
        return {}
    end
    local cur_dir = vim.fn.getcwd()
    local dir_sep = os.seperator

    if(cur_dir == nil) then
        return {}
    end

    local prev_dir = "nothing"
    while (prev_dir ~= cur_dir) do
        local files = Path.GetFilesByExtension(cur_dir,extension)
        if (next(files) ~= nil) then
            return files
        end
        prev_dir = cur_dir
        cur_dir = Path.GetParrentDirectory(cur_dir, dir_sep)
    end
end

return Path
