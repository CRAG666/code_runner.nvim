<h1 align='center'>Code_Runner</h1>

<h4 align='center'>🔥 Code Runner for Neovim written in pure lua 🔥</h4>

![Code Runner](https://i.ibb.co/1njTRTL/ezgif-com-video-to-gif.gif)

### Requirements

-   Neovim (0.5)

### Install

-   With [packer.nvim](https://github.com/wbthomason/packer.nvim)


```lua
use { 'CRAG666/code_runner.nvim', requires = 'nvim-lua/plenary.nvim' }
```
### Quick start

Add the following line to your init.vim

```vimscript
lua require('code_runner').setup({})
```

### Chek new features
check out the new_features branch(Unstable)

```lua
use { 'CRAG666/code_runner.nvim', requires = 'nvim-lua/plenary.nvim', branch = "new_features" }
```
#### Features
* (Nothing new for now)

Your help is needed to make this plugin the best of its kind, be free to contribute, criticize (don't be soft) or contribute ideas

### Functions

-   `CRFiletype` - Open json  with supported files.
-   `CRProjects` - Open json with list of projects.
-   `:RunCode` - Runs based on file type, first checking if belongs to project, then if filetype mapping exists
-   `:RunCode <A_key_here>` - Runs command with key of cool in the current directory.
-   `RunFile`    - Run the current file
-   `RunProject` - Run the current project(If you are in a project otherwise you will not do anything)


### Options

- `term`: configurations for the integrated terminal

  Fields:

    - `position`: integrated terminal position(for option :h windows) default: `belowright`
    - `size`: size of the terminal window (default: `8`)

- `filetype`: Configuration for filetype

  Fields:

    - `map`: keys to trigger execution (default: `<leader>r`)

    - `json_path`: absolute path to json file config (default: packer module path)

- `project_context`: Configuration for projects

  Fields:

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
  filetype = {
    map = "<leader>r",
    json_path = "/home/myuser/.config/nvim/code_runner.json"
  },
  project_context = {
    map = "<leader>r",
    json_path = "/home/myuser/.config/nvim/projects.json"
  }
}

```
As seen in this example configuration, both project_context and filetype have the same keymap assigned, this does not cause any problem because in these cases the plugin assigns a single map to `:RunCode`(read how it works `:RunCode`).


### Add support for more file types
Run `CRFiletype` , Open the configuration file.

The file should look like this(the default file does not exist create it with the `CRFiletype` command):

````json

{
    "java": "cd $dir && javac $fileName && java $fileNameWithoutExt",
    "python": "python -U",
    "typescript": "deno run",
    "rust": "cd $dir && rustc $fileName && $dir/$fileNameWithoutExt"
}

````

In the code_runner.json a series of commands associated with file type (chek file type in vim/neovim) is specified, if you want to add some other language follow this structure "file_type": "commans"

#### Variable

The available variables are the following:

  * file  -- file path to currend file opened
  * fileName  -- file name to curren file opened
  * fileNameWithoutExt  -- file without extension file opened
  * dir  -- path of directory to file opened

Below is an example of an absolute path and how it behaves depending on the variable:

absolute path: /home/anyuser/current/file.py

- file = /home/anyuser/current/file.py
- fileName = file.py
- fileNameWithoutExt = file
- dir = /home/anyuser/current

##### Example

Add support to javascript and objective c:

````json
{
....... more ........
"javascript": "node",
"objective-c": "cd $dir && gcc -framework Cocoa $fileName -o $fileNameWithoutExt && $dir/$fileNameWithoutExt"
}
````

In this example, there are two file types, one uses variables and the other does not. If no variables are used, the plugin adds the current file path. This is a way to add commands in a simple way for those languages that do not require complexity to execute (python and javascrip for example)


### Add projects
Run `CRProjects` , Open the project list.

The file should look like this(the default file does not exist create it with the `CRProjects` command):

````json
{
    "~/python/intel_2021_1": {
        "name": "Intel Course 2021"
        "description": "Simple python project",
        "file_name": "POO/main.py"
    },
    "~/deno/example": {
        "name": "ExapleDeno"
        "description": "Project with deno using other command",
        "file_name": "http/main.ts",
        "command": "deno run --allow-net"
    },
    "~/cpp/example": {
        "name": "ExapleCpp"
        "description": "Project with make file",
        "command": "make buid & cd buid/ & ./compiled_file"
    }
}
````
There are 3 main ways to configure the execution of a project (found in the example.)

1. Use the default command defined in the filetypes file (see `:CRFiletype`). In order to do that it is necessary to define file_name.

2. Use a different command than the one set in `CRFiletype`. In this case, the file_name and command must be provided.

3. Use a command to run the project. It is only necessary to define command(You do not need to write navigate to the root of the project, because automatically the plugin is located in the root of the project).

#### Projects parameters

-  `name`: Project name
-  `description`: Project description
-  `file_name`: Filename relative to root path
-  `command`: Command to run the project. It is possible to use variables exactly the same as we would in `CRFiletype`

warning! : Avoid using all the parameters at the same time. The correct way to use them is shown in the example and described above.

# Screenshots

![typescript](https://i.ibb.co/JCg3tNd/ezgif-com-video-to-gif.gif)

![python](https://i.ibb.co/1njTRTL/ezgif-com-video-to-gif.gif)

![Code_Runner](https://i.ibb.co/gFRhLgr/screen-1628272271.png "Code Runner with python")

# Tip
For unknown reasons, leaving a comma in the trailing element in any json file causes an error when loading into lua, so you have to remove the trailing comma in the last item.

# Important!
If you have any ideas to improve this project, do not hesitate to make a request, if problems arise, try to solve them and publish them. Don't be so picky I did this in one afternoon
