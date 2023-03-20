-- A Class to manage a solution and perform operations to the solution

--See https://paulwatt526.github.io/wattageTileEngineDocs/luaOopPrimer.html
--See https://www.2n.pl/blog/how-to-write-neovim-plugins-in-lua
local win = require("solution.window")

local Parser = require("solution.parser")
local CacheManager = require("solution.CacheManager")

local SolutionManager = {}

-- A runtime configuration that defines the handling of the currently loaded
-- solution
local Current = {
    BuildConfiguration = nil,
    BuildPlatform = nil
}


-- The current in memory solution or project
LoadedSolution = nil

SolutionManager.Solution = nil

-- The output locations of the executales
SolutionManager.OutputLocations = nil


SolutionManager.SetBuildConfiguration = function(BuildConfiguration)
    Current.BuildConfiguration = BuildConfiguration
end

SolutionManager.SetBuildPlatform = function(BuildPlatform)
    Current.BuildPlatform= BuildPlatform 
end


--- Prompts the user to select the configuration that will be used for the project.
SolutionManager.SelectBuildConfiguration = function()
    if(LoadedSolution == nil) then
            return
    end

    local items = {
    }

    local hash = {
    }

    -- We may have the same configuration with mulitple platforms
    -- We only keep the unique values using the hash table but we also
    -- print them in order or declaration
    for _,v in ipairs(LoadedSolution.SolutionConfigurations) do
        if(not hash[v[1]]) then
            hash[v[1]] = true
        end
    end

    local SelectionHandler = function(item,_) -- Discard index
        if not item then
            return
        end
        Current.BuildConfiguration = item
    end

    local opts = {
        prompt = string.format("Select Build Configuration [%s]:",LoadedSolution.SolutionPath)
    }

    vim.ui.select(items,opts,SelectionHandler)
end


SolutionManager.SelectBuildPlatform = function()
    if(LoadedSolution == nil) then
        if(LoadedSolution == nil) then
            vim.notify("No solution found.",vim.log.levels.WARN, {title="Solution.nvim"})
            return
        end
    end

    local items = {
    }

    local hash = {
    }

    for _,v in ipairs(LoadedSolution.SolutionConfigurations) do
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
    end

    local opts = {
        prompt = string.format("Select Platform for [%s] Configuration [%s]:",LoadedSolution.SolutionPath,Current.BuildConfiguration)
    }
    vim.ui.select(items,opts,SelectionHandler)
end


SolutionManager.DisplayOutputs = function()

    if(SolutionManager.OutputLocations == nil) then
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
    for _,v in pairs(SolutionManager.OutputLocations) do
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

    SolutionManager.OutputLocations = nil


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
            SolutionManager.OutputLocations = CurrentOutputLocations
            --Store ouput locations to cache
            CacheManager.SetSolutionOutputs(SolutionManager.Solution.SolutionPath,CurrentOutputLocations)
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

return SolutionManager
