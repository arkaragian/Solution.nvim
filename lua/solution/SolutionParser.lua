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

local SolutionParser = {}

-- See https://www.codeproject.com/Reference/720512/List-of-Visual-Studio-Project-Type-GUIDs
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
    ["EFBA0AD7-5A72-4C68-AF49-8Pro3D382785DCF"]="Xamarin.Android / Mono for Android",
    ["F135691A-BF7E-435D-8960-F99683D2D49C"]="Distributed System",
    ["F184B08F-C81C-45F6-A57F-5ABD9991F28F"]="VB.NET",
    ["F2A71F9B-5D33-465A-A702-920D77279786"]="F#",
    ["F5B4F3BC-B597-4E2B-B552-EF5D8A32436F"]="MonoTouch Binding",
    ["F85E285D-A4E0-4152-9332-AB1D724D3325"]="ASP.NET MVC 2.0",
    ["F8810EC1-6754-47FC-A15F-DFABD2E3FA90"]="SharePoint Workflow",
    ["FAE04EC0-301F-11D3-BF4B-00C04F79EFBC"]="C#",
}

local path = require("solution.path")

local function ParseProjectLine(line)
    --  Parse the following
    --  Project("{Project type GUID}") = "Project name", "Relative path to project file", "{Project GUID}"
    --Project("{9A19103F-16F7-4668-BE54-9A1E7A4F7556}") = "AIStream", "AIStream\AIStream.csproj", "{901BBF64-7D29-4DC4-BED4-61DEEDA35237}"
    --EndProject
    --print("Parsing Line:" .. line)
    --local patternStart, patternEnd = string.find(line, "EndProject")

    --if(patternStart ~= nil and patternEnd ~= nil) then
        -- We have matched the EndProject. This means that there is nothing
        -- to do. Just return.
    --    return nil
    --end
    local patternStart, patternEnd = string.find(line, "Project")

    if(patternStart == nil or patternEnd == nil) then
        --We have no match. There is nothing to do.
        return nil
    end

    if(patternStart ~= nil and patternEnd ~= nil) then

        local project = {}

        local counter = 1
        for guid in string.gmatch(line, "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x") do
            if(counter == 1) then
                project.typeGUID = guid
                project.type = ProjectTypes[guid]
            else
                project.GUID = guid
            end
            counter = counter + 1
        end

        -- Project word found let's find the equal sign so that we can locate the project.
        patternStart,_ = string.find(line,"=")
        --print("Found = at position:"..i)
        patternStart,patternEnd = string.find(line,"\"",patternStart)
        _,patternEnd = string.find(line,"\"",patternEnd+1)
        --print("Found quotes at i:"..i.." j:"..j)
        local ProjectName = string.sub(line,patternStart+1,patternEnd-1)

        patternStart,patternEnd = string.find(line,",",patternEnd)
        patternStart,_ = string.find(line,"\"",patternStart)
        _,patternEnd = string.find(line,"\"",patternStart+1)
        local ProjectRelativePath = string.sub(line,patternStart+1,patternEnd-1)

        project.name = ProjectName
        project.RelPath = ProjectRelativePath

        return project
    else
        return nil
    end
end

