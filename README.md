# solution.nvim
A neovim plugin that adds support for V***** S***** .sln and .csproj files.
Written in Lua.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Current State
**Warning**: This plugin is still in early alpha stage and the design will be breaking frequently.
This piece of software comes as is 

## Showcase
Solution Loading:

https://user-images.githubusercontent.com/6718844/219972645-bd9d4ea8-0756-4611-8213-5089bbcd119c.mp4

Compiling and quickfix support:

https://user-images.githubusercontent.com/6718844/219972947-07137eff-7432-4cd9-90fd-a898d9af188d.mp4



## How it Works
When opening a .cs file the plugin searches the upstream directories for any
`.sln` or `.csproj` file and parses it.

## Dependencies
1. `nvim-treesitter` plugin.
1. `plenary.nvim` for the test execution

## Setup
In order to use with the default configuration.
```lua
local sln = require("solution").setup()
```
For customised configurations pass a configuration table to the setup function

```lua
local SolutionConfig = {
    -- Indicates the selection policy. Currently there are two policies.
    -- 1) first
    -- 2) selection
    -- First indicates to use the first file that is found and is applicable
    -- select indicates to ask to selection in case that there are multiple applicable
    -- files found
    SolutionSelectionPolicy = "first",   -- Compile the first project that we find.
    DefaultBuildConfiguration = "Debug", -- What configuration to build with
    DefaultBuildPlatform = "Any CPU",
    Display = {
        RemoveCR = true,                 -- Remove final CR characters on popup windows
        HideCompilationWarnings = true   -- Hide compilation warnings
    }
}


https://github.com/bradharding/doomretro.git

sln.setup(config)
```

### Setup options
`SolutionSelectionPolicy`: Defines the behavior when multiple .sln files have
been detected. valid values are `first` and `select`
`BuildConfiguration`: defines the default build configuration for the solution

## Usage
The following commands are defined by the plugin:
1. `LoadSolution`                  :Loads a solution in memory
1. `DisplaySolution`               :Displays the loaded solution
1. `DisplayOutputs`                :Displays the .dll executables that this solution produces
1. `DisplayExecutionScheme`        :Displays the current solution configuration and platform. Also displays the solution outputs
1. `DisplayStartupProjectProfiles` :Displays the project profiles for the startup project
1. `SelectBuildConfiguration`      :Select Active Build Configuration
1. `SelectPlatform`                :Select Active Build Platform
1. `SelectWaringDisplay`           :Select if compilation warnings populate the quickfix list
1. `SelectStartupProject`          :Select the solution startup project
1. `SelectTest`                    :Select a test for debug
1. `ExecuteTest`                   :Select a test for debug
1. `LaunchSolution`                :Launch the solution
1. `CompileSolution`               :Compiles the currently loaded solution




## Cache location
The cache is located on the following locations
```
AppData\Local\Temp\nvim
```

## Implemented Features
- [x] Automatic `.sln` and `.csproj` detection within the filesystem.
- [x] Quick fix list implementation from compilation output.
    - [x] Color compilation output
- [x] Solution file parsing
- [x] Solution file syntax highlighting parsing
- [x] Project file parsing
    - [x] xml parser implementation (use the xml2lua parser)
- [x] Popup window implementation
- [x] Live compilation on popup window
- [x] Unit test discovery
- [x] Ability to display the solution or the project that is loaded in memory.
- [x] Ability to write solution files
- [x] Automatic executable output discovery for DAP debugging.
- [x] Persistent between project settings (using lua `vim.fn.stdpath("cache") .. "/solution.nvim",` 

## Solution `.sln` support
Currently the plugin can parse(for the most part) the solution files. Based on
that we should provide:
- [x] Solution Configuration selection
- [x] Ability to write solution files -- This enables the following featues
    - [ ] Ability to add solution configurations
    - [ ] Ability to add solution platforms

## Project file `.csproj` support 
Currently the project files are parsed useing xml2lua.


## Ideas for future implementation
Below are listed ideas of what the plugin could do. Not in order of priority.
- [x] Support for executing the project inside nvim (currently on windows only)
- [ ] Implement and Handle solution filters
- [ ] Async Compile. (maybe immplement using libuv)
- [ ] Implement a Unit test explorer
    - [ ] Add support for unit tests execution
    - [ ] Single test execution to support test driven development
- [ ] Add support for project exclusion
- [ ] Integration with dap modules for easier discovery of programs.
- [ ] Add nuget package management.
