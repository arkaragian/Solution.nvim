-- The goal of this module is to
-- Detect and hold all the tests of the projects
-- Execute single test for debug porposes.
local TestManager = {}

local Path = require("solution.path")
local utils = require("solution.utils")

local TestList = {}

-- Holds the state of the "parser" as we list the tests with "dotnet test"
local TestListParsingState = "none"

-- The previous line that we parsed in "dotnet test"
local PreviousLine = nil


local win = require("solution.window")

-- Parses all the output of the "dotnet test --list-tests" command. Using
-- the PreviousLine and TestListParsingState as a state. Discard the job id.
-- We don't need it. This method is used as an event handler.
local function ReceiveTestListResults(_, data, event)
    if(event == "exit") then
        TestListParsingState = "none"
        PreviousLine = nil
        print(utils.Length(TestList) .. " Tests found.")
    end

    if(data) then
        -- The exit code will also be written in the standard output.
        if(type(data) == "number") then
            if(data ~= 0) then
                print("Could not retreive tests error code: " .. data)
            end
            return
        end

        -- Job event handlers may receive partial (incomplete) lines. For a given
        -- invocation of on_stdout/on_stderr, `data` is not guaranteed to end
        -- with a newline.
        -- Concat data to single line
        local line = ""
        for _,lineSegment in ipairs(data) do
            line = line .. lineSegment
        end

        if(TestListParsingState == "parsing") then
            if(line == "") then
                return
            end

            -- If our line starts with \r then that means that we have a
            -- remaining test tha was not parsed from the previous line.
            -- We need to find the last test that was not parsed from the
            -- previous line and prepend it to this line so that it will parsed
            -- normally.
            if(string.sub(line,1,1) =="\r" and PreviousLine ~= nil) then
                local lfIndex = 0
                local lfPrev  = 1
                repeat
                    lfIndex = string.find(line,"\r",lfIndex+1)
                    if(lfIndex == nil) then
                        local s = string.sub(PreviousLine,lfPrev,string.len(PreviousLine))
                        local testName = s:gsub("^%s+", ""):gsub("%s+$", "")
                        table.insert(TestList,testName)
                    else
                        lfPrev = lfIndex
                    end
                until(lfIndex == nil)
            end

            -- At this point we may receive multiple tests that are seperated
            -- by \r e.g <Space>TestName\r <space>TestName\r etc. this however
            -- was only tested in windows. In addition we may have lines that
            -- start with the \r character. We need to make sure that this also
            -- works on linux
            local lfIndex = 0
            local lfPrev  = 1
            repeat
                lfIndex = string.find(line,"\r",lfIndex+1)
                if(lfIndex ~= nil) then
                    local s = string.sub(line,lfPrev,lfIndex-1)
                    --Remove spaces. Copied from http://lua-users.org/wiki/StringTrim
                    local testName = s:gsub("^%s+", ""):gsub("%s+$", "")
                    -- This happens if the line that is processed starts with \r.
                    -- We have alrady hanled this.
                    if(testName ~= "") then
                        table.insert(TestList,testName)
                    end
                    lfPrev = lfIndex
                end
                PreviousLine = line
            until(lfIndex == nil)
            return
        end

        if(TestListParsingState == "none") then
            local start
            -- After this line the tests are listed.
            start, _= string.find(line,"The following Tests are available:")
            if(start ~= nil) then
                TestListParsingState = "parsing"
                return
            end
        end

    end
end

TestManager.GetTestUnderCursor = function()
    -- Principle of operation:
    -- 1 Get the tsnode under the cursor.
    -- 2 Go upstream until we find the method declaration node
    -- 3 Go downstream from the method declaration node until
    -- we find the function name. The node is: name: identifier
    -- that is child of the function_declaration node.
    local ts_utils = require("nvim-treesitter.ts_utils")
    local node = ts_utils.get_node_at_cursor(0)
    --
    -- The following query captures the function.
    --(method_declaration name:(identifier) @the-function) @capture

    local expr = node
    while expr do
        if expr:type() == 'method_declaration' then
            print("Found method declaration")
            break
        end
        expr = expr:parent()
    end

    -- TODO: Check that this method has a test attribute.

    if not expr then
        print("Found nothing!")
    else
        -- For each child
        for child, _ in expr:iter_children() do
            print(vim.inspect("Node type is ".. child:type()))
            if(child:type() == "identifier") then
                local s = vim.treesitter.get_node_text(child,0)
                print("Got: " ..s)
                return s
            end
        end
    end
end

-- Executes the "dotnet test --list-tests" command and parses the resulting
-- tests.
TestManager.GetTests = function(filename)
    local ext = Path.GetFileExtension(filename)
    if(ext ~= ".sln") then
        return nil
    end
    local command = "dotnet test " .. filename .. " --list-tests"
    print(command)

    local id = vim.fn.jobstart(command,{
        on_stderr = ReceiveTestListResults,
        on_stdout = ReceiveTestListResults,
        on_exit = ReceiveTestListResults,
    })
end

-- Executes a single test.
TestManager.ExecuteSingleTest = function(Project,TestName)
    -- TODO: Implement this function
    local command="dotnet test --filter Name~"..TestName .. " --logger=\"console;verbosity=detailed\""
    -- Make the LSP to shut up
    _ = Project
    _ = command
    print("Executing:".. command)

    local CompileOutputWindow = win.new(" Executing Test: " .. TestName .. " ")
    CompileOutputWindow.PaintWindow()
    CompileOutputWindow.AddLine("Command: ".. command)
    CompileOutputWindow.AddLine("")

    local function on_event(_, data, event)
        -- While the job is running , it may write to stdout and stderr
        -- Here we handle when we write to stdout
        if event == "stdout" or event == "stderr" then
            -- If we have data, then append them to the lines array
            if data then
                for _,theLine in ipairs(data) do
                    CompileOutputWindow.AddLine(theLine,SolutionConfig.Display.RemoveCR)
                end
            end
        end

        -- When the job exits, populate the quick fix list
        if event == "exit" then
            CompileOutputWindow.BringToFront()
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

TestManager.DebugTest = function(TestName)

    -- TODO: Implement this function
    local command="dotnet test --filter Name~"..TestName

    -- https://phelipetls.github.io/posts/async-make-in-nvim-with-lua/
    --local _ = vim.fn.jobstart(command,{
        --    on_stderr = on_event,
        --    on_stdout = on_event,
        --    on_exit = on_event,
        --    --stdout_buffered = true,
        --    --stderr_buffered = true,
        --})

        local dap = require("dap")
        require("dapui").open()
        dap.continue()
    end

return TestManager
