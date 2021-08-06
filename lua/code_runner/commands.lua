local o = require("code_runner.options")
-- load json config and convert to table
local loadTable = require("code_runner.load_json")
local fileCommands = loadTable()

-- if json file not exists return null
if not fileCommands then
	return
end

-- Create prefix for run commands
local prefix = string.format("%s %dsplit term://", o.get().term.position, o.get().term.size)
local suffix = "<CR>"

-- Create autocmd for each file type and add map for ececute file type
local function shellcmd(lang, command)
	vim.cmd ("autocmd FileType " .. lang .. " nnoremap <buffer> " .. o.get().map .. " :" .. prefix .. "" .. command .. suffix)
end

local function vimcmd(lang, config)
	vim.cmd ("autocmd FileType " .. lang .. " nnoremap <buffer> " .. o.get().map .. " :" .. config .. "<CR>")
end

-- Substitute json vars to vim vars in commands for each file type.
-- If a command has no arguments, one is added with the current file path
local function subvarcomm(command)
	local vars_json = {
		["%$fileNameWithoutExt"] = "%%:r",
		["$fileName"] = "%%:t",
		["$file"] = "%%",
		["$dir"] = "%%:p:h"
	}
	for var, var_vim in pairs(vars_json) do
		command = command:gsub(var, var_vim)
	end
	if not command:find("%%") then
		command = command .. " %"
	end
	return command
end

-- call subvarcomm and shellcmd
function run()
	for lang, command in pairs(fileCommands) do
		command_vim = subvarcomm(command)
		shellcmd(lang, command_vim)
	end
	-- vimcmd("markdown", defaults.commands.markdown)
	vimcmd("vim", "source %")
	vimcmd("lua", "luafile %")
end
return run
