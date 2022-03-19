local o = require("code_runner.options")
local pattern = "crunner_"

-- Replace json variables with vim variables in command.
-- If a command has no arguments, one is added with the current file path
-- @param command command to run the path
-- @param path absolute path
-- @return command with variables replaced by modifiers
local function jsonVars_to_vimVars(command, path)
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
  local path = vim.loop.cwd()
  local home_path = vim.fn.expand("~")
  while path ~= home_path do
    local project = opt.project[path] or opt.project[vim.fn.fnamemodify(path, ":~")]
    if project then
      project["path"] = path
      return project
    end
    path = vim.fn.fnamemodify(path, ":h")
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
    local command_vim = jsonVars_to_vimVars(command, path)
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
      command = jsonVars_to_vimVars(context.command, file)
    else
      local filetype = require("plenary.filetype")
      local current_filetype = filetype.detect_from_extension(file)
      command = get_command(current_filetype, file)
    end
  else
    command = "cd " .. context.path .. " &&" .. context.command
  end
  return command
end

local function close_runner(bufname)
  bufname = bufname or vim.fn.expand("%:t:r")
  if string.find(vim.fn.bufname("%"), pattern) then
    vim.cmd("bwipeout!")
  else
    local bufname = pattern .. bufname
    local i = vim.fn.bufnr("$")
    while i >= 1 do
      if vim.fn.bufname(i) == bufname then
        vim.cmd("bwipeout!" .. i)
        break
      end
      i = i - 1
    end
  end
end

--- Execute comanda and create name buffer
---@param command comando a ejecutar
---@param bufname buffer name
local function execute(command, bufname)
  bufname = bufname or vim.fn.expand("%:t:r")
  local opt = o.get()
  local set_bufname = "file " .. pattern .. bufname
  close_runner(bufname)
  vim.cmd(opt.prefix .. command)
  vim.cmd(set_bufname)
  vim.cmd(opt.term.mode)
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
      vim = "source %",
    }
    local cmd = nvim_files[vim.bo.filetype] or ""
    vim.cmd(cmd)
  end
end

-- Get command for this current project
---@return project_context or nil
function M.get_project_command()
  local project_context = {}
  local opt = o.get()
  local context = nil
  if vim.tbl_isempty(opt.project) then
    context = get_project_rootpath()
  end
  if context then
    project_context.command = get_project_command(context) or ""
    project_context.name = context.name
    return project_context
  end
  return nil
end

-- Execute project
function M.run_project()
  local project = M.get_project_command()
  if project then
    execute(project.command, project.name)
  end
end

-- Execute filetype or project
function M.run(...)
  local json_key_select = select(1, ...)
  if json_key_select ~= "" then
    -- since we have reached here, means we have our command key
    local cmd_to_execute = get_command(json_key_select)
    if cmd_to_execute then
      execute(cmd_to_execute, json_key_select)
    end
  end

  --  procede here if no input arguments
  local project = M.get_project_command()
  if project then
    execute(project.command, project.name)
  else
    M.run_filetype()
  end
end

function M.run_close()
  local context = get_project_rootpath()
  if context then
    close_runner(context.name)
  else
    close_runner()
  end
end

return M
