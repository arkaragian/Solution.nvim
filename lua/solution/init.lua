
-- This is the module that will be finaly returned to the editor
local solution = {}

--The modules that we will be using.
local Path = require("solution.path")
local win = require("solution.window")
local SolutionParser = require("solution.SolutionParser")
local SolutionManager = require("solution.SolutionManager")
local TestManager = require("solution.TestManager")
local Project = require("solution.Project")
local CacheManager = require("solution.CacheManager")

------------------------------------------------------------------------------
--                    P R I V A T E  M E M B E R S                          --
------------------------------------------------------------------------------

local SolutionSelectionPolicies = {
    First = "first",
    Selection = "selection"
}

-- File filename of the solution or project that is beeing parsed.
local filenameSLN = nil

-- The test name that will be executed
local TestFunctionName = nil

-- The project file that contains the test.
local TestProject = nil

-- The locations of the output binaries
local OutputLocations = nil

--Could be used to configure the parser.
--local CompilerVersion = nil

-- This table stores the plugin configuration
-- The Keys that we need:
-- selection = first|selection
local SolutionConfig = {
    -- Indicates the selection policy. Currently there are two policies.
    -- 1) first
    -- 2) selection
    -- First indicates to use the first file that is found and is applicable
    -- select indicates to ask to selection of there are multiple files found
    SolutionSelectionPolicy = "first",
    DefaultBuildConfiguration = "Debug",
    DefaultBuildPlatform = "Any CPU",
    Display = { -- Controls options for popup windows.
        RemoveCR = true,
        HideCompilationWarnings = true
    },
}


--- Define user options for the plugin configuration
-- @param config The user options configuraton object
solution.setup = function(config)
    if (config == nil or config == {}) then
        -- No configuration use default options that have already been predefined.
        return
    else
        SolutionConfig = config
    end

    local r = solution.ValidateConfiguration(SolutionConfig)
    if(not r) then
        vim.notify("Invalid configuration!",vim.log.levels.ERROR,{title="Solution.nvim"})
        return;
    end

    solution.GetCompilerVersion()

    vim.api.nvim_create_user_command("LoadSolution"             , solution.LoadSolution             , {desc = "Loads a solution in memory"                 } )
    vim.api.nvim_create_user_command("DisplaySolution"          , solution.DisplaySolution          , {desc = "Displays the loaded solution"               } )
    vim.api.nvim_create_user_command("DisplayExecutables"       , solution.DisplayOutputs           , {desc = "Displays the loaded solution"               } )
    vim.api.nvim_create_user_command("SelectBuildConfiguration" , solution.SelectBuildConfiguration , {desc = "Select Active Build Configuration"          } )
    vim.api.nvim_create_user_command("SelectPlatform"           , solution.SelectBuildPlatform      , {desc = "Select Active Build Platform"               } )
    vim.api.nvim_create_user_command("SelectWaringDisplay"      , solution.SelectWaringDisplay      , {desc = "Select if compilation warnings are visible" } )
    vim.api.nvim_create_user_command("SelectStartupProject"     , solution.SelectStartupProject     , {desc = "Select the solution startup project"        } )
    vim.api.nvim_create_user_command("SelectTest"               , solution.SetTest                  , {desc = "Select a test for debug"                    } )
    vim.api.nvim_create_user_command("ExecuteTest"              , solution.TestSelected             , {desc = "Select a test for debug"                    } )
    vim.api.nvim_create_user_command("LaunchSolution"            ,solution.LaunchSolution           , {desc = "Launch the solution"                        } )
    vim.api.nvim_create_user_command("ListProjectProfiles"      , solution.ListProjectProfiles      , {desc = "Launch a project"                           } )
    vim.api.nvim_create_user_command("CompileSolution"          , solution.Compile                  , {desc = "Compiles the currently loaded solution"     } )
    -- Execute test in debug mode
    vim.api.nvim_create_user_command("DebugTest"           , function() TestManager.DebugTest(TestFunctionName) end          , {desc = "Select a test for debug"                    } )



    --Generate the cache directory.
    CacheManager.CreateCacheRoot()

    SolutionManager.SetBuildConfiguration(SolutionConfig.DefaultBuildConfiguration)
    SolutionManager.SetBuildPlatform(SolutionConfig.DefaultBuildPlatform)

    --Setup autocommand to autoload the solution
    local SolutionNvimSolutionAutoLoader = vim.api.nvim_create_augroup("SolutionNvimSolutionAutoLoader", { clear = true })

    vim.api.nvim_create_autocmd("BufEnter", {
        pattern = {"*.cs,*.csproj,*.sln"},
        --command = solution.LoadSolution,
        callback = solution.LoadSolution,
        group = SolutionNvimSolutionAutoLoader,
    })
