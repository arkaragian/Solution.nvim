-- A Class to manage a solution and perform operations to the solution

--See https://paulwatt526.github.io/wattageTileEngineDocs/luaOopPrimer.html
--See https://www.2n.pl/blog/how-to-write-neovim-plugins-in-lua
local win = require("solution.window")
local osutils = require("solution.osutils")
local path = require("solution.path")

local Parser = require("solution.parser")
local CacheManager = require("solution.CacheManager")

local SolutionManager = {}

-- A runtime configuration that defines the handling of the currently loaded
-- solution
local Current = {
    BuildConfiguration = nil,
    BuildPlatform = nil,
    StartupProject = nil,
    StartupLaunchProfile = nil,
    OutputLocations = nil
}


-- The current in memory solution or project
SolutionManager.Solution = nil

SolutionManager.SetBuildConfiguration = function(BuildConfiguration)
    Current.BuildConfiguration = BuildConfiguration
end

SolutionManager.SetBuildPlatform = function(BuildPlatform)
    Current.BuildPlatform= BuildPlatform
end

SolutionManager.SetStartupProject = function(ProjectName)
    Current.StartupProject = ProjectName
end

SolutionManager.HandleCacheData = function(CacheData)
    for k,_ in pairs(CacheData) do
        Current[k] = CacheData[k]
    end
end


--- Prompts the user to select the configuration that will be used for the project.
SolutionManager.SelectBuildConfiguration = function()
    if(SolutionManager.Solution == nil) then
            return
    end

    local items = {
    }

    local hash = {
    }

    -- We may have the same configuration with mulitple platforms
    -- We only keep the unique values using the hash table but we also
    -- print them in order or declaration
    for _,v in ipairs(SolutionManager.Solution.SolutionConfigurations) do
        if(not hash[v[1]]) then
            hash[v[1]] = true
            table.insert(items,v[1])
        end
    end

    local SelectionHandler = function(item,_) -- Discard index
        if not item then
            return
        end
        Current.BuildConfiguration = item
        --When we change the build configuration and build platform the outouts are invalid
        Current.OutputLocations = nil
        CacheManager.WriteCacheData(SolutionManager.Solution.SolutionPath,Current)
    end

    local opts = {
        prompt = string.format("Select Build Configuration [%s]:",SolutionManager.Solution.SolutionPath)
    }

    vim.ui.select(items,opts,SelectionHandler)
end


SolutionManager.SelectBuildPlatform = function()
    if(SolutionManager.Solution == nil) then
        if(SolutionManager.Solution == nil) then
            vim.notify("No solution found.",vim.log.levels.WARN, {title="Solution.nvim"})
            return
        end
    end

    local items = {
    }

    local hash = {
    }

    for _,v in ipairs(SolutionManager.Solution.SolutionConfigurations) do
        -- We may have the same configuration with mulitple platforms
        -- We only keep the unique values using the hash table but we
        -- also print them in order or declaration
        if(v[1] == Current.BuildConfiguration) then
            if(not hash[v[2]]) then
                hash[v[2]] = true
                table.insert(items,v[2])
            end
        end
    end


    local SelectionHandler = function(item,_) -- Discard index
        if not item then
            return
        end
        Current.BuildPlatform = item
        Current.OutputLocations = nil
        CacheManager.WriteCacheData(SolutionManager.Solution.SolutionPath,Current)
    end

    local opts = {
        prompt = string.format("Select Platform for [%s] Configuration [%s]:",SolutionManager.Solution.SolutionPath,Current.BuildConfiguration)
    }
    vim.ui.select(items,opts,SelectionHandler)
end

SolutionManager.SelectStartupProject = function()
    if(SolutionManager.Solution == nil) then
            return
    end

    local items = {
    }

    -- Projects are passed in order
    for _,v in ipairs(SolutionManager.Solution.Projects) do
        table.insert(items,v.Name)
    end

    local SelectionHandler = function(item,_) -- Discard index
        if not item then
            return
        end
        Current.StartupProject= item
        CacheManager.WriteCacheData(SolutionManager.Solution.SolutionPath,Current)
    end

    local opts = {
        prompt = string.format("Select Startup Project [%s]:",SolutionManager.Solution.SolutionPath)
    }

    vim.ui.select(items,opts,SelectionHandler)
end

SolutionManager.DisplayExecutionScheme = function()

    if(Current.OutputLocations == nil) then
        vim.notify("No outputs loaded, nothing to display",vim.log.levels.WARN,{title = "Solution.nvim"})
        return
    end

    local window
    if(SolutionManager.Solution~= nil) then
        window = win.new(" Current Execution Scheme ")
    end
    window.PaintWindow()
    window.SetFiletype("lua")

    local str = vim.inspect(Current)
    --TODO: This is the same code that displays a solution. Maybe abstract this away

    local i = 0
    local prev = 0
    while(true) do
        i,_ = string.find(str,"\n",i+1)
        if(i == nil) then
            break
        end
        local line = string.sub(str,prev+1,i-1)
        window.AddLine(line)
        prev = i
    end
end


