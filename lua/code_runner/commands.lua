local o = require("code_runner.options")

-- Replace json variables with vim variables in command.
-- If a command has no arguments, one is added with the current file path
-- @param command command to run the path
-- @param path absolute path
-- @return command with variables replaced by modifiers
local function re_jsonvar_with_vimvar(command, path)
	local no_sub_command = command

	command = command:gsub("$fileNameWithoutExt", vim.fn.fnamemodify(path, ":t:r"))
	command = command:gsub("$fileName", vim.fn.fnamemodify(path, ":t"))
	command = command:gsub("$file", path)
	command = command:gsub("$dir", vim.fn.fnamemodify(path, ":p:h"))

	if command == no_sub_command then
		command = command .. " " .. path
	end
	return command
end

-- Check if current buffer is in project
-- if a project return table of project
local function get_project_rootpath()
	local opt = o.get()
	local path = "%:p:~:h"
	local expand = ""
	while expand ~= "~" do
		expand = vim.fn.expand(path)
		local project = opt.project[expand]
		if project then
			project["path"] = expand
			return project
		end
		path = path .. ":h"
	end
	return nil
end

-- Return a command for filetype
-- @param filetype filetype of path
-- @param path absolute path to file
-- @return command
local function get_command(filetype, path)
	local opt = o.get()
	path = path or vim.fn.expand("%:p")
	local command = opt.filetype[filetype]
	if command then
		local command_vim = re_jsonvar_with_vimvar(command, path)
		return command_vim
	end
	return nil
end

-- Run command in project context
local function get_project_command(context)
	local command = nil
	if context.file_name then
		local file = context.path .. "/" .. context.file_name
		if context.command then
			command = re_jsonvar_with_vimvar(context.command, file)
		else
			local filetype = require'plenary.filetype'
			local current_filetype = filetype.detect_from_extension(file)
			command = get_command(current_filetype, file)
		end
	else
		command = "cd " .. context.path .. " &&" .. context.command
	end
	return command
end

local function execute(command, project)
	project = project or false
	local opt = o.get()
	local bufname = "| :file code_runner-%:t"
	vim.cmd(opt.prefix .. command .. bufname .. opt.term.mode)
end


-- Create prefix for run commands
local M = {}

-- Get command for the current filetype
function M.get_filetype_command()
	local filetype = vim.bo.filetype
	return get_command(filetype) or ""
end

-- Execute filetype
function M.run_filetype()
	local command = M.get_filetype_command()
	if command ~= "" then
		execute(command)
	else
		local nvim_files = {
			lua = "luafile %",
			vim = "source %"
		}
		vim.cmd(nvim_files[vim.bo.filetype])
	end
end

-- Get command for this current project
function M.get_project_command()
	local opt = o.get()
	local context = nil
	local next = next
	if next(opt.project or {}) ~= nil then
		context = get_project_rootpath()
	end
	if context then
		return get_project_command(context) or ""
	end
	return ""
end

-- Check if is a project
local function is_a_project()
	local command = M.get_project_command()
	if command ~= "" then
		return command
	end
	return nil
end

-- Execute project
function M.run_project()
	local command = is_a_project()
	if command then
		execute(command, true)
	end
end

-- Execute filetype or project
function M.run(...)
	local json_key_select = select(1,...)
	if json_key_select ~= "" then
		-- since we have reached here, means we have our command key
		local cmd_to_execute = get_command(json_key_select)
		if cmd_to_execute then
			execute(cmd_to_execute)
		end
		return
	end
	--  procede here if no input arguments
	local project = is_a_project()
	if project then
		execute(project, true)
	else
		M.run_filetype()
	end
end

--- Reload commands
function M.run_reload()
	local pattern = "code_runner-"
	if string.find(vim.fn.bufname("%"), pattern) then
		vim.cmd("bwipeout!")
		print("reload current runner")
		M.run()
	else
		local bufname = pattern .. vim.fn.expand("%:t")
		local i = vim.fn.bufnr("$")
		while (i >= 1)
		do
			if (vim.fn.bufname(i) == bufname) then
				vim.cmd("bwipeout!" .. i)
				print("reload runner" .. bufname)
				M.run()
				break
			end
			i = i - 1
		end
	end
end

return M
