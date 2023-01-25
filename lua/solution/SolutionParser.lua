local SolutionParser = {}

local path = require("solution.path")

local function ParseProjectLine(line)
    --Project("{9A19103F-16F7-4668-BE54-9A1E7A4F7556}") = "AIStream", "AIStream\AIStream.csproj", "{901BBF64-7D29-4DC4-BED4-61DEEDA35237}"
    --EndProject
    print("Parsing Line:" .. line)
    local i, j = string.find(line, "EndProject")

    if(i ~= nil and j ~= nil) then
        return nil
    end
    i, j = string.find(line, "Project")

    if(i == nil or j == nil) then
        return nil
    end

    if(i ~= nil and j ~= nil) then
        --print("i:"..i.." j:"..j)
        -- Project word found let's find the equal sign so that we can locate the project.
        i,_ = string.find(line,"=")
        --print("Found = at position:"..i)
        i,j = string.find(line,"\"",i)
        _,j = string.find(line,"\"",j+1)
        --print("Found quotes at i:"..i.." j:"..j)
        local ProjectName = string.sub(line,i+1,j-1)

        i,j = string.find(line,",",j)
        i,_ = string.find(line,"\"",i)
        _,j = string.find(line,"\"",i+1)
        local ProjectRelativePath = string.sub(line,i+1,j-1)

        local project = {}
        project.name = ProjectName
        project.RelPath = ProjectRelativePath

        return project
    else
        return nil
    end
end

SolutionParser.ParseSolution = function(filename)
    local ext = path.GetFileExtension(filename)
    if (ext ~= ".sln") then
        print("File extension is not sln but ".. ext)
        return
    end

    -- A value to check the region. Can have the following values:
    -- preamble
    -- projects
    -- global
    local state = "preamble"
    -- The table that will contain the end result.
    local solution = {
        projects = {}
    }
    for line in io.lines(filename) do
        local i, j = string.find(line, "MinimumVisualStudioVersion")
        if(i ~= nil and j ~= nil) then
            state = "projects"
        end

        i, j = string.find(line, "Global")
        if(i ~= nil and j ~= nil) then
            state = "global"
        end
        -- Parse line.
        if (state == "projects") then
            local a = ParseProjectLine(line)
            if a ~= nil then
                table.insert(solution.projects, a)
            end
        end
    end

    print(vim.inspect(solution))

    return solution
end

return SolutionParser
