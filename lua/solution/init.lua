
-- This is the module that will be finaly returned to the editor
local solution = {}

--The modules that we will be using.
local Path = require("solution.path")

------------------------------------------------------------------------------
--- HELPER FUNCTIONS --
------------------------------------------------------------------------------
local function CountItems(list)
    local count = 0
    for _ in pairs(list) do
        count = count + 1 end
    return count
end



-- This table stores the plugin configuration
-- The Keys that we need:
-- ExecuteFirstSolution = true/false
local SolutionConfig = {
    selection = "first",
    ext = ".sln",
    conf = "Debug",
    arch = "x86"
}

solution.setup = function(config)
    if (config == nil) then
        -- No configuration use default options
        print("No configuration")
        return
    else
        SolutionConfig = config
    end
end

solution.CompileByFilename = function(filename, options)
    -- dotnet build [<PROJECT | SOLUTION>...] [options]
    local command = "dotnet build " .. filename-- .. " -c " .. options.conf-- .. " -a " .. options.arch
    local id = vim.fn.jobstart(command)
    if(id == 0) then
        print("Invalid Compilation Arguments")
    else
        print("Compilation Complete")
    end

    --vim.loop.spawn('dotnet build', {
    --    args = {filename,'-c',options.conf,'-a',options.arch}
    --}, function()
    --    print("Compilation Complete")
    --end)
end

--- Compiles the solution
solution.CompileFirst = function(options)
    local slnFile = Path.FindUpstreamFilesByExtension(options.ext)
    if(slnFile[1] == nil ) then
        print("No solution file found")
        return
    end
    solution.CompileByFilename(slnFile[1], options)
end

local function OnSelection(table, index)
    if(index == nil) then
        return
    end

    solution.CompileByFilename(table[index],SolutionConfig)
end

-- Ask for selection
solution.CompileSelect = function(options)
    local slnFile = Path.FindUpstreamFilesByExtension(options.ext)
    if(slnFile == nil) then
        print("No solution file found")
        return
    end

    SelectionOptions = {
        prompt = "Select file to compile.."
    }

    vim.ui.select(slnFile,SelectionOptions,OnSelection)
end

solution.Compile= function(options)
    if not options then
        options = SolutionConfig
    end
    if(options.selection == "first") then
        if(options.ext == nil) then
            print("Options extension is nill. Doing nothing.")
        end
        solution.CompileFirst(options)
    else
        solution.CompileSelect(options)
    end
end

return solution
