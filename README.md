<h1 align='center'>Code_Runner</h1>

<h4 align='center'>🔥 Code Runner for Neovim written in lua and python 🔥</h4>

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
### Quick start

Add the following line to your init.vim

```vimscript
lua require('code_runner').setup({})
```

### Functions

-   `:RunCode` - Run current file in native terminal.
-   `:FRunCode` - Run current file in FTerm(if exist).
-   `:SRunCode` - Open json  with supported files.


### Options

-   `term`: configurations for the integrated terminal

    Fields:

  - `position` - integrated terminal position(for option :h windows) default: `belowright`

  - `size` - size of the terminal window (default: `8`)


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

### Add support for more file types
Run :SRunCode, The configuration file is called code_runner.json.

The file should look like this:

```` json

{
    "java": "cd {dir} && javac {fileName} && java {fileNameWithoutExt}",
    "c": "cd {dir} && gcc {fileName} -o {fileNameWithoutExt} && {dir}{fileNameWithoutExt}",
    "cpp": "cd {dir} && g++ {fileName} -o {fileNameWithoutExt} && {dir}{fileNameWithoutExt}",
    "py": "python -u {file}",
    "ts": "deno run {file}",
    "rs": "cd {dir} && rustc {fileName} && {dir}{fileNameWithoutExt}"
}

````

In the code_runner.json a series of commands associated with file extensions is specified, if you want to add some other language follow this structure "extension": "commans"

#### Variable

Variables are represented in python f string style
the available variables are the following:

  * file  -- file path to currend file opened
  * fileName  -- file name to curren file opened
  * fileNameWithoutExt  -- file without extension file opened
  * dir  -- currend path to file opened

##### Example

add support to javascript and objective c:

```` json
{
....... more..........
     "js": "node {file}",
     "m": "cd {dir} && gcc -framework Cocoa {fileName} -o {fileNameWithoutExt} && {dir}{fileNameWithoutExt}"

}
````
# Important!
If you have any ideas to improve this project, do not hesitate to make a request, if problems arise, try to solve them and publish them. Don't be so picky I did this in one afternoon
