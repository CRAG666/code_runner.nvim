-- import options
local o = require("code_runner.options")

-- Create prefix for run commands
local prefix = string.format("%s %dsplit term://", o.get().term.position, o.get().term.size)

-- Substitute json vars to vim vars in commands for each file type.
-- If a command has no arguments, one is added with the current file path
local function sub_var_command(command, path)
	local no_sub_command = command
	local vars_json = {
		["%$fileNameWithoutExt"] = path .. ":r",
		["$fileName"] = path .. ":t",
		["$file"] = path,
		["$dir"] = path .. ":p:h"
	}
	for var, var_vim in pairs(vars_json) do
		command = command:gsub(var, var_vim)
	end
	if command == no_sub_command then
		if path == "%%" then path = "%" end
		command = command .. " " .. path
	end
	return command
end


-- Check if current buffer is in project context
-- if a project context return table of project
local function get_context()
	local path = "%:p:~:h"
	local expand = ""
	while expand ~= "~" do
		path = path .. ":h"
		expand = vim.fn.expand(path)
		local project = vim.g.projectManager[expand]
		if project then
			project["path"] = expand
			return project
		end
	end
	return nil
end

-- Return a command for filetype
local function get_command(filetype, path)
	path = path or "%%"
	local command = vim.g.fileCommands[filetype]
	if command then
		local command_vim = sub_var_command(command, path)
		return prefix .. command_vim
	end
	return nil
end

local M = {}

local function run_command_context(context)
		local command = ""
		local file = context.path .. "/" .. context.file_name
		if context.command then
				command = context.command .. " " .. file
		else
				command = get_command(context.filetype, file)
		end
		vim.cmd(command)
end

-- Execute filetype or project
function M.run()
	local context = get_context()
	if context then
		run_command_context(context)
	else
		M.run_filetype()
	end
end


-- Execute filetype
function M.run_filetype()
		local filetype = vim.bo.filetype
		local command = ""
		if filetype == "lua" then
			command = "luafile %"
		elseif filetype == "vim" then
			command = "source %"
		else
			command = get_command(filetype)
		end
		vim.cmd(command)
	end


-- Execute project
function M.run_project()
	local context = get_context()
	if context then
		run_command_context(context)
	end
end

return M