SolutionManager.DisplayOutputs = function()

    if(Current.OutputLocations == nil) then
        vim.notify("No outputs loaded, nothing to display",vim.log.levels.WARN,{title = "Solution.nvim"})
        return
    end

    local window
    if(SolutionManager.Solution~= nil) then
        window = win.new(" " .. SolutionManager.Solution.SolutionPath .. " Outputs ")
    end
    window.PaintWindow()
    --window.SetFiletype("lua")

    --print(str)
    for _,v in pairs(Current.OutputLocations) do
        window.AddLine(string.format("%s -> %s",v.Project,v.OutputLocation))
    end
end

SolutionManager.CompileSolution = function()
    -- dotnet build [<PROJECT | SOLUTION>...] [options]
    --local command = "dotnet build " .. filename .. " -c " .. options.BuildConfiguration
    if(SolutionManager.Solution == nil) then
        vim.notify("No solution loaded. Nothing to compile",vim.log.levels.ERROR, {title="Solution.nvim"})
        return
    end
    local command = "dotnet build " .. SolutionManager.Solution.SolutionPath .. " -c " .. Current.BuildConfiguration


    -- The items to be Displayed in the quickfix list
    local items = {}
    -- Reset the quickfix list
    vim.fn.setqflist(items)
    local stringLines = {} -- Used to detect duplicates

    -- Detects if we have entries to our quickfix table
    local counter = 0

    -- Keep track the number of errors and warnings
    local errors = 0
    local warnings = 0

    Current.OutputLocations = nil


    local CompileOutputWindow = win.new(" Compiling " .. SolutionManager.Solution.SolutionPath .. " ")
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
            --SolutionManager.OutputLocations = CurrentOutputLocations
            Current.OutputLocations = CurrentOutputLocations
            CacheManager.WriteCacheData(SolutionManager.Solution.SolutionPath,Current)
        end
    end

    -- https://phelipetls.github.io/posts/async-make-in-nvim-with-lua/
    local _ = vim.fn.jobstart(command,{
        on_stderr = on_event,
        on_stdout = on_event,
        on_exit = on_event,
        --stdout_buffered = truee
        --stderr_buffered = true,
    })

    --TODO: Store ouptut locations to cache
end


SolutionManager.Launch = function()
    -- In order to execute a project we need the following:
    -- 1 The launch profile that supplies the command line arguments
    -- 2 
    local command = nil

    -- TODO: Currently we only have windows commands. Also take care linux commands.
    if(Current.StartupProject == nil) then
        command = string.format("!start cmd /K dotnet run -c %s",Current.BuildConfiguration)
        -- command = string.format("!start dotnet run -c %s",Current.BuildConfiguration)
    else

        --From the startup project locate the project path
        print("Locating path for startup project: "..Current.StartupProject)
        local thePath = nil
        for _,v in ipairs(SolutionManager.Solution.Projects) do
            if(Current.StartupProject== v.Name) then
                thePath = path.GetParrentDirectory(SolutionManager.Solution.SolutionPath,osutils.seperator()) .. osutils.seperator() .. v.RelPath
                break
            end
        end
        if(Current.StartupLaunchProfile== nil) then
            command = string.format("!start cmd /K dotnet run --project %s -c %s",thePath,Current.BuildConfiguration)
        else
            command = string.format("!start cmd /K dotnet run --project %s --launch-profile %s -c %s",thePath,Current.StartupLaunchProfile,Current.BuildConfiguration)
        end
    end
    -- TODO: Try to open in new window
    vim.cmd(command)
    --local _ = vim.fn.jobstart(command,{
        --on_stderr = on_event,
        --on_stdout = on_event,
        --on_exit = on_event,
        --stdout_buffered = true,
        --stderr_buffered = true,
    --})
end

SolutionManager.GetCSProgram= function()
    local csProgram = nil
    if(Current.OutputLocations == nil) then
        return csProgram
    elseif(#Current.OutputLocations> 1) then
        -- We have more than one ouptut location. Ask the user to select one.
        local opts = {
            prompt = "Select Output to Debug:"
        }

        local Projects = {}
        local maxLeftLength = 1
        local maxRightLength = 1

        -- Iterate once through the results to find the results dimensions.
        -- We want to make the results easier to select so we need to format
        -- them correctly
        for _,v in ipairs(Current.OutputLocations) do
            --maxLeftLength  = math.max(maxLeftLength,string.len(v[1]))
            --maxRightLength = math.max(maxRightLength,string.len(v[2]))

            maxLeftLength  = math.max(maxLeftLength,string.len(v.Project))
            maxRightLength = math.max(maxRightLength,string.len(v.OutputLocation))
        end

        -- Generate the formated results
        for i,v in ipairs(Current.OutputLocations) do
            -- Max field length is 99. Don't know why
            local formatProvider
            -- The right length will always be bigger than the leeft lenght
            -- and almost always bigger than 99 characters.
            if(maxLeftLength > 99) then
                formatProvider = "%s ----> %s"
            else
                formatProvider = "%-"..maxLeftLength.."s ----> %s"
            end
            local s2 = string.format(formatProvider,v.Project,v.OutputLocation)
            Projects[i] = s2
        end

        -- Present to the user for selection
        vim.ui.select(Projects,opts,function(item,index)
            if not item then
                csProgram =Current.OutputLocations[1].OutputLocation
            else
                csProgram = Current.OutputLocations[index].OutputLocation
            end
        end)
    else
        --return vim.fn.input('Path to dll: ', locs[1][2], 'file') -- Nothing selected set the first input
        csProgram = Current.OutputLocations[1].OutputLocation
    end

    return csProgram
end

return SolutionManager
