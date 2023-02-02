
-- This is the module that will be finaly returned to the editor
local solution = {}

--The modules that we will be using.
local Path = require("solution.path")
local Parser = require("solution.parser")
local win = require("solution.window")


local filenameSLN = nil

-- The test name that will be executed
local TestFunctionName = nil

-- The project file that contains the test.
local TestProject = nil

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
    arch = "x86",
    display = { -- Controls options for popup windows.
        removeCR = true,
        HideCompilationWarnings = true
    }
}

solution.setup = function(config)
    if (config == nil) then
        -- No configuration use default options
        print("No configuration")
        return
    else
        SolutionConfig = config
    end
    solution.GetCompilerVersion()
end

solution.SelectArchitecture = function()
    -- TODO make sure to have all the dotnet provided architectures.
    -- Or make this user configurable?
    local items = {
        "x86",
        "x64",
        "AnyCPU"
    }
    local opts = {
        prompt = "Change compile architecture to:"
    }
    vim.ui.select(items,opts,solution.SetArchitecture)
end

solution.SetArchitecture = function(item,index)
    if not item then
        return
    end
    _ = index
    SolutionConfig.arch = item
end

solution.SelectWaringDisplay = function()
    -- TODO make sure to have all the dotnet provided architectures.
    -- Or make this user configurable?
    local items = {
        "Show Warnings",
        "Hide Warnings",
    }
    local opts = {
        prompt = "When compiling:"
    }
    vim.ui.select(items,opts,solution.SetArchitecture)
end

solution.SetWarningDisplay = function(item,index)
    if not item then
        return
    end
    _ = index
    if(item == "Show Warnings") then
        SolutionConfig.display.HideCompilationWarnings = false
    else
        SolutionConfig.display.HideCompilationWarnings = true
    end
end

solution.CompileByFilename = function(filename, options)
    -- dotnet build [<PROJECT | SOLUTION>...] [options]
    local command = "dotnet build " .. filename .. " -c " .. options.BuildConfiguration
    if(Path.GetFileExtension(filename) ~= ".sln") then
        -- We cannot build a solution and specify a project architecture.
        --command = command .. " -a " .. options.arch
        _ = 5
    end
    command = command .. " -v q"

    -- The items to be displayed
    local items = {}
    -- Reset the quickfix list
    vim.fn.setqflist(items)
    local stringLines = {} -- Used to detect duplicates

    -- Detects if we have entries to our quickfix table
    local counter = 0

    -- Keep track the number of errors and warnings
    local errors = 0
    local warnings = 0


    local CompileOutputWindow = win.new(" Compiling " .. filename .. " ")
    CompileOutputWindow.PaintWindow()
    CompileOutputWindow.AddLine("Command: ".. command)
    CompileOutputWindow.AddLine("")


    local function on_event(job_id, data, event)
        -- Make the lsp shutup.
        _ = job_id
        -- While the job is running , it may write to stdout and stderr
        -- Here we handle when we write to stdout
        if event == "stdout" or event == "stderr" then
            -- If we have data, then append them to the lines array
            if data then
                for _,theLine in ipairs(data) do
                    CompileOutputWindow.AddLine(theLine,SolutionConfig.display.removeCR)
                    if not stringLines[theLine] then
                        stringLines[theLine] = true
                        local r = Parser.ParseLine(theLine)
                        if r then
                            counter = counter + 1
                            if (r.type == 'E') then
                                errors = errors + 1
                                -- Add the line to the table
                                vim.list_extend(items,{r})
                            else
                                warnings = warnings + 1
                                if(SolutionConfig.display.HideCompilationWarnings == false) then
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
            -- TODO: Add user configurable option to only open if there are errors
            -- TODO: User configurable option to only display errors or warnings
            if (counter > 0) then
                vim.fn.setqflist(items)
                vim.cmd.doautocmd("QuickFixCmdPost")
                vim.cmd.copen()
                CompileOutputWindow.BringToFront()
            end
        end
    end

    -- https://phelipetls.github.io/posts/async-make-in-nvim-with-lua/
    local id = vim.fn.jobstart(command,{
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
                    window.AddLine(theLine,SolutionConfig.display.removeCR)
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
    local id = vim.fn.jobstart(command,{
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

    local function on_event(job_id, data, event)
        -- Make the lsp shutup.
        _ = job_id
        -- While the job is running , it may write to stdout and stderr
        -- Here we handle when we write to stdout
        if event == "stdout" or event == "stderr" then
            -- If we have data, then append them to the lines array
            if data then
                for _,theLine in ipairs(data) do
                    window.AddLine(theLine,SolutionConfig.display.removeCR)
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
    local id = vim.fn.jobstart(command,{
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

    local function HandleData(job_id, data, event)
        -- Handle Data Written to stdout
        count = count+1
        if data then
            CompilerVersion = data[2]
        end
    end

    local id = vim.fn.jobstart(command,{
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


solution.PerformCommand = function(command,options)
    -- Reset the filename
    filenameSLN = nil
    if not options then
        options = SolutionConfig
    end

    if(options.ProjectSelectionPolicy == "first") then
        -- Do not select file. Find the first applicable file.
        local slnFile = Path.FindUpstreamFilesByExtension(".sln")
        if(slnFile[1] == nil ) then
            print("No solution file found")
            slnFile = Path.FindUpstreamFilesByExtension(".csproj")
            if(slnFile[1] == nil ) then
                return
            else
                filenameSLN = slnFile[1]
            end
        else
            filenameSLN = slnFile[1]
        end
    elseif (options.ProjectSelectionPolicy == "select") then
        -- Select file
        solution.AskForSelection(options)
    else
        print("Invalid selection policy")
        return
    end

    if not filenameSLN then
        print("No project or solution detected. Returning.")
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

solution.Compile= function(options)
    solution.PerformCommand("build", options)
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
    if(TestProject ~= nil and TestFunctionName ~= nil) then
        tm.ExecuteSingleTest(TestProject,TestFunctionName)
    end
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
        end
    end
end

--- Clears the test that will be invoked by the TestSelected method.
solution.ClearTest = function()
    TestFunctionName = nil
    TestProject = nil
end


solution.FunctionTest = function()
    --local p = require("solution.SolutionParser")
    --print("Hello")
    --p.ParseSolution("C:/users/Admin/source/repos/AIStream/AIStream.sln")
    --p.ParseSolution("C:/users/Admin/source/repos/AIStream/AIStream.sln")
    local p = require("solution.ProjectParser")
    p.GetBinaryOutput("C:/users/Admin/source/repos/AIStream/AIStream.sln")
end

return solution