end

-----------------------------------------------------------------------------
--               U S E R  M A P P A B L E  P U B L I C  A P I              --
-----------------------------------------------------------------------------

solution.LoadSolution = function()
    solution.FindAndLoadSolution(SolutionConfig)
end

solution.DisplaySolution = function()
    SolutionParser.DisplaySolution(SolutionManager.Solution)
end

solution.DisplayOutputs = function()
    SolutionManager.DisplayOutputs()
end

solution.SelectBuildConfiguration = function()
    SolutionManager.SelectBuildConfiguration()
end

solution.SelectBuildPlatform = function()
    SolutionManager.SelectBuildPlatform()
end

solution.SelectStartupProject = function()
    SolutionManager.SelectStartupProject()
end

solution.ListProjectProfiles = function()
    local ppath = SolutionParser.GetProjectPath(SolutionManager.Solution,1)
    Project.GetProjectProfiles(ppath)
end

solution.Compile = function()
    SolutionManager.CompileSolution()
end

solution.LaunchSolution = function()
    SolutionManager.Launch()
end
-----------------------------------------------------------------------------


solution.ValidateConfiguration = function(config)
    local RequiredConfigKeys = {
        ["SolutionSelectionPolicy"]   = true,
        ["DefaultBuildConfiguration"] = true,
        ["DefaultBuildPlatform"]      = true,
        ["Display"]                   = true
    }

    local RequiredDisplayKeys = {
        ["RemoveCR"]                = true,
        ["HideCompilationWarnings"] = true
    }


    for key, _ in pairs(RequiredConfigKeys) do
        if(config[key] == nil) then
            print(string.format("Key %s not found!",key))
            return false
        end
    end
    -- TODO Fix this check using the enum
    -- Validate correct values individually
    --if(config.ProjectSelectionPolicy ~= "first" and config.ProjectSelectionPolicy ~= "selection") then
    --    return false
    --end
    local checkOk = false
    for _,v in pairs(SolutionSelectionPolicies) do
        if(config.SolutionSelectionPolicy == v) then
            checkOk = true
        end
    end
    if(checkOk == false) then
        return false
    end

    -- Build configuration may be any string
    if(type(config.DefaultBuildConfiguration) ~= "string") then
        return false
    end

    if(type(config.Display) ~= "table") then
        return false
    end

    for key, _ in pairs(RequiredDisplayKeys) do
        if(config.Display[key] == nil) then
            print(string.format("Key Display.%s not found!",key))
            return false
        end
    end

    return true
end


solution.SelectWaringDisplay = function()
    local items = {
        "Show Warnings",
        "Hide Warnings",
    }
    local opts = {
        prompt = "When compiling:"
    }

    local SelectionHandler = function(item,_) -- Discard index
        if not item then
            return
        end
        if(item == "Show Warnings") then
            SolutionConfig.Display.HideCompilationWarnings = false
        else
            SolutionConfig.Display.HideCompilationWarnings = true
        end
    end

    vim.ui.select(items,opts,SelectionHandler)
end


