# solution.nvim
A neovim plugin that adds support for V***** S***** .sln and .csproj files.
Written in Lua.

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
    -- select indicates to ask to selection of there are multiple files found
    ProjectSelectionPolicy = "first",
    BuildConfiguration = "Debug",
    display = { -- Controls options for popup windows.
        removeCR = true,
        HideCompilationWarnings = true
    },
}

sln.setup(config)
```

### Setup options
`ProjectSelectionPolicy`: Defines the behavior when multiple .sln files have
been detected. valid values are `first` and `select`
`BuildConfiguration`: defines the default build configuration for the solution

## Usage

## Current State
The plugin is still in early alpha stage and the design will be breaking frequently.

## Implemented Features
- [x] Automatic `.sln` and `.csproj` detection within the filesystem.
- [x] Quick fix list implementation from compilation output.
    - [x] Color compilation output
- [x] Solution file parsing
- [x] Project file parsing
    - [x] xml parser implementation (use the xml2lua parser)
- [x] Popup window implementation
- [x] Live compilation on popup window
- [x] Unit test discovery
- [x] Ability to display the solution or the project that is loaded in memory.
- [x] Ability to write solution files

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
- [ ] Support for executing the project inside nvim
- [ ] Async Compile. (maybe immplement using libuv)
- [ ] Implement a Unit test explorer
    - [ ] Add support for unit tests execution
    - [ ] Single test execution to support test driven development
- [ ] Add support for project exclusion
- [ ] Persistent between project settings (using lua `vim.fn.stdpath("cache") .. "/Solution.nvim",` 
- [ ] Integration with dap modules for easier discovery of programs.
- [ ] Add nuget package management.
