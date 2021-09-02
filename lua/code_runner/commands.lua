-- Import options
local o = require("code_runner.options")

-- Create prefix for run commands
local prefix = string.format("%s %dsplit term://", o.get().term.position, o.get().term.size)

--[[ -- Return dir path, File name and extension starting from File path
local function split_filename(file_path)
  file_path = file_path .. "."
  return file_path:match("^(.-)([^\\/]-%.([^\\/%.]-))%.?$")
end --]]

-- Create file modifiers
local function filename_modifiers(path, modifiers)
	if path == "%%" then
		return path .. modifiers
	end
	return vim.fn.fnamemodify(path, modifiers)
end


-- Substitute json vars to vim vars in commands for each file type.
-- If a command has no arguments, one is added with the current file path
	--[[ local dir, fileName, ext = split_filename(path)
	local vars_json = {
		["%$fileNameWithoutExt"] = string.gsub(path, "." .. ext, ""),
		["$fileName"] = fileName,
		["$file"] = path,
		["$dir"] = dir
	} --]]
local function sub_var_command(command, path)
	local no_sub_command = command
	local vars_json = {
		["%$fileNameWithoutExt"] = filename_modifiers(path, ":t:r"),
		["$fileName"] = filename_modifiers(path, ":t"),
		["$file"] = path,
		["$dir"] = filename_modifiers(path, ":p:h")
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
		expand = vim.fn.expand(path)
		local project = vim.g.projectManager[expand]
		if project then
			project["path"] = expand
			return project
		end
		path = path .. ":h"
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


-- Run command in project context
local function run_command_context(context)
		local command = ""
		if context.file_name then
			local file = context.path .. "/" .. context.file_name
			if context.command then
					command = prefix .. sub_var_command(context.command, file)
			else
					command = get_command(context.filetype, file)
			end
		else
			command = prefix .. "cd " .. context.path .. context.command
		end
		vim.cmd(command)
end


local M = {}

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
			command = get_command(filetype) or ""
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