solution.CleanByFilename = function(filename)
    -- dotnet build [<PROJECT | SOLUTION>...] [options]
    local command = "dotnet clean " .. filename
    print("Cleaning:" .. filename)

    local window = win.new("Cleaning..")
    window.PaintWindow()

    local function on_event(job_id, data, event)
        -- Make the lsp shutup.
        _ = job_id
        -- While the job is running , it may write to stdout and stderr
        -- Here we handle when we write to stdout
        if event == "stdout" or event == "stderr" then
            -- If we have data, then append them to the lines array
            if data then
                for _,theLine in ipairs(data) do
                    window.AddLine(theLine,SolutionConfig.Display.RemoveCR)
                end
            end
        end

        -- When the job exits, populate the quick fix list
        if event == "exit" then
            -- Make the lsp setup here.
            local a = 5
            _ = a
        end
    end

    -- https://phelipetls.github.io/posts/async-make-in-nvim-with-lua/
    local _ = vim.fn.jobstart(command,{
        on_stderr = on_event,
        on_stdout = on_event,
        on_exit = on_event,
        --stdout_buffered = true,
        --stderr_buffered = true,
    })
end

solution.TestByFilename = function(filename)
    local command = "dotnet test " .. filename .. " --logger:console"

    local window = win.new("Testing..")
    window.PaintWindow()

    local function on_event(_, data, event)
        -- While the job is running , it may write to stdout and stderr
        -- Here we handle when we write to stdout
        if event == "stdout" or event == "stderr" then
            -- If we have data, then append them to the lines array
            if data then
                for _,theLine in ipairs(data) do
                    window.AddLine(theLine,SolutionConfig.Display.RemoveCR)
                end
            end
        end

        -- When the job exits, populate the quick fix list
        if event == "exit" then
            -- Make the lsp setup here.
            local a = 5
            _ = a
        end
    end

    -- https://phelipetls.github.io/posts/async-make-in-nvim-with-lua/
    local _ = vim.fn.jobstart(command,{
        on_stderr = on_event,
        on_stdout = on_event,
        on_exit = on_event,
        --stdout_buffered = true,
        --stderr_buffered = true,
    })
end


solution.GetCompilerVersion = function()
    local command = "dotnet build --version"

    local count = 0

    -- Inputs are -> job_id, data, event
    local function HandleData(_, data, _)
        -- Handle Data Written to stdout
        count = count+1
        if data then
            CompilerVersion = data[2]
        end
    end

    local _ = vim.fn.jobstart(command,{
        on_stdout = HandleData,
        stdout_buffered = true,
        stderr_buffered = true,
    })
end

local function OnSelection(table, index)
    if(index == nil) then
        filenameSLN = nil
        return
    end

    filenameSLN = table[index]
    --solution.CompileByFilename(table[index],SolutionConfig)
end

-- Ask for selection
solution.AskForSelection = function(options)
    local ProjectOrSolution = Path.FindUpstreamFilesByExtension(".sln")
    if(ProjectOrSolution == nil) then
        print("No solution file found")
        ProjectOrSolution = Path.FindUpstreamFilesByExtension(".csproj")
        if(ProjectOrSolution == nil) then
            return
        end
    end


    SelectionOptions = {
        prompt = "Select file to compile.."
    }

    vim.ui.select(ProjectOrSolution,SelectionOptions,OnSelection)
end

solution.GetCSProgram= function()
    return SolutionManager.GetCSProgram();
end

--- Locates the .sln where the file that is currently edited belong to and loads
-- is into memory. This is private member and we reserve the right to change it
-- any time.
-- @param options The plugin configuration options
solution.FindAndLoadSolution = function(options)

    local filename = nil
    -- If no options are provided use the default options.
    if not options then
        options = SolutionConfig
    end

    if(options.SolutionSelectionPolicy == SolutionSelectionPolicies.First ) then
        -- Do not select file. Find the first applicable file.
        local slnFile = Path.FindUpstreamFilesByExtension(".sln")
        if(slnFile == nil ) then
            -- No solution file found. Try to fall back to a csproj
            vim.notify("No sln file located. Trying to locate csproj file.",vim.log.levels.WARN, {title="Solution.nvim"})
            slnFile = Path.FindUpstreamFilesByExtension(".csproj")
            if(slnFile == nil ) then
                return 1
            else
                filename = slnFile[1]
            end
        else
            filename = slnFile[1]
        end
    elseif (options.SolutionSelectionPolicy == SolutionSelectionPolicies.Selection) then
        -- Select file
        solution.AskForSelection(options)
    else
        print("Invalid selection policy")
        return
    end

    if not filename then
        return 2
    end

    if(SolutionManager.Solution == nil or SolutionManager.Solution.SolutionPath ~= filename) then
        -- Parse Solution
        SolutionManager.Solution = SolutionParser.ParseSolution(filename)
        CacheManager.SetupCache(SolutionManager.Solution.SolutionPath)
        vim.notify("Loaded "..filename,vim.log.levels.INFO, {title="Solution.nvim"})
    end

    local CacheData = CacheManager.ReadCacheData(SolutionManager.Solution.SolutionPath)
    if(CacheData ~= nil) then
        SolutionManager.HandleCacheData(CacheData)
    end
