<h1 align='center'>Code_Runner</h1>

<h4 align='center'>🔥 Code Runner for Neovim written in pure lua 🔥</h4>

![Code_Runner](https://i.ibb.co/gFRhLgr/screen-1628272271.png "Code Runner with python")

### Requirements

-   Neovim (0.5)

### Install

-   With [packer.nvim](https://github.com/wbthomason/packer.nvim)


```lua
use 'CRAG666/code_runner.nvim'
```
### Quick start

Add the following line to your init.vim

```vimscript
lua require('code_runner').setup({})
```

### chek new features
check out the new_features branch(Unstable)

```lua
use {'CRAG666/code_runner.nvim', branch = "new_features"}
```
#### Features
* Better code
* Faster
* Project management and execution
* Execution functions like jetbrains IDEs but without being so heavy

Your help is needed to make this plugin the best of its kind, be free to contribute, criticize (don't be soft) or contribute ideas

### Functions

-   `:SRunCode` - Open json  with supported files.


### Options

- `term`: configurations for the integrated terminal

  Fields:

    - `position` - integrated terminal position(for option :h windows) default: `belowright`
    - `size` - size of the terminal window (default: `8`)

- `map`: keys to trigger execution (default: `<leader>r`)

- `json_path`: absolute path to json file config (default: packer module path)


### Setup

```lua
-- this is a config example
require('code_runner').setup {
  term = {
    position = "vert",
    size = 8
  },
  map = "<leader>r",
  json_path = "/home/myuser/.config/nvim/code_runner.json"
}

```

### Add support for more file types
Run :SRunCode, The configuration file is called code_runner.json.

The file should look like this(the default file does not exist create it with the SRunCode command):

````json

{
    "java": "cd $dir && javac $fileName && java $fileNameWithoutExt",
    "python": "python -U",
    "typescript": "deno run",
    "rust": "cd {dir} && rustc $fileName && $dir$fileNameWithoutExt"
}

````

In the code_runner.json a series of commands associated with file type (chek file type in vim/neovim) is specified, if you want to add some other language follow this structure "file_type": "commans"

#### Variable

The available variables are the following:

  * file  -- file path to currend file opened
  * fileName  -- file name to curren file opened
  * fileNameWithoutExt  -- file without extension file opened
  * dir  -- currend path to file opened

##### Example

Add support to javascript and objective c:

````json
{
....... more ........
     "javascript": "node",
     "objective-c": "cd $dir && gcc -framework Cocoa $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt"
}
````
In this example, there are two file types, one uses variables and the other does not. If no variables are used, the plugin adds the current file path. This is a way to add commands in a simple way for those languages that do not require complexity to execute (python and javascrip for example)

# Important!
If you have any ideas to improve this project, do not hesitate to make a request, if problems arise, try to solve them and publish them. Don't be so picky I did this in one afternoon
