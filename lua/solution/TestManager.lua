-- The goal of this module is to
-- Detect and hold all the tests of the projects
-- Execute single test for debug porposes.
local TestManager = {}

local Path = require("solution.path")
local utils = require("solution.utils")

--- This is async populated
local TestList = {}

-- Holds the state of the "parser" as we list the tests with "dotnet test"
-- The states are two. None and parsing
local TestListParsingState = "none"

-- The previous line that we parsed in "dotnet test"
local PreviousLine = nil

--- Keeps the state of the TestManager
local State = {
    TestList = {},
    TestListParsingState = "none"
}


local win = require("solution.window")


--- The exit callback that is called when the dotnet test command finishes
-- @param jobid is discarted
-- @param data is discarted
-- @param event should always be exit
local function ReceiveTestListResultsExitCallback(_, _, event)
    if(event == "exit") then
        State.TestListParsingState = "none"
        PreviousLine = nil
        vim.notify("Test Detection Finished. ".. utils.Length(State.TestList) .. " Tests found." ,vim.log.levels.INFO,{title = "Solution.nvim"})
    end
end

--- Parses all the output of the "dotnet test --list-tests" command.
-- Uses the PreviousLine and TestListParsingState as a state. Discard the job id.
-- We don't need it. This method is used as an event handler.
-- @param id The job id. Is discarted.
-- @param data The data contained in the callback
-- @param event The event type either "stdout" "stderr" or "exit"
-- @param picker_update_callback A callback that updates the test results back to telescope
-- @return a string value
local function ReceiveTestListResultsCallback(_, data, _, update_picker)
    -- Just return if we have no data
    if(data == nil) then
        return
    end

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

    -- Tha value of this is reset in each execution
    local line = ""

    print("Line variable before concat \"" .. line .."\"");

    -- Concat data to single line
    for _,lineSegment in ipairs(data) do
        print("Adding: \"" .. lineSegment .. "\"");
        line = line .. lineSegment
    end

    if(State.TestListParsingState == "none") then
        --- The start location that string.find returns for the pattern
        local start
        -- dotnet test --list-tests gives out the following file before
        -- outputing the tests: "The following Tests are available:"
        -- If we find this line then we can commence the parsing.
        start, _= string.find(line,"The following Tests are available:")

        -- We have found the magic string. What comes next are test names
        -- change our state.
        if(start ~= nil) then
            State.TestListParsingState = "parsing"
        end
        return
    end

    if(State.TestListParsingState == "parsing") then
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
                    table.insert(State.TestList,testName)
                    --print("Inserting Test:" .. testName)
                    if update_picker then
                        update_picker(testName)
                    end
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
                    table.insert(State.TestList,testName)
                    -- print("Inserting Test:" .. testName)
                    if update_picker then
                        update_picker(testName)
                    end
                end
                lfPrev = lfIndex
            end
            PreviousLine = line
        until(lfIndex == nil)
        return
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

TestManager.GetTestList = function()
    return State.TestList
end

--- Executes the "dotnet test --list-tests" command and parses the resulting tests.
TestManager.GetTests = function(solutionfile, update_picker)
    if(solutionfile == nil) then
        return nil
    end

    local ext = Path.GetFileExtension(solutionfile)
    if(ext ~= ".sln") then
        return nil
    end

    State.TestList = {}
    local command = "dotnet test " .. solutionfile .. " --list-tests"
    print(command)

    local id = vim.fn.jobstart(command,{
        -- on_stderr = ReceiveTestListResultsCallback,
        -- on_stdout = ReceiveTestListResultsCallback,
        on_stderr = function(_, data, event)
            ReceiveTestListResultsCallback(_, data, event, update_picker)
        end,
        on_stdout = function(_, data, event)
            ReceiveTestListResultsCallback(_, data, event, update_picker)
        end,
        on_exit = ReceiveTestListResultsExitCallback,
    })
    if(id == 0) then
        vim.notify("Invalid arguments",vim.log.levels.ERROR,{title = "Solution.nvim Test Parsing"})
    end

    if(id == -1) then
        vim.notify("Command or Shell is not Executable",vim.log.levels.ERROR,{title = "Solution.nvim Test Parsing"})
    end

-- Returns |job-id| on success, 0 on invalid arguments (or job
-- table is full), -1 if {cmd}[0] or 'shell' is not executable.
-- The returned job-id is a valid |channel-id| representing the
-- job's stdio streams. Use |chansend()| (or |rpcnotify()| and
-- |rpcrequest()| if "rpc" was enabled) to send data to stdin and
-- |chanclose()| to close the streams without stopping the job.
    return TestList
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
