local SolutionWriter = {}

local lineCounter = 0

--- Appends a newline character to the line string, writes it to the output
--and increments the global line counter
--@param line The string that needs to be written to the io
local function WriteLine(line)
    io.write(line .. "\n")
    lineCounter = lineCounter + 1
    --print("Linecounter is:" .. lineCounter)
end

--- Iterates through the entries table and writes them to the output file if
--their posision means that they should be written
local function WriteRawTextEntries(entries)
    -- entries is a table as follows:
    --entries = {
    --    { lineNumber, string}, 
    --    { lineNumber, string}, 
    --    { lineNumber, string}
    --}
    -- The _text containes tables with { lineNumbe, string}
    --
    if (entries == nil) then
        return
    end

    for key,entry in ipairs(entries) do
        -- Will the line that we are going to write have the same number as
        -- the one that is supposed to have???
        if (entry[1] == lineCounter+1) then
            WriteLine(entry[2])
        end
    end
end

local function WriteProject(project)
    local line = string.format("Project(\"{%s}\") = \"%s\", \"%s\", \"{%s}\"",project.TypeGUID,project.Name,project.RelPath,project.GUID)
    WriteLine(line)
    if (#project._text > 0) then
        -- The _text containes tables with { lineNumbe, string}
        for k,entry in ipairs(project._text) do
            if (entry[1] ~= lineCounter-1) then
                local s = string.format("Line couter %d does not match with the line number %d been written",lineCounter-1,entry[1])
            end
            WriteLine(entry[2])
        end
    end
    WriteLine("EndProject")
end

local function WriteSolutionConfigurationPlatforms(solution)
--	GlobalSection(SolutionConfigurationPlatforms) = preSolution
--		Debug|Any CPU = Debug|Any CPU
--		Release|Any CPU = Release|Any CPU
--		TestConfiguration|Any CPU = TestConfiguration|Any CPU
--	EndGlobalSection
    WriteLine("\tGlobalSection(SolutionConfigurationPlatforms) = preSolution")
    -- TODO: Find a way to do it in order to be reproducible
    for k,v in pairs(solution.SolutionConfigurations) do
        for k2,v2 in pairs(v) do
            local line = string.format("\t\t%s|%s = %s|%s",k,v2,k,v2)
            WriteLine(line)
        end
    end
    WriteLine("\tEndGlobalSection")
end

local function WriteProjectConfigurations(ProjectConfigurations)
    WriteLine("\tGlobalSection(ProjectConfigurationPlatforms) = postSolution")
    for k,v in ipairs(ProjectConfigurations) do
    --  {6185CC21-BE89-448A-B3C0-D1C27112E595}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
    --  {6185CC21-BE89-448A-B3C0-D1C27112E595}.Debug|Any CPU.Build.0 = Debug|Any CPU
        local line1 = string.format("\t\t{%s}.%s|%s.ActiveCfg = %s|%s",v.ProjectGUID,v.Configuration,v.Platform,v.Configuration,v.Platform)
        local line2 = string.format("\t\t{%s}.%s|%s.Build.0 = %s|%s",v.ProjectGUID,v.Configuration,v.Platform,v.Configuration,v.Platform)
        WriteLine(line1)
        WriteLine(line2)
    end
    WriteLine("\tEndGlobalSection")
end

SolutionWriter.WriteSolution = function(solution)
    local filename = solution.SolutionPath .. ".nvim"
    print("Writing Solution to:" .. filename)
    
    -- Think about the mode again
    local file = io.open(filename,"w+")
    io.output(file)

    lineCounter = 0

    WriteLine("")
    WriteLine("Microsoft Visual Studio Solution File, Format Version 12.00")
    WriteLine("# Visual Studio Version 17")
    WriteLine("VisualStudioVersion = " .. solution.VisualStudioVersion)
    WriteLine("MinimumVisualStudioVersion = " .. solution.MinimumVisualStudioVersion)
    -- In between each section that we are going to write. Make sure that we
    -- also output any lines that were collected
    WriteRawTextEntries(solution._text)
    for k,v in ipairs(solution.Projects) do
        WriteProject(v)
    end
    WriteRawTextEntries(solution._text)
    WriteSolutionConfigurationPlatforms(solution)
    WriteRawTextEntries(solution._text)
    WriteProjectConfigurations(solution.ProjectConfigurations)
    WriteRawTextEntries(solution._text)

    io.close(file)
end

return SolutionWriter