end


solution.PerformCommand = function(command,options)
    -- This wil popoulate the filenameSLN value
    solution.FindAndLoadSolution(options)
    if not filenameSLN then
        vim.notify("No project or solution detected.",vim.log.levels.ERROR, {title="Solution.nvim"})
        return
    end

    if (command == "clean") then
        solution.CleanByFilename(filenameSLN)
        return
    end

    if (command == "test") then
        solution.TestByFilename(filenameSLN)
        return
    end

    if (command == "ListTest") then
        local tm = require("solution.TestManager")
        tm.GetTests(filenameSLN)
        return
    end
end

solution.Clean= function(options)
    solution.PerformCommand("clean", options)
end

solution.LaunchProject = function()
    -- Get Current Startup project.
    -- Get active profile if a Properties directory exist 
end

solution.Test = function()
    solution.PerformCommand("test", options)
end

--- Execute a single test.
solution.TestSelected = function()
    local tm = require("solution.TestManager")
    if(TestProject == nil) then
        vim.notify("Test project is nil noothing to execute",vim.log.levels.WARN,{title="Solution.nvim"})
        return
    end

    if(TestFunctionName == nil) then
        vim.notify("No test function selected. Nothing to execute",vim.log.levels.WARN,{title="Solution.nvim"})
    end

    tm.ExecuteSingleTest(TestProject,TestFunctionName)
end

--- Load all the tests that are reported by dotnet
solution.GetTests = function()
    solution.PerformCommand("ListTest", options)
end

--- Sets the test that will be invoked by the TestSelected method.
solution.SetTest = function()
    local tm = require("solution.TestManager")
    local s = tm.GetTestUnderCursor()
    if (s ~= nil) then
        local project = Path.FindUpstreamFilesByExtension(".csproj")
        if(project[1] == nil ) then
            return
        else
            TestProject = project[1]
            TestFunctionName = s
            local msg = string.format("Selected test %s:", s)
            vim.notify(msg, vim.log.levels.INFO, {title="Solution.nvim"})
        end
    end
end

--- Clears the test that will be invoked by the TestSelected method.
solution.ClearTest = function()
    TestFunctionName = nil
    TestProject = nil
end

--- Clears the test that will be invoked by the TestSelected method.
solution.WriteSolution= function()
    local p = require("solution.SolutionParser")
    local s = p.ParseSolution("C:/users/Admin/source/repos/MVEnc/MVEnc.sln")

    local p = require("solution.SolutionWriter").WriteSolution(s)
end


solution.FunctionTest = function()
    local p = require("solution.SolutionParser")
    --print("Hello")
    --p.ParseSolution("C:/users/Admin/source/repos/AIStream/AIStream.sln")
    --local s = p.ParseSolution("C:/users/Admin/source/repos/AIStream/AIStream.sln")
    local s = p.ParseSolution("C:/users/Admin/source/repos/MVEnc/MVEnc.sln")
    p.DisplaySolution(s)
    --local p = require("solution.ProjectParser")
    --p.GetBinaryOutput("C:/users/Admin/source/repos/AIStream/AIStream.sln")
end

-- Let everyone else know that we have loaded
vim.g.SolutionPluginLoaded = true

return solution
