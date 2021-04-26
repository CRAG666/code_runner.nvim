<h1 align='center'>Code_Runner</h1>

<h4 align='center'>🔥 Code Runner like vscode written in lua and python 🔥</h4>

![Code_Runner](https://i.ibb.co/XX43DDs/2021-04-26-00-34.png "Code Runner with python")

### Requirements

-   Neovim Nightly (0.5)

### Install

-   With [packer.nvim](https://github.com/wbthomason/packer.nvim)


#### Use FTerm
```lua
use {
    "CRAG666/code_runner.nvim",
    requires = {"numtostr/FTerm.nvim"}
}
```

#### Use native Terminal
```lua
use 'CRAG666/code_runner.nvim'
```

### Functions

-   `:RunCode` - Run current file in native terminal.
-   `:FRunCode` - Run current file in FTerm(if exist).


### Configuration

-   `term`: configurations for the integrated terminal

    Fields:
  
  -   `position` - integrated terminal position(for option :h windows) default: `belowright`
  -   `size` - size of the terminal window (default: `8`)
  
-   `fterm`: Object containing the [FTerm](https://github.com/numToStr/FTerm.nvim) window dimensions.

    Fields: (Values should be between `0` and `1`)
  -   `height` - Height of the terminal window (default: `0.8`)
  -   `width` - Width of the terminal window (default: `0.8`)


### Setup

```lua

require('code_runner').setup {
  term = {
    position = "vert",
    size = 8
  },
  fterm = {
    height = 0.7,
    width = 0.7
  }
}

```