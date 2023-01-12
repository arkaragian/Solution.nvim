
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
SolutionConfig = {
    selection = "first",
    ext = ".csproj",
    conf = "Debug",
    arch = "x64"
}

solution.setup = function(config)
    if not config then
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
    print("Command is:" .. command)
    -- TODO: Investigate vim jobstart
    --local code = os.execute(command)
    vim.fn.jobstart(command)
    --print("Exit code is:" .. code)
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
        solution.CompileFirst(options.ext)
    else
        --solution.CompileSelect(options.ext)
    end
end

return solution
