local o = require("code_runner.options")
local window = require("code_runner.floats")
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
  if not vim.tbl_isempty(vim.g.runners) then
    bufname = bufname or vim.fn.expand("%:t:r")
    local current_buf = vim.fn.bufname("%")
    if string.find(current_buf, pattern) then
      vim.g.runners[current_buf] = nil
      vim.cmd("bwipeout!")
    else
      vim.cmd("bwipeout!" .. vim.g.runners[bufname]["buffer"])
      vim.g.runners[bufname] = nil
    end
  end
end

--- Execute comanda and create name buffer
---@param command comando a ejecutar
---@param bufname buffer name
-- @param hide not show output
local function execute(command, bufname, hide)
  hide = hide or false
  local opt = o.get()
  local set_bufname = "file " .. pattern .. bufname
  close_runner(bufname)
  vim.cmd(opt.prefix .. command)
  vim.cmd(set_bufname)
  vim.g.runners[bufname] = {
    ["id"] = vim.fn.win_getid(),
    ["buffer"] = vim.fn.bufnr("%"),
    ["hide"] = hide,
  }
  vim.cmd(opt.insert_prefix)
  vim.cmd(hide and "hide" or "")
end

local function toggle(command, bufname)
  local opt = o.get()
  local exits = vim.g.runners[bufname]
  local hide = vim.g.runners[bufname]["hide"]
  if exits then
    if hide then
      local prefix = string.format("%s %d new | ", opt.term.position, opt.term.size)
      if opt.term.tab then
        prefix = "tabnew | "
      end
      vim.g.runners[bufname]["hide"] = false
      vim.cmd(prefix .. "buffer " .. pattern .. vim.g.runners[bufname]["id"])
    else
      vim.g.runners[bufname]["hide"] = true
      vim.fn.win_gotoid(vim.g.runners[bufname]["id"])
      vim.cmd("hide")
    end
  else
    execute(command, bufname)
  end
end

-- Create prefix for run commands
local M = {}

-- Get command for the current filetype
function M.get_filetype_command()
  local filetype = vim.bo.filetype
  return get_command(filetype) or ""
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

-- Execute filetype
function M.run_filetype(mode)
  mode = mode or ""
  local command = M.get_filetype_command()
  local bufname = vim.fn.expand("%:t:r")
  if command ~= "" then
    if mode == "float" then
      window.float(command)
    elseif mode == "toggle" then
      toggle(command, bufname)
    else
      execute(command, bufname)
    end
  else
    local nvim_files = {
      lua = "luafile %",
      vim = "source %",
    }
    local cmd = nvim_files[vim.bo.filetype] or ""
    vim.cmd(cmd)
  end
end

-- Execute project
function M.run_project(mode)
  mode = mode or ""
  local project = M.get_project_command()
  if project then
    if mode == "float" then
      window.float(project.command)
    elseif mode == "toggle" then
      toggle(project.command, project.name)
    else
      execute(project.command, project.name)
    end
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
