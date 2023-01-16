# solution.nvim
A neovim plugin that adds support for V***** S***** .sln and .csproj files.
Written in Lua.

## How it Works
The when the compile method is called, the plugin searches upstream for any `.sln`
or `.csproj` item. Then it calls the `dotnet build` command and with the specified
project configuration and architecture. It then parses the result for any error
or warnings that might have occured and populates a quicfix buffer.

## Usage
In order to use with the default configuration.
```lua
local sln = require("solution")
```

## Ideas for future implementation
Below are listed ideas of what the plugin could do. Not in order of priority.
- [x] Automatic `.sln` and `.csproj` detection within the filesystem.
- [x] Quick fix list implementation from compilation output.
- [ ] Support for msbuild (this would support additional languages such as C/C++ with microsoft tools).
- [ ] Solution and project file parser (the features of the parser need to tbd). Maybe using treesitter.
- [ ] Solution Configuration selection
- [ ] Persistent project settings (Remember past projects that have been compiled)
- [ ] Add ui for information
- [ ] Add support for unit tests execution
- [ ] Add support for project exclusion
- [ ] Persistent between project settings (using lua `vim.fn.stdpath("cache") .. "/Solution.nvim",` 
