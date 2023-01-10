
-- This is the module that will be finaly returned to the editor
local solution = {}


--The modules that we will be using.
local Path = require("solution.path")

-- This table stores the plugin configuration
-- The Keys that we need:
-- ExecuteFirstSolution = true/false
SolutionConfig = SolutionConfig or {}

function solution.setup(config)
    if not config then
        SolutionConfig.ExecuteFirstSolution = true
        return
    end

    SolutionConfig.ExecuteFirstSolution = config.ExecuteFirstSolution
end

--- Compiles the solution
function solution.CompileSolution()
    local slnFile = Path.FindFirstOccurenceOfExtension("sln")
    if(slnFile == nil) then
        print("No solution file found")
        return
    end
    local command = "dotnet build " .. slnFile
    print(command)
end

--- Compiles the current project
function solution.CompileProject()
    print("Compile Project")
end

return solution
