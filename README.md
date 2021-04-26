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

-   With [vim-plug](https://github.com/junegunn/vim-plug)

#### Use FTerm
```vim
Plug 'numtostr/FTerm.nvim'
Plug 'CRAG666/code_runner.nvim'
```

#### Use native Terminal
```vim
Plug 'CRAG666/code_runner.nvim'
```

### Functions

-   `:RunCode` - Run current file in native terminal.
-   `:FRunCode` - Run current file in FTerm.

### Configuration
