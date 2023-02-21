
-- This is the module that will be finaly returned to the editor
local solution = {}

--The modules that we will be using.
local Path = require("solution.path")
local Parser = require("solution.parser")
local win = require("solution.window")
local SolutionParser = require("solution.SolutionParser")

------------------------------------------------------------------------------
--                    P R I V A T E  M E M B E R S                          --
------------------------------------------------------------------------------

-- File filename of the solution or project that is beeing parsed.
local filenameSLN = nil

-- The current in memory solution or project
local InMemorySolution = nil

-- The test name that will be executed
local TestFunctionName = nil

-- The project file that contains the test.
local TestProject = nil


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
    ProjectSelectionPolicy = "first",
    BuildConfiguration = "Debug",
    BuildPlatform = "Any CPU",
    Display = { -- Controls options for popup windows.
        RemoveCR = true,
        HideCompilationWarnings = true
    },
}

--- Define user options for the plugin configuration
-- @param config The user options configuraton object
solution.setup = function(config)
    if (config == nil) then
        -- No configuration use default options that have already been predefined.
        print("No configuration")
        return
    else
        SolutionConfig = config
    end

    local r = solution.ValidateConfiguration(SolutionConfig)
    if(not r) then
        return;
    end

    solution.GetCompilerVersion()

    vim.api.nvim_create_user_command("HelloSolution"       , 'echo \"Hello Solution\"'                                       , {desc = "Displays a greeting message"                } )
    vim.api.nvim_create_user_command("LoadSolution"        , function() solution.FindAndLoadSolution(SolutionConfig) end     , {desc = "Loads a solution in memory"                 } )
    vim.api.nvim_create_user_command("DisplaySolution"     , function() SolutionParser.DisplaySolution(InMemorySolution) end , {desc = "Displays the loaded solution"               } )
    vim.api.nvim_create_user_command("SelectConfiguration" , solution.SelectConfiguration                                    , {desc = "Select Active Build Configuration"          } )
    vim.api.nvim_create_user_command("SelectPlatform"      , solution.SelectPlatform                                         , {desc = "Select Active Build Platform"               } )
    vim.api.nvim_create_user_command("SelectWaringDisplay" , solution.SelectWaringDisplay                                    , {desc = "Select if compilation warnings are visible" } )
    vim.api.nvim_create_user_command("SelectTest"          , solution.SetTest                                                , {desc = "Select a test for debug"                    } )
    vim.api.nvim_create_user_command("ExecuteTest"         , solution.TestSelected                                           , {desc = "Select a test for debug"                    } )
    -- Execute test in debug mode
    vim.api.nvim_create_user_command("DebugTest"           , function() print("Not yet implemented!") end                    , {desc = "Select a test for debug"                    } )
end

