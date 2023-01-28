
-- This is the module that will be finaly returned to the editor
local solution = {}

--The modules that we will be using.
local Path = require("solution.path")
local Parser = require("solution.parser")
local Ui = require("solution.ui")


local filenameSLN = nil

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
        removeCR = true
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
    SolutionConfig.arch = item
end

solution.CompileByFilename = function(filename, options)
    -- dotnet build [<PROJECT | SOLUTION>...] [options]
    local command = "dotnet build " .. filename .. " -c " .. options.BuildConfiguration
    if(Path.GetFileExtension(filename) ~= ".sln") then
        -- We cannot build a solution and specify a project architecture.
        command = command .. " -a " .. options.arch
    end
    command = command .. " -v q"

    -- The items to be displayed
    local items = {}
    local stringLines = {} -- Used to detect duplicates

    -- Detects if we have entries to our quickfix table
    local counter = 0

    -- Keep track the number of errors and warnings
    local errors = 0
    local warnings = 0


    Ui.OpenWindow(" Compiling " .. filename .. " ")
    Ui.AddLine("Command: ".. command)
    Ui.AddLine("")

    local function on_event(job_id, data, event)
        -- Make the lsp shutup.
        _ = job_id
        -- While the job is running , it may write to stdout and stderr
        -- Here we handle when we write to stdout
        if event == "stdout" or event == "stderr" then
            -- If we have data, then append them to the lines array
            if data then
                for _,theLine in ipairs(data) do
                    Ui.AddLine(theLine,SolutionConfig.display.removeCR)
                    if not stringLines[theLine] then
                        stringLines[theLine] = true
                        local r = Parser.ParseLine(theLine)
                        if r then
                            -- Add the line to the table
                            vim.list_extend(items,{r})
                            counter = counter + 1
                            if (r.type == 'E') then
                                errors = errors + 1
                            else
                                warnings = warnings + 1
                            end
                        end
                    end
                end
            end
        end

        -- When the job exits, populate the quick fix list
        if event == "exit" then
            --Ui.CloseWindow()
            -- TODO: Add user configurable option to only open if there are errors
            -- TODO: User configurable option to only display errors or warnings
            if (counter > 0) then
                vim.fn.setqflist(items)
                vim.cmd.doautocmd("QuickFixCmdPost")
                vim.cmd.copen()
                Ui.BringToFront()
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

    Ui.OpenWindow("Cleaning..")

    local function on_event(job_id, data, event)
        -- Make the lsp shutup.
        _ = job_id
        -- While the job is running , it may write to stdout and stderr
        -- Here we handle when we write to stdout
        if event == "stdout" or event == "stderr" then
            -- If we have data, then append them to the lines array
            if data then
                for _,theLine in ipairs(data) do
                    Ui.AddLine(theLine,SolutionConfig.display.removeCR)
                end
            end
        end

        -- When the job exits, populate the quick fix list
        if event == "exit" then
            --TODO Make this user configurable
            --Ui.CloseWindow()
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

    Ui.OpenWindow("Testing..")

    local function on_event(job_id, data, event)
        -- Make the lsp shutup.
        _ = job_id
        -- While the job is running , it may write to stdout and stderr
        -- Here we handle when we write to stdout
        if event == "stdout" or event == "stderr" then
            -- If we have data, then append them to the lines array
            if data then
                for _,theLine in ipairs(data) do
                    Ui.AddLine(theLine,SolutionConfig.display.removeCR)
                end
            end
        end

        -- When the job exits, populate the quick fix list
        if event == "exit" then
            --TODO Make this user configurable
            --Ui.CloseWindow()
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

solution.FunctionTest = function()
    local p = require("solution.SolutionParser")
    print("Hello")
    p.ParseSolution("C:/users/Admin/source/repos/AIStream/AIStream.sln")
end

return solution
