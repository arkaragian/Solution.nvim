-- Author: Aris Karagiannidis
-- e-mail: arkaragian@gmail.com
--
-- The format of the solution file is actually is not throrougly documented.
-- At least I have not found any good source of documentation.
--
-- One good way to make sense of that is happening is to see what MSBuild is
-- actually doing. Fortunatelly microsoft has made this open source. The repo
-- is located : https://github.com/dotnet/msbuild
-- 
-- The file that we care about is:
-- https://github.com/dotnet/msbuild/blob/main/src/Build/Construction/Solution/SolutionFile.cs
-- 
-- Now even with that we are not sure that we need to support all the features
-- of V***** S***** since some of them are quite internal to the IDE. Only time
-- will tell.

local SolutionParser = {}

-- This is the project types that are defined by Microsoft.
-- Some are quite historical like the Zune! (https://www.youtube.com/watch?v=POIXq7999aM)
-- See https://www.codeproject.com/Reference/720512/List-of-Visual-Studio-Project-Type-GUIDs
-- May be updated in the future if needed.
local ProjectTypes = {
    ["06A35CCD-C46D-44D5-987B-CF40FF872267"]="Deployment Merge Module",
    ["14822709-B5A1-4724-98CA-57A101D1B079"]="Workflow (C#)",
    ["20D4826A-C6FA-45DB-90F4-C717570B9F32"]="Legacy (2003) Smart Device (C#)",
    ["2150E333-8FDC-42A3-9474-1A3956D46DE8"]="Solution Folder",
    ["2DF5C3F4-5A5F-47a9-8E94-23B4456F55E2"]="XNA (XBox)",
    ["32F31D43-81CC-4C15-9DE6-3FC5453562B6"]="Workflow Foundation",
    ["349C5851-65DF-11DA-9384-00065B846F21"]="Web Application (incl. MVC 5)",
    ["3AC096D0-A1C2-E12C-1390-A8335801FDAB"]="Test",
    ["3D9AD99F-2412-4246-B90B-4EAA41C64699"]="Windows Communication Foundation (WCF)",
    ["3EA9E505-35AC-4774-B492-AD1749C4943A"]="Deployment Cab",
    ["4D628B5B-2FBC-4AA6-8C16-197242AEB884"]="Smart Device (C#)",
    ["4F174C21-8C12-11D0-8340-0000F80270F8"]="Database (other project types)",
    ["54435603-DBB4-11D2-8724-00A0C9A8B90C"]="Visual Studio 2015 Installer Project Extension",
    ["593B0543-81F6-4436-BA1E-4747859CAAE2"]="SharePoint (C#)",
    ["603C0E0B-DB56-11DC-BE95-000D561079B0"]="ASP.NET MVC 1.0",
    ["60DC8134-EBA5-43B8-BCC9-BB4BC16C2548"]="Windows Presentation Foundation (WPF)",
    ["68B1623D-7FB9-47D8-8664-7ECEA3297D4F"]="Smart Device (VB.NET)",
    ["66A26720-8FB5-11D2-AA7E-00C04F688DDE"]="Project Folders",
    ["6BC8ED88-2882-458C-8E55-DFD12B67127B"]="MonoTouch",
    ["6D335F3A-9D43-41b4-9D22-F6F17C4BE596"]="XNA (Windows)",
    ["76F1466A-8B6D-4E39-A767-685A06062A39"]="Windows Phone 8/8.1 Blank/Hub/Webview App",
    ["786C830F-07A1-408B-BD7F-6EE04809D6DB"]="Portable Class Library",
    ["8BB2217D-0F2D-49D1-97BC-3654ED321F3B"]="ASP.NET 5",
    ["8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942"]="C++",
    ["978C614F-708E-4E1A-B201-565925725DBA"]="Deployment Setup",
    ["9A19103F-16F7-4668-BE54-9A1E7A4F7556"]=".NET Core",
    ["A07B5EB6-E848-4116-A8D0-A826331D98C6"]="Service Fabric Application (.sfproj)",
    ["A1591282-1198-4647-A2B1-27E5FF5F6F3B"]="Silverlight",
    ["A5A43C5B-DE2A-4C0C-9213-0A381AF9435A"]="Universal Windows Class Library",
    ["A860303F-1F3F-4691-B57E-529FC101A107"]="Visual Studio Tools for Applications (VSTA)",
    ["A9ACE9BB-CECE-4E62-9AA4-C7E7C5BD2124"]="Database",
    ["AB322303-2255-48EF-A496-5904EB18DA55"]="Deployment Smart Device Cab",
    ["B69E3092-B931-443C-ABE7-7E7B65F2A37F"]="Micro Framework",
    ["BAA0C2D2-18E2-41B9-852F-F413020CAA33"]="Visual Studio Tools for Office (VSTO)",
    ["BC8A1FFA-BEE3-4634-8014-F334798102B3"]="Windows Store Apps (Metro Apps)",
    ["BF6F8E12-879D-49E7-ADF0-5503146B24B8"]="C# in Dynamics 2012 AX AOT",
    ["C089C8C0-30E0-4E22-80C0-CE093F111A43"]="Windows Phone 8/8.1 App (C#)",
    ["C252FEB5-A946-4202-B1D4-9916A0590387"]="Visual Database Tools",
    ["CB4CE8C6-1BDB-4DC7-A4D3-65A1999772F8"]="Legacy (2003) Smart Device (VB.NET)",
    ["D399B71A-8929-442a-A9AC-8BEC78BB2433"]="XNA (Zune)",
    ["D59BE175-2ED0-4C54-BE3D-CDAA9F3214C8"]="Workflow (VB.NET)",
    ["DB03555F-0C8B-43BE-9FF9-57896B3C5E56"]="Windows Phone 8/8.1 App (VB.NET)",
    ["E24C65DC-7377-472B-9ABA-BC803B73C61A"]="Web Site",
    ["E3E379DF-F4C6-4180-9B81-6769533ABE47"]="ASP.NET MVC 4.0",
    ["E53F8FEA-EAE0-44A6-8774-FFD645390401"]="ASP.NET MVC 3.0",
    ["E6FDF86B-F3D1-11D4-8576-0002A516ECE8"]="J#",
    ["EC05E597-79D4-47f3-ADA0-324C4F7C7484"]="SharePoint (VB.NET)",
    ["EFBA0AD7-5A72-4C68-AF49-83D382785DCF"]="Xamarin.Android / Mono for Android",
    ["F135691A-BF7E-435D-8960-F99683D2D49C"]="Distributed System",
    ["F184B08F-C81C-45F6-A57F-5ABD9991F28F"]="VB.NET",
    ["F2A71F9B-5D33-465A-A702-920D77279786"]="F#",
    ["F5B4F3BC-B597-4E2B-B552-EF5D8A32436F"]="MonoTouch Binding",
    ["F85E285D-A4E0-4152-9332-AB1D724D3325"]="ASP.NET MVC 2.0",
    ["F8810EC1-6754-47FC-A15F-DFABD2E3FA90"]="SharePoint Workflow",
    ["FAE04EC0-301F-11D3-BF4B-00C04F79EFBC"]="C#",
}

local path = require("solution.path")

--- Parses a .sln project line that contains the project information such as
-- type, name, relative path and it's GUID.
-- @param line The line that contains the information
local function ParseProjectLine(line)
    --  What we expect to parse is the following line
    --  Project("{Project type GUID}") = "Project name", "Relative path to project file", "{Project GUID}"
    --  The logic is to find the delimiting characters or patterns and then get the substrings between
    --  the found positions..

    local patternStart, patternEnd = string.find(line, "Project")

    if(patternStart == nil or patternEnd == nil) then
        --We have no match. There is nothing to do.
        return nil
    end

    -- If the line seems to be valid.
    if(patternStart ~= nil and patternEnd ~= nil) then
        local project = {}

        -- Find the GUIDs. The first one denotes the project type. The second
        -- is the project identifier.
        local counter = 1
        for guid in string.gmatch(line, "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x") do
            if(counter == 1) then
                project.TypeGUID = guid
                project.Type = ProjectTypes[guid]
            else
                project.GUID = guid
            end
            counter = counter + 1
        end

        local equalLocation,_ = string.find(line,"=")
        -- Find the first quote after the equal sign
        patternStart,_= string.find(line,"\"",equalLocation+1)
        -- Find the second Quote quote
        _,patternEnd = string.find(line,"\"",patternStart+1)

        -- Name is the string between the quotes.
        local ProjectName = string.sub(line,patternStart+1,patternEnd-1)

        local commaLocation,_ = string.find(line,",",patternEnd)

        -- Again find the next pair of quotes
        patternStart,_ = string.find(line,"\"",commaLocation+1)
        _,patternEnd = string.find(line,"\"",patternStart+1)
        local ProjectRelativePath = string.sub(line,patternStart+1,patternEnd-1)

        -- Set the relevant fields
        project.Name = ProjectName
        project.RelPath = ProjectRelativePath
        project._text = {}

        return project
    else
        return nil
    end
end

--- Parse a project and it's subtree in with the given start position
-- @param fileHandle The file hanle of the .sln file. Must be already opened.
-- @param startPosition The position within the file where the project definition starts.
local function ParseProject(fileHandle,startPosition,lineCounter)
    --  What we need to parse is the following.
    --  Project("{Project type GUID}") = "Project name", "Relative path to project file", "{Project GUID}"
    --      ProjectSection(ProjectDependencies) = postProject
    --          {Parent project unique name} = {Parent project unique name}
    --          ...
    --      EndProjectSection
    --  EndProject
    --
    -- Rewind the open file to the start position
    --

    fileHandle:seek("set",startPosition)
    local result = {
        project = nil,
        position = startPosition,
        line = lineCounter - 1 -- We have rewinded thus we just remove a line this will be overwritten down the line
    }
    local line = fileHandle:read()
    -- No need to add to the line counter since we are re-reading the line that
    -- we have already encountered
    if(line == nil) then
        return result
    end
    --lineCounter = lineCounter + 1

    -- The parsing of the first line is quite big. Delegate to a function of
    -- its own. This function also creates the project structre which is returned
    -- here and we can continue working from here.
    local project = ParseProjectLine(line)
    if(project == nil) then
        print("Error could not parse project!")
        result.position = fileHandle:seek()
        return result
    end

    local utils = require("solution.utils")
    local textIndex = 1
    -- Start reading lines
    while(true) do
        line = fileHandle:read()
        -- We have reached the end of the file. But not the normal ending of
        -- the project.
        if(line == nil) then
            result.position = fileHandle:seek()
            return result
        end
        lineCounter = lineCounter + 1

        -- Bellow are multiple cases. We don't handle them for the momment.
        -- Just keep them for future implementations if needed in the future.
        if(line == "EndProject") then
            -- This is a normal ending for the project. Break the loop in order
            -- to return
            break
        elseif (utils.StringStartsWith(line,"ProjectSection(ProjectDependencies)")) then
            -- We have a ProjectDependencies section.  Each subsequent line should identify
            -- a dependency. For now we don't need to parse those. I am unsure if the data here
            -- is of value to the plugin
            project._text[textIndex] = {lineCounter, line}
            textIndex = textIndex + 1
            goto continue
        elseif (utils.StringStartsWith(line,"ProjectSection(WebsiteProperties)")) then
            -- We have a WebsiteProperties section.  This section is present only in Venus
            -- projects, and contains properties that are needed in order to call the 
            -- AspNetCompiler task. However I am not sure on how those properties
            -- will be used in our plugin. For now we don't need to parse those.
            -- I am unsure if the data here is of value to the plugin
            project._text[textIndex] = {lineCounter, line}
            textIndex = textIndex + 1
            goto continue
        elseif (utils.StringStartsWith(line,"Project(")) then
            -- Another Project spotted instead of EndProject for the current
            -- one - solution file is malformed We don't support this. Print
            -- an error for the user.
            print("Detected nested project definitions. The solution file is malformed.")
        else
            project._text[textIndex] = {lineCounter, line}
            textIndex = textIndex + 1
        end
        ::continue::
    end
    result.project = project
    result.position = fileHandle:seek()
    result.line = lineCounter
    return result
end

--- Generate the projects configurations table based on the available projects,
-- the available solution configurations and the raw parsed configuration strings.
-- @param projects The list of projects that the solution contains.
-- @param solConfigs The list of solution configurations.
-- @param rawConfigurations The list of raw project configuration strings.
local function ProcessRawProjectConfigurations(projects,solConfigs,rawConfigurations)
    -- Instead of parsing the data line by line, we parse it project by project,
    -- constructing the  entry name ("{A6F99D27-47B9-4EA4-BFC9-25157CBDC281}.Release|Any CPU.ActiveCfg")
    -- and retrieving its value from the raw data. The reason for this is that
    -- the IDE does it this way, and as the result the '.' character is allowed
    -- in configuration names although it technically separates different parts
    -- of the entry name string. This could lead to ambiguous results if we tried
    -- to parse the entry name instead of constructing it and looking it up.
    -- Although it's pretty unlikely that this would ever be a problem, it's
    -- safer to do it the same way VS IDE does it.

    local ProjectConfigurations = {
    }
    for _,project in ipairs(projects) do
        for _,v in pairs(solConfigs) do
            local configuration = v[1]
            local platformValue = v[2]
            --for _, platformValue in pairs(solConf) do
                -- The "ActiveCfg" entry defines the active project configuration in the given solution configuration
                -- This entry must be present for every possible solution configuration/project combination.
                local fullConfig = configuration .."|".. platformValue
                local entryNameActiveConfig = string.format("{%s}.%s.ActiveCfg",project["GUID"], fullConfig);
                -- The "Build.0" entry tells us whether to build the project configuration in the given solution configuration.
                -- Technically, it specifies a configuration name of its own which seems to be a remnant of an initial, 
                -- more flexible design of solution configurations (as well as the '.0' suffix - no higher values are ever used). 
                -- The configuration name is not used, and the whole entry means "build the project configuration" 
                -- if it's present in the solution file, and "don't build" if it's not.
                -- TODO: See how to use this. Maybe have additional field that indicates if the project will be built?
                -- local entryNameBuild = string.format("{%s}.%s.Build.0",project["GUID"], fullConfig);
                --print(entryNameBuild)
                if rawConfigurations[entryNameActiveConfig] then
                    local pConfig = rawConfigurations[entryNameActiveConfig]
                    local i,_ = string.find(pConfig,"|")
                    local projectConfigration = string.sub(pConfig,1,i-1)
                    local projectPlatform = string.sub(pConfig,i+1,string.len(pConfig))
                    --print("Adding configuration")
                    local projectConfiguration = {
                        ProjectName = project["Name"],
                        ProjectGUID = project["GUID"],
                        SolutionConfiguration = configuration,
                        SolutionPlatform = platformValue,
                        ProjectConfiguration = projectConfigration,
                        ProjectPlatform = projectPlatform,
                    }
                    table.insert(ProjectConfigurations,projectConfiguration)
                end
            --end
        end
    end
    return ProjectConfigurations
end

--- Parse the nested projects of a project
-- @param fileHandle The file hanle of the .sln file. Must be already opened.
-- @param startPosition The position within the file where the nester projects starts.
local function ParseNestedProjects(fileHandle,startPosition)
    --  What we need to parse is the following.
    --  Project("{Project type GUID}") = "Project name", "Relative path to project file", "{Project GUID}"
    --      ProjectSection(ProjectDependencies) = postProject
    --          {Parent project unique name} = {Parent project unique name}
    --          ...
    --      EndProjectSection
    --  EndProject
    fileHandle:seek("set",startPosition)
    local utils = require("solution.utils")

    local result = {}
    repeat
        local line = fileHandle:read()
        if(line == nil) then
            break
        end

        if(line == nil or line == "EndGlobalSection") then
            -- This is a normal ending for the project get our current position
            -- and return it to the calling function along with our project.
            break
        elseif (utils.StringIsNullOrWhiteSpace(line) or string.sub(line,1,1) == "#") then
            -- Coninue here, but lua has no such statement. So we just do nothing.
        else
        end
    until(true)

    return result
end

--- Parse the solution configurations
-- @param fileHandle The file hanle of the .sln file. Must be already opened.
-- @param startPosition The position within the file where the configurations start
local function ParseSolutionConfigurations(fileHandle,startPosition, lineCounter)
    -- GlobalSection(SolutionConfigurationPlatforms) = preSolution
    --     Debug|Any CPU = Debug|Any CPU
    --     Release|Any CPU = Release|Any CPU
    -- EndGlobalSection
    fileHandle:seek("set",startPosition)
    local utils = require("solution.utils")

    local result = {
        configurations = nil,
        position = startPosition,
        line = lineCounter - 1 -- We have rewinded thus we just remove a line this will be overwritten down the line
    }

    local SolutionConfigurations = {
    }
    lineCounter = lineCounter -1

    local configurationIndex = 1
    repeat
        local line = fileHandle:read()

        if(line == nil) then
            break
        end

        lineCounter = lineCounter + 1

        if(utils.StringTrimWhiteSpace(line) == "EndGlobalSection") then
            -- This is a normal ending for the project get our current position
            -- and return it to the calling function along with our project.
            --
            -- We break just like before but now we have counted the line that we
            -- parsed
            break
        elseif (utils.StringIsNullOrWhiteSpace(line) or string.sub(line,1,1) == "#") then
            -- Coninue here, but lua has no such statement. So we just do nothing.
            goto continue
        else
            -- If we are here we need to parse. To do that locate the = character
            local i,_ = string.find(line,"=")
            if(i == nil) then
                goto continue
            end
            -- There should be only one = character. If we find another one then raise
            -- an error.
            local a,_ = string.find(line,"=",i+1)
            if(a ~= nil) then
                goto continue
            end

            local beforeEqual = utils.StringTrimWhiteSpace(string.sub(line,1,i-1))
            local afterEqual = utils.StringTrimWhiteSpace(string.sub(line,i+1,string.len(line)))
            if(beforeEqual ~= afterEqual) then
                -- Two halves are not equal. ignoring.
                goto continue
            end

            i,_ = string.find(beforeEqual,"|")
            local config = string.sub(beforeEqual,1,i-1)
            local plat   = string.sub(beforeEqual,i+1,string.len(beforeEqual))
            --TODO: Maybe refactor this part and keep the order of addition
            -- This is important for solution writer
            SolutionConfigurations[configurationIndex] = { config, plat }
            configurationIndex = configurationIndex + 1
            --if not SolutionConfigurations[config] then
            --    SolutionConfigurations[config] = {}
            --end
            --table.insert(SolutionConfigurations[config],plat)
        end
        ::continue::
    until(false)
    result.configurations = SolutionConfigurations
    result.position = fileHandle:seek()
    result.line = lineCounter
    return result
end

--- Parse the project configurations
-- @param fileHandle The file hanle of the .sln file. Must be already opened.
-- @param startPosition The position within the file where the project configurations start
local function ParseProjectConfigurations(fileHandle,startPosition,lineCounter)
    -- GlobalSection(ProjectConfigurationPlatforms) = postSolution
    --  {6185CC21-BE89-448A-B3C0-D1C27112E595}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
    --  {6185CC21-BE89-448A-B3C0-D1C27112E595}.Debug|Any CPU.Build.0 = Debug|Any CPU
    --  {6185CC21-BE89-448A-B3C0-D1C27112E595}.Debug|Mixed Platforms.ActiveCfg = Release|Any CPU
    --  {6185CC21-BE89-448A-B3C0-D1C27112E595}.Debug|Mixed Platforms.Build.0 = Release|Any CPU
    --  {6185CC21-BE89-448A-B3C0-D1C27112E595}.Debug|Win32.ActiveCfg = Debug|Any CPU
    --  {A6F99D27-47B9-4EA4-BFC9-25157CBDC281}.Release|Any CPU.ActiveCfg = Release|Win32
    --  {A6F99D27-47B9-4EA4-BFC9-25157CBDC281}.Release|Mixed Platforms.ActiveCfg = Release|Win32
    --  {A6F99D27-47B9-4EA4-BFC9-25157CBDC281}.Release|Mixed Platforms.Build.0 = Release|Win32
    --  {A6F99D27-47B9-4EA4-BFC9-25157CBDC281}.Release|Win32.ActiveCfg = Release|Win32
    --  {A6F99D27-47B9-4EA4-BFC9-25157CBDC281}.Release|Win32.Build.0 = Release|Win32
    -- EndGlobalSection
    fileHandle:seek("set",startPosition)
    local utils = require("solution.utils")

    local result = {
        projectConfigurations = nil,
        position = startPosition,
        line = lineCounter - 1 -- We have rewinded thus we just remove a line this will be overwritten down the line
    }

    local RawProjectConfigurations = {
    }

    lineCounter = lineCounter -1
    repeat
        local line = fileHandle:read()
        --if(line ~= nil) then
        --    print("Line parsed:"..line)
        --end

        if(line == nil) then
            break
        end

        lineCounter = lineCounter + 1

        if(utils.StringTrimWhiteSpace(line) == "EndGlobalSection") then
            -- This is a normal ending for the project get our current position
            -- and return it to the calling function along with our project.
            break
        elseif (utils.StringIsNullOrWhiteSpace(line) or string.sub(line,1,1) == "#") then
            -- Coninue here, but lua has no such statement. So we just do nothing.
            goto continue
        else

            -- Find | character. It is a seperator. If we don't find it ignore the line.
            local i,_ = string.find(line,"|")
            if(i == nil) then
                goto continue
            end

            -- If we are here we need to parse. To do that locate the = character
            i,_ = string.find(line,"=")
            if(i == nil) then
                goto continue
            end
            -- There should be only one = character. If we find another one then raise
            -- an error.
            local a,_ = string.find(line,"=",i+1)
            if(a ~= nil) then
                goto continue
            end

            local beforeEqual = utils.StringTrimWhiteSpace(string.sub(line,1,i-1))
            local afterEqual = utils.StringTrimWhiteSpace(string.sub(line,i+1,string.len(line)))
            RawProjectConfigurations[beforeEqual]=afterEqual
        end
        ::continue::
    until(false)
    result.projectConfigurations = RawProjectConfigurations
    result.position =fileHandle:seek()
    result.line = lineCounter

    return result
end

--- Parse the Visual Studio Version
-- @param line The line that contains the information
local function ParseVisualStudioVersion(line)
    -- Input line is of the form
    --MinimumVisualStudioVersion = 10.0.40219.1
    local i,_ = string.find(line, '=')
    local value = string.sub(line,i+1)

    return require("solution.utils").StringTrimWhiteSpace(value)
end

--- Parses a .sln file into a lua structure
-- @param filename The path to the file
SolutionParser.ParseSolution = function(filename)
    local ext = path.GetFileExtension(filename)
    if (ext ~= ".sln") then
        return
    end

    local solution = {
        SolutionPath = filename,
        VisualStudioVersion = nil,
        MinimumVisualStudioVersion = nil,
        Projects = {},
        SolutionConfigurations = {},
        ProjectConfigurations = {},
        _text = {}
    }


    local utils = require("solution.utils")
    -- Use read mode for the file.
    local file = io.open(filename,"r")
    if(file == nil) then
        print("Could not open file")
        vim.notify("Could not open file: ".. filename,vim.log.levels.ERROR,{title = "Solution.nvim"})
        return
    end
    -- At some points we need to rewind thus we need to remember our positions
    local previousPosition = 0
    local lineCounter = 0
    local textIndex = 1
    while(true) do
        local line = file:read()
        if(line == nil) then
            break
        end
        lineCounter = lineCounter + 1

        if(utils.StringStartsWith(line,"Project(")) then
            -- We have now read a line that denotes the start of a project.
            -- Since it's parsing is non trivial rewind the file to the end
            -- of the previous line and delegate the parsing to the ParseProject
            -- function.
            local result = ParseProject(file,previousPosition,lineCounter)
            if result.project ~= nil then
                table.insert(solution.Projects, result.project)
            end
            file:seek("set",result.position)
            lineCounter = result.line
        elseif (utils.StringStartsWith(line,"GlobalSection(NestedProjects)")) then
            -- TODO: Parse nested projects
            solution._text[textIndex] = {lineCounter, line}
            textIndex = textIndex + 1;
        elseif (utils.StringStartsWith(utils.StringTrimWhiteSpace(line),"GlobalSection(SolutionConfigurationPlatforms)")) then
            local result = ParseSolutionConfigurations(file,previousPosition,lineCounter)
            if result.configurations ~= nil then
                solution.SolutionConfigurations = result.configurations
            end
            file:seek("set",result.position)
            lineCounter = result.line
        elseif (utils.StringStartsWith(utils.StringTrimWhiteSpace(line),"GlobalSection(ProjectConfigurationPlatforms)")) then
            local result = ParseProjectConfigurations(file,previousPosition, lineCounter)
            if result.projectConfigurations ~= nil then
                --print(vim.inspect(a))
                solution.ProjectConfigurations = ProcessRawProjectConfigurations(solution.Projects,solution.SolutionConfigurations,result.projectConfigurations)
                --table.insert(solution.projects, a)
            else
                print("Project Configurations were parsed as nil!")
            end
            file:seek("set",result.position)
            lineCounter = result.line
            --return solution
        elseif (utils.StringStartsWith(line,"VisualStudioVersion")) then
            solution.VisualStudioVersion = ParseVisualStudioVersion(line)
        elseif (utils.StringStartsWith(line,"MinimumVisualStudioVersion")) then
            solution.MinimumVisualStudioVersion= ParseVisualStudioVersion(line)
        else
            -- This is text that we store but does not offer any significant value
            -- and is just output to the solution writer at the appropriate positions.
            -- So in order to be good we need to filter
            solution._text[textIndex] = {lineCounter, line}
            textIndex = textIndex + 1;
        end
        previousPosition = file:seek()
    end

    --print(vim.inspect(solution))

    return solution
end


--- Displays a solution structure to a popup window
-- @param theSolution The solution structure to be displayed
SolutionParser.DisplaySolution = function(theSolution)
    local win = require("solution.window")

    if(theSolution == nil) then
        vim.notify("No solution loaded, nothing to display",vim.log.levels.WARN,{title = "Solution.nvim"})
        return
    end

    local window = win.new(" " .. theSolution.SolutionPath .. " ")
    window.PaintWindow()
    window.SetFiletype("lua")

    local str = vim.inspect(theSolution)

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

SolutionParser.GetProjectPath = function(Solution,IndexOrName)
    local os = require("solution.osutils")
    if(type(IndexOrName) == "number") then
        local parent = path.GetParrentDirectory(Solution.SolutionPath,os.seperator())
        local ProjectPath = parent .. os.seperator() .. Solution.Projects[IndexOrName].RelPath
        return ProjectPath
    end

    if(type(IndexOrName) == "string") then
        local parent = path.GetParrentDirectory(Solution.SolutionPath,os.seperator())
        local ProjectPath = parent .. os.seperator() .. Solution.Projects[1].RelPath
        return ProjectPath
    end
end


return SolutionParser
