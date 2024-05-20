# The solution datastructur

When a solution is parsed the solution is stored in a datastrucutre as follows:
```lua
    local solution = {
        --- The absolute path of the solution file
        SolutionPath = filename,
        VisualStudioVersion = nil,
        MinimumVisualStudioVersion = nil,
        Projects = {},
        SolutionConfigurations = {},
        ProjectConfigurations = {},
        _text = {}
    }
```

# Cache

## Cache Data
```json
{
    "OutputLocations":[
        {
            "Project":"libExcel",
            "OutputLocation":"C:\\Users\\Admin\\source\\repos\\libExcel\\libExcel\\bin\\Debug\\net7.0\\libExcel.dll"
        },{
            "Project":"Test",
            "OutputLocation":"C:\\Users\\Admin\\source\\repos\\libExcel\\Test\\bin\\Debug\\net7.0\\Test.dll"
        }
    ],
    "BuildConfiguration":"Debug",
    "BuildPlatform":"Any CPU"
}
```