solution.ValidateConfiguration = function(config)
    local RequiredConfigKeys = {
        ["ProjectSelectionPolicy"] = true,
        ["BuildConfiguration"]     = true,
        ["BuildPlatform"]          = true,
        ["Display"]                = true
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
    -- Validate correct values individually
    if(config.ProjectSelectionPolicy ~= "first" and config.ProjectSelectionPolicy ~= "selection") then
        return false
    end

    -- Build configuration may be any string
    if(type(config.BuildConfiguration) ~= "string") then
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

--- Prompts the user to select the configuration that will be used for the project.
solution.SelectConfiguration = function()
    if(InMemorySolution == nil) then
        -- Try to find a solution. Maybe there is no solution is loaded.
        solution.FindAndLoadSolution()
        if(InMemorySolution == nil) then
            print("No solution found!")
            return
        end
    end

    local items = {
    }

    local hash = {
    }

    for _,v in ipairs(InMemorySolution.SolutionConfigurations) do
        -- We may have the same configuration with mulitple platforms
        -- We only keep the unique values using the hash table but we also
        -- print them in order or declaration
        if(not hash[v[1]]) then
            hash[v[1]] = true
            table.insert(items,v[1])
        end
    end

    local opts = {
        prompt = string.format("Select Build Configuration [%s]:",InMemorySolution.SolutionPath)
    }
    vim.ui.select(items,opts,solution.SetConfiguration)
end

solution.SetConfiguration = function(item,index)
    if not item then
        return
    end
    _ = index
    SolutionConfig.BuildConfiguration = item
end

solution.SelectPlatform = function()
    if(InMemorySolution == nil) then
        -- Try to find a solution. Maybe there is no solution is loaded.
        solution.FindAndLoadSolution()
        if(InMemorySolution == nil) then
            vim.notify("No solution found.",vim.log.levels.WARN, {title="Solution.nvim"})
            return
        end
    end

    local items = {
    }

    local hash = {
    }

    for _,v in ipairs(InMemorySolution.SolutionConfigurations) do
        -- We may have the same configuration with mulitple platforms
        -- We only keep the unique values using the hash table but we
        -- also print them in order or declaration
        if(v[1] == SolutionConfig.BuildConfiguration) then
            if(not hash[v[2]]) then
                hash[v[2]] = true
                table.insert(items,v[2])
            end
        end
    end

    local opts = {
        prompt = string.format("Select Platform for [%s] Configuration [%s]:",InMemorySolution.SolutionPath,SolutionConfig.BuildConfiguration)
    }
    vim.ui.select(items,opts,solution.SetConfiguration)
end

solution.SetPlatform = function(item,index)
    if not item then
        return
    end
    _ = index
    SolutionConfig.BuildPlatform = item
end

solution.SelectWaringDisplay = function()
    local items = {
        "Show Warnings",
        "Hide Warnings",
    }
    local opts = {
        prompt = "When compiling:"
    }
    vim.ui.select(items,opts,solution.SetConfiguration)
end

solution.SetWarningDisplay = function(item,index)
    if not item then
        return
    end
    _ = index
    if(item == "Show Warnings") then
        SolutionConfig.Display.HideCompilationWarnings = false
    else
        SolutionConfig.Display.HideCompilationWarnings = true
    end
end

solution.GetOutputLocations = function()
    return OutputLocations
end

solution.CompileByFilename = function(filename, options)
    -- dotnet build [<PROJECT | SOLUTION>...] [options]
    local command = "dotnet build " .. filename .. " -c " .. options.BuildConfiguration
    if(Path.GetFileExtension(filename) ~= ".sln") then
        -- We cannot build a solution and specify a project architecture.
        --command = command .. " -a " .. options.arch
        _ = 5
    end

    -- The items to be Displayed
    local items = {}
    -- Reset the quickfix list
    vim.fn.setqflist(items)
    local stringLines = {} -- Used to detect duplicates

    -- Detects if we have entries to our quickfix table
    local counter = 0

    -- Keep track the number of errors and warnings
    local errors = 0
    local warnings = 0

    OutputLocations = nil


    local CompileOutputWindow = win.new(" Compiling " .. filename .. " ")
    CompileOutputWindow.PaintWindow()
    CompileOutputWindow.AddLine("Command: ".. command)
    CompileOutputWindow.AddLine("")

    local ErrorHighlight = {
        hl_group = "Error",
    }

    local WarningHighlight = {
        hl_group = "WarningMsg",
    }


    local CurrentOutputLocations = {}

    local function on_event(_, data, event)
        -- TODO: Rewrite code to remove too much nesting
        -- While the job is running , it may write to stdout and stderr
        -- Here we handle when we write to stdout
        if event == "stdout" or event == "stderr" then
            -- If we have data, then append them to the lines array
            if data then
                for _,theLine in ipairs(data) do
                    CurrentOutputLocations = Parser.ParseOutputDirectory(theLine,CurrentOutputLocations)
                    local r = Parser.ParseLine(theLine)
                    if (r ~= nil and r.type == 'E') then
                        CompileOutputWindow.AddLine(theLine,SolutionConfig.Display.RemoveCR,ErrorHighlight)
                    elseif (r ~= nil and r.type == 'W') then
                        CompileOutputWindow.AddLine(theLine,SolutionConfig.Display.RemoveCR,WarningHighlight)
                    else
                        CompileOutputWindow.AddLine(theLine,SolutionConfig.Display.RemoveCR)
                    end
                    if not stringLines[theLine] then
                        stringLines[theLine] = true
                        if r then
                            if (r.type == 'E') then
                                errors = errors + 1
                                counter = counter + 1
                                -- Add the line to the table
                                vim.list_extend(items,{r})
                            else
                                warnings = warnings + 1
                                if(SolutionConfig.Display.HideCompilationWarnings == false) then
                                    counter = counter + 1
                                    vim.list_extend(items,{r})
                                end
                            end
                        end
                    end
                end
            end
        end

        -- When the job exits, populate the quick fix list
        if event == "exit" then
            local CounterToUse = 0;
            if(SolutionConfig.Display.HideCompilationWarnings == true) then
                CounterToUse = errors
            else
                CounterToUse = counter
            end

            if (CounterToUse > 0) then
                vim.fn.setqflist(items)
                vim.cmd.doautocmd("QuickFixCmdPost")
                vim.cmd.copen()
                CompileOutputWindow.BringToFront()
            else
                vim.cmd.cclose()
            end
            OutputLocations = CurrentOutputLocations
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

    if(options.ProjectSelectionPolicy == "first") then
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
    elseif (options.ProjectSelectionPolicy == "select") then
        -- Select file
        solution.AskForSelection(options)
    else
        print("Invalid selection policy")
        return
    end

    if not filename then
        return 2
    end

    if(InMemorySolution == nil or InMemorySolution.SolutionPath ~= filename) then
        -- Parse Solution
        InMemorySolution = SolutionParser.ParseSolution(filename)
        filenameSLN = filename
        vim.notify("Loaded "..filename,vim.log.levels.INFO, {title="Solution.nvim"})
    end
end

solution.PerformCommand = function(command,options)
    -- This wil popoulate the filenameSLN value
    solution.FindAndLoadSolution(options)
    if not filenameSLN then
        vim.notify("No project or solution detected.",vim.log.levels.ERROR, {title="Solution.nvim"})
        return
    end

    if (command == "build") then
        solution.CompileByFilename(filenameSLN,options)
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

solution.Compile = function()
    solution.PerformCommand("build", SolutionConfig)
end

solution.Clean= function(options)
    solution.PerformCommand("clean", options)
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
