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

TestManager.ExecuteTest = function(TestName)
    -- TODO: Execute in new window
    local command="dotnet test --filter Name~"..TestName
end

return TestManager