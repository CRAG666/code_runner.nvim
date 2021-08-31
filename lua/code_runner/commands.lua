local o = require("code_runner.options")

-- Create prefix for run commands
local prefix = string.format("%s %dsplit term://", o.get().term.position, o.get().term.size)

-- Substitute json vars to vim vars in commands for each file type.
-- If a command has no arguments, one is added with the current file path
local function sub_var_command(command, path)
	local vars_json = {
		["%$fileNameWithoutExt"] = path .. ":r",
		["$fileName"] = path .. ":t",
		["$file"] = path,
		["$dir"] = path .. ":p:h"
	}
	for var, var_vim in pairs(vars_json) do
		command = command:gsub(var, var_vim)
	end
	if not command:find(path) then
		if path == "%%" then
			path = " %"
		end
		command = command .. path
	end
	return command
end


local function get_context()
	local path = vim.fn.expand("%")
	while path ~= "/" do
		path = path:gsub("[^\\]+\\?$", "")
		local project = vim.g.projectManager[path]
		if project then
			project["path"] = path
			return project
		end
	end
	return nil
end


local function get_command(filetype, path)
	path = path or "%%"
	local command = vim.g.fileCommands[filetype]
	if command then
		local command_vim = sub_var_command(command)
		return prefix .. command_vim
	end
	return ""
end

local M = {}

-- Create shellcmd
function M.run()
	local context = get_context()
	if context then
		vim.cmd(get_command(context.filetype, context.path .. context.file_name))
	else
		vim.cmd(get_command(vim.bo.filetype))
	end
	-- vimcmd("markdown", defaults.commands.markdown)
	-- vimcmd("vim", "source %")
	-- vimcmd("lua", "luafile %")
end


function M.run_filetype()
		vim.cmd(get_command(vim.bo.filetype))
	end


function M.run_project()
	local context = get_context()
	if context then
		vim.cmd(get_command(context.filetype, context.path .. context.file_name))
	end
end

return M