--- Parse a project in a given open handle with the given start position
-- Description
-- @param Parameter Name Parameter Description
local function ParseProject(fileHandle,startPosition)
    --  What we need to parse is the following.
    --  Project("{Project type GUID}") = "Project name", "Relative path to project file", "{Project GUID}"
    --      ProjectSection(ProjectDependencies) = postProject
    --          {Parent project unique name} = {Parent project unique name}
    --          ...
    --      EndProjectSection
    --  EndProject
    fileHandle:seek("set",startPosition)
    local line = fileHandle:read()
    local project = ParseProjectLine(line)
    if(project == nil) then
        print("Error could not parse project!")
        return
    end

    local utils = require("solution.utils")
    while(true) do
        line = fileHandle:read()
        if(line == nil) then
            print("No more lines to read. Exiting..")
            break
        end

        if(line == "EndProject") then
            -- This is a normal ending for the project get our current position
            -- and return it to the calling function along with our project.
            local pos = fileHandle:seek()
            return project, pos
        elseif (utils.StringStartsWith("ProjectSection(ProjectDependencies)")) then
            -- We have a ProjectDependencies section.  Each subsequent line should identify
            -- a dependency. For now we don't need to parse those. I am unsure if the data here
            -- is of value to the plugin
        elseif (utils.StringStartsWith("ProjectSection(WebsiteProperties)")) then
            -- We have a WebsiteProperties section.  This section is present only in Venus
            -- projects, and contains properties that are needed in order to call the 
            -- AspNetCompiler task. However I am not sure on how those properties
            -- will be used in our plugin. For now we don't need to parse those.
            -- I am unsure if the data here is of value to the plugin
        elseif (utils.StringStartsWith("Project(")) then
            -- Another Project spotted instead of EndProject for the current one - solution file is malformed
            -- We don't support this. Print an error for the user.
            print("Detected nested project definitions. The solution file is malformed.")
        else
        end
    end
end


SolutionParser.ParseNestedProjects = function(fileHandle,startPosition)
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
            print("No more lines to read. Exiting..")
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

SolutionParser.ParseSolutionConfigurations = function(file,position)
end

SolutionParser.ParseProjectConfigurations = function()
end

SolutionParser.ParseVisualStudioVersion = function(line)
    -- Input line is of the form
    --MinimumVisualStudioVersion = 10.0.40219.1
    local i,_ = string.find(line, '=')
    local value = string.sub(line,i+1)

    return require("solution.utils").StringTrimWhiteSpace(value)
end

SolutionParser.ParseSolution = function(filename)
    local ext = path.GetFileExtension(filename)
    if (ext ~= ".sln") then
        print("File extension is not sln but ".. ext)
        return
    end

    local solution = {
        VisualStudioVersion = nil,
        MinimumVisualStudioVersion = nil,
        projects = {},
    }

    -- A value to check the region. Can have the following values:
    -- Preamble
    -- Project
    -- NestedProject
    -- ProjectConfigurationPlatforms
    -- SolutionConfigurationPlatforms
    local state = "Preamble"


    local utils = require("solution.utils")
    -- Use read mode for the file.
    local file = io.open(filename,"r")
    if(file == nil) then
        print("Could not open file")
        return
    end
    -- At some points we need to rewind thus 
    local previousPosition = 0
    while(true) do
        local line = file:read()
        if(line == nil) then
            print("No more lines to read. Exiting..")
            break
        end

        if(utils.StringStartsWith(line,"Project(")) then
            -- We have now read a line that denotes the start of a project.
            -- Since it's parsing is non trivial rewind the file to the end
            -- of the previous line and delegate the parsing to the ParseProject
            -- function.
            local a, pos = ParseProject(file,previousPosition)
            if a ~= nil then
                table.insert(solution.projects, a)
            end
            file:seek("set",pos)
            previousPosition = file:seek()
            --return solution
            break
        elseif (utils.StringStartsWith(line,"GlobalSection(NestedProjects)")) then
        elseif (utils.StringStartsWith(line,"GlobalSection(SolutionConfigurationPlatforms)")) then
        elseif (utils.StringStartsWith(line,"GlobalSection(ProjectConfigurationPlatforms)")) then
        elseif (utils.StringStartsWith(line,"VisualStudioVersion")) then
            solution.VisualStudioVersion = SolutionParser.ParseVisualStudioVersion(line)
        elseif (utils.StringStartsWith(line,"MinimumVisualStudioVersion")) then
            solution.MinimumVisualStudioVersion= SolutionParser.ParseVisualStudioVersion(line)
        else
            -- Do nothing
        end
            previousPosition = file:seek()
    end

    print(vim.inspect(solution))

    return solution
end

return SolutionParser
