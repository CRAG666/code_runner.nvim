<h1 align='center'>Code_Runner</h1>

<h4 align='center'>🔥 Code Runner for Neovim written in pure lua 🔥</h4>

![Code Runner](https://i.ibb.co/1njTRTL/ezgif-com-video-to-gif.gif)

# Introduction

When I was still in college it was common to try multiple programming languages, at that time I used vscode that with a single plugin allowed me to run many programming languages, I left the ballast that are electron apps and switched to neovim, I searched the Internet and finally i found a lot of plugins, but none of them i liked (maybe i didn't search well), so i started adding autocmds like i don't have a tomorrow, this worked fine but this is lazy (maybe it will work for you, if you only programs in one or three languages maximum). So I decided to make this plugin and since the migration of my commands was very fast, it was just copy and paste and everything worked. Currently I don't test many languages anymore and work in the professional environment, but this plugin is still my swiss army knife.

### Requirements

- Neovim (>= 0.7)

### Install

- With [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { 'CRAG666/code_runner.nvim', requires = 'nvim-lua/plenary.nvim' }
```

- With [paq-nvim](https://github.com/savq/paq-nvim)

```lua
require "paq"{'CRAG666/code_runner.nvim'; 'nvim-lua/plenary.nvim';}
```

### Quick start

Add the following line to your init.lua

```lua
require('code_runner').setup({
  -- put here the commands by filetype
  filetype = {
		java = "cd $dir && javac $fileName && java $fileNameWithoutExt",
		python = "python3 -u",
		typescript = "deno run",
		rust = "cd $dir && rustc $fileName && $dir/$fileNameWithoutExt"
	},
})
```

Don't use setup if filetype or a json path

#### Features

- Toggle runner
- Reload runner
- Run in a Float window
- Run in a tab
- Run in a split
- Run in toggleTerm

##### Help build this feature

The things to do are listed below:

- Open an issue to know if it is worth implementing this function and if there are people interested in its existence

### Functions

All run commands allow restart. So, for example, if you use a command that does not have hot reload, you can call a command again and it will close the previous one and start again.

- `:RunCode` - Runs based on file type, first checking if belongs to project, then if filetype mapping exists
- `:RunCode <A_key_here>` - Execute command from its key in current directory.
- `:RunFile <mode>` - Run the current file(optionally you can select an opening mode: {"toggle", "float", "tab", "toggleterm"}, default: "term").
- `:RunProject <mode>` - Run the current project(If you are in a project otherwise you will not do anything, (optionally you can select an opening mode: {"toggle", "float", "tab", "toggleterm"}, default: "term").
- `:RunClose` - Close runner
- `:CRFiletype` - Open json with supported files(Use only if you configured with json files).
- `:CRProjects` - Open json with list of projects(Use only if you configured with json files).

This plugin stopped creating mappings, in favor of you creating your own

Recomended:

```lua
vim.keymap.set('n', '<leader>r', ':RunCode<CR>', { noremap = true, silent = false })
vim.keymap.set('n', '<leader>rf', ':RunFile<CR>', { noremap = true, silent = false })
vim.keymap.set('n', '<leader>rft', ':RunFile tab<CR>', { noremap = true, silent = false })
vim.keymap.set('n', '<leader>rp', ':RunProject<CR>', { noremap = true, silent = false })
vim.keymap.set('n', '<leader>rc', ':RunClose<CR>', { noremap = true, silent = false })
vim.keymap.set('n', '<leader>crf', ':CRFiletype<CR>', { noremap = true, silent = false })
vim.keymap.set('n', '<leader>crp', ':CRProjects<CR>', { noremap = true, silent = false })
```

### Options

- `mode`: Mode in which you want to run(default: term, valid options: {"toggle", "float", "tab", "toggleterm"}),
- `focus`: Focus on runner window(only works on toggle, term and tab mode, default: true)
- `startinsert`: init in insert mode(default: false)
- `term`: Configurations for the integrated terminal
  Fields:

  - `position`: Integrated terminal position(for option :h windows, default: `belowright`)
  - `size`: Size of the terminal window (default: `8`)

- `float`: Configurations for the float win
  Fields:

  - `border`: Window border (see ':h nvim_open_win')
  - `height`
  - `width`
  - `x`
  - `y`
  - `border_hl`: (default: FloatBorder)
  - `float_hl`: (defult: "Normal")
  - `blend`: Transparency (see ':h winblend')

- `filetype_path`: Absolute path to json file config (default: packer module path, use absolute paths)

- `filetype`: If you prefer to use lua instead of json files, you can add your settings by file type here(type table)

- `project_path`: Absolute path to json file config (default: packer module path, use absolute paths)

- `project`: If you prefer to use lua instead of json files, you can add your settings by project here(type table)

### Setup

```lua
-- this is a config example
require('code_runner').setup {
  mode = "tab"
  focus = false,
  startinsert = true
	term = {
		position = "vert",
		size = 8,
	},
	filetype_path = vim.fn.expand('~/.config/nvim/code_runner.json'),
	project_path = vim.fn.expand('~/.config/nvim/project_manager.json')
}
```

Note: A common mistake code runners make is using relative paths and not absolute ones. Use absolute paths in configurations or else the plugin won't work, in case you like to use short or relative paths you can use something like this `vim.fn.expand('~/.config/nvim/project_manager.json')`

#### Default values

```lua
require('code_runner').setup {
  -- choose default mode (valid term, tab, float, toggle)
  mode = 'term',
  -- Focus on runner window(only works on toggle, term and tab mode)
  focus = true,
  -- startinsert (see ':h inserting-ex')
  startinsert = false,
  term = {
    --  Position to open the terminal, this option is ignored if mode is tab
    position = "bot",
    -- window size, this option is ignored if tab is true
    size = 8,
  },
  float = {
    -- Window border (see ':h nvim_open_win')
    border = "none",

    -- Num from `0 - 1` for measurements
    height = 0.8,
    width = 0.8,
    x = 0.5,
    y = 0.5,

    -- Highlight group for floating window/border (see ':h winhl')
    border_hl = "FloatBorder",
    float_hl = "Normal",

    -- Transparency (see ':h winblend')
    blend = 0,
  },
  filetype_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/code_runner.nvim/lua/code_runner/code_runner.json",
  filetype = {},
  project_path = vim.fn.stdpath("data")
      .. "/site/pack/packer/start/code_runner.nvim/lua/code_runner/project_manager.json",
  project = {},
}
```

It is important that you know that configuration is given priority in pure lua, but if you prefer to configure in json, do not add the options filetype and project, and configure over the options filetype_path and project_path (these are paths of the os where your file is json), then you have a configuration in pure lua:

```lua
require('code_runner').setup {
  mode = "term"
  startinsert = true
	term = {
		position = "vert",
		size = 15,
	},
	filetype = {
		java = "cd $dir && javac $fileName && java $fileNameWithoutExt",
		python = "python3 -u",
		typescript = "deno run",
		rust = "cd $dir && rustc $fileName && $dir/$fileNameWithoutExt"
	},
	project = {
		["~/deno/example"] = {
			name = "ExapleDeno",
			description = "Project with deno using other command",
			file_name = "http/main.ts",
			command = "deno run --allow-net"
		},
		["~/cpp/example"] = {
			name = "ExapleCpp",
			description = "Project with make file",
			command = "make buid & cd buid/ & ./compiled_file"
		}
	},
}
```

### Add support for more file types

#### Configure with json files

Run `CRFiletype` , Open the configuration file.

The file should look like this(the default file does not exist create it with the `CRFiletype` command):

```json
{
  "java": "cd $dir && javac $fileName && java $fileNameWithoutExt",
  "python": "python3 -u",
  "typescript": "deno run",
  "rust": "cd $dir && rustc $fileName && $dir/$fileNameWithoutExt"
}
```

#### Configure with lua files

```lua
..... more config .....
	filetype = {
	java = "cd $dir && javac $fileName && java $fileNameWithoutExt",
	python = "python3 -u",
	typescript = "deno run",
	rust = "cd $dir && rustc $fileName && $dir/$fileNameWithoutExt"
},
..... more config .....
}
```

if you want to add some other language or some other command follow this structure "key": "commans"

#### Variables

The available variables are the following:

- `file` -- file path to currend file opened
- `fileName` -- file name to curren file opened
- `fileNameWithoutExt` -- file without extension file opened
- `dir` -- path of directory to file opened

Below is an example of an absolute path and how it behaves depending on the variable:

absolute path: /home/anyuser/current/file.py

- `file` = /home/anyuser/current/file.py
- `fileName` = file.py
- `fileNameWithoutExt` = file
- `dir` = /home/anyuser/current

Remember that if you don't want to use variables you can use vim [filename-modifiers](http://vimdoc.sourceforge.net/htmldoc/cmdline.html#filename-modifiers)

##### Example

Add support to javascript and objective c:

json:

```json
{
....... more ........
	"javascript": "node",
	"objective-c": "cd $dir && gcc -framework Cocoa $fileName -o $fileNameWithoutExt && $dir/$fileNameWithoutExt"
}
```

lua:

```lua
{
	....... more ........
		javascript = "node",
	["objective-c"] = "cd $dir && gcc -framework Cocoa $fileName -o $fileNameWithoutExt && $dir/$fileNameWithoutExt"
}
```

In this example, there are two file types, one uses variables and the other does not. If no variables are used, the plugin adds the current file path. This is a way to add commands in a simple way for those languages that do not require complexity to execute (python and javascrip for example)

### Add projects

#### Configure with json files

Run `CRProjects` , Open the project list.

The file should look like this(the default file does not exist create it with the `CRProjects` command):

```json
{
  "~/python/intel_2021_1": {
    "name": "Intel Course 2021",
    "description": "Simple python project",
    "file_name": "POO/main.py"
  },
  "~/deno/example": {
    "name": "ExapleDeno",
    "description": "Project with deno using other command",
    "file_name": "http/main.ts",
    "command": "deno run --allow-net"
  },
  "~/cpp/example": {
    "name": "ExapleCpp",
    "description": "Project with make file",
    "command": "make buid & cd buid/ & ./compiled_file"
  }
}
```

#### Configure with lua files

```lua
..... more config .....
	project = {
	["~/python/intel_2021_1"] = {
		name = "Intel Course 2021",
		description = "Simple python project",
		file_name = "POO/main.py"
	},
	["~/deno/example"] = {
		name = "ExapleDeno",
		description = "Project with deno using other command",
		file_name = "http/main.ts",
		command = "deno run --allow-net"
	},
	["~/cpp/example"] = {
		name = "ExapleCpp",
		description = "Project with make file",
		command = "make buid & cd buid/ & ./compiled_file"
	}
},
..... more config .....
}
```

There are 3 main ways to configure the execution of a project (found in the example.)

1. Use the default command defined in the filetypes file (see `:CRFiletype`or check your confi lua). In order to do that it is necessary to define file_name.

2. Use a different command than the one set in `CRFiletype` or your config lua. In this case, the file_name and command must be provided.

3. Use a command to run the project. It is only necessary to define command(You do not need to write navigate to the root of the project, because automatically the plugin is located in the root of the project).

Note: Don't forget to name your projects because if you don't do so code runner will fail as it uses the name for the buffer name

#### Projects parameters

- `name`: Project name
- `description`: Project description
- `file_name`: Filename relative to root path
- `command`: Command to run the project. It is possible to use variables exactly the same as we would in `CRFiletype`

warning! : Avoid using all the parameters at the same time. The correct way to use them is shown in the example and described above.

### Queries

These functions could be useful if you intend to create plugins around code_runner, currently only the file type and current project commands can be accessed respectively

```lua
require("code_runner").get_filetype_command() -- get the current command for this filetype
require("code_runner").get_project_command() -- get the current command for this project
```

# Integration with other plugins

## Harpoon

you can directly integrate this plugin with [ThePrimeagen/harpoon](https://github.com/ThePrimeagen/harpoon) the way to do it is through command queries, harpoon allows the command to be sent to a terminal, below it is shown how to use harpoon term together with code_runner.nvim:

```vimscript
:lua require("harpoon.term").sendCommand(1, require("code_runner").get_filetype_command() .. "\n")
```

# Tip

For unknown reasons, leaving a comma in the trailing element in any json file causes an error when loading into lua, so you have to remove the trailing comma in the last item.

# Inspirations and thanks

- The idea of this project comes from the vscode plugin [code_runner](https://marketplace.visualstudio.com/items?itemName=formulahendry.code-runner) You can even copy your configuration and pass it to this plugin, as they are the same in the way of defining commands associated with [filetypes](https://github.com/CRAG666/code_runner.nvim#add-support-for-more-file-types)

- [jaq-nvim](https://github.com/is0n/jaq-nvim) some ideas of how to execute commands were taken from this plugin, thank you very much.

- [FTerm.nvim](https://github.com/numToStr/FTerm.nvim) Much of how this README.md is structured was blatantly stolen from this plugin, thank you very much

- Thanks to all current and future collaborators, without their contributions this plugin would not be what it is today

# Screenshots

![typescript](https://i.ibb.co/JCg3tNd/ezgif-com-video-to-gif.gif)

![python](https://i.ibb.co/1njTRTL/ezgif-com-video-to-gif.gif)

![Code_Runner](https://i.ibb.co/gFRhLgr/screen-1628272271.png "Code Runner with python")

# Contributing

Your help is needed to make this plugin the best of its kind, be free to contribute, criticize (don't be soft) or contribute ideas. All PR's are welcome.

## :warning: Important!

If you have any ideas to improve this project, do not hesitate to make a request, if problems arise, try to solve them and publish them. Don't be so picky I did this in one afternoon

# LICENCE

---

[MIT](https://github.com/CRAG666/code_runner.nvim/blob/main/LICENSE)
