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
  if not vim.tbl_isempty(require("code_runner.commands").runners) then
    bufname = bufname or pattern .. vim.fn.expand("%:t:r")
    local current_buf = vim.fn.bufname("%")
    if string.find(current_buf, pattern) then
      require("code_runner.commands").runners[current_buf] = nil
      vim.cmd("bwipeout!")
    else
      local exist = require("code_runner.commands").runners[bufname]
      if exist then
        local temp_buf = exist["buffer"]
        if vim.fn.bufexists(temp_buf) == 1 then
          vim.cmd("bwipeout!" .. temp_buf)
        end
      end
      require("code_runner.commands").runners[bufname] = nil
    end
  end
end

--- Execute comanda and create name buffer
---@param command comando a ejecutar
---@param bufname buffer name
-- @param hide not show output
local function execute(command, bufname)
  local opt = o.get()
  local set_bufname = "file " .. bufname
  close_runner(bufname)
  vim.cmd(opt.prefix .. " | term " .. command)
  require("code_runner.commands").runners[bufname] = {
    ["id"] = vim.fn.win_getid(),
    ["buffer"] = vim.fn.bufnr("%"),
    ["hide"] = false,
  }
  vim.cmd(set_bufname)
  vim.cmd(opt.insert_prefix)
end

local function toggle(command, bufname)
  local opt = o.get()
  local exist = require("code_runner.commands").runners[bufname]
  if exist then
    vim.pretty_print("Toggle " .. bufname .. "....")
    local is_hide = exist["hide"]
    if is_hide then
      vim.cmd(opt.prefix .. " | buffer " .. bufname)
      require("code_runner.commands").runners[bufname]["id"] = vim.fn.win_getid()
      require("code_runner.commands").runners[bufname]["hide"] = false
    else
      vim.fn.win_gotoid(exist["id"])
      require("code_runner.commands").runners[bufname]["hide"] = true
      vim.cmd(":hide")
    end
  else
    execute(command, bufname)
  end
end

-- Create prefix for run commands
local M = {}
M.runners = {}

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
  if not vim.tbl_isempty(opt.project) then
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
  local bufname = pattern .. vim.fn.expand("%:t:r")
  if command ~= "" then
    if mode == "float" then
      window.floating(command)
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
  local bufname = pattern .. project.name
  if project then
    if mode == "float" then
      window.floating(project.command)
    elseif mode == "toggle" then
      toggle(project.command, bufname)
    else
      execute(project.command, bufname)
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
    close_runner(pattern .. context.name)
  else
    close_runner()
  end
end

return M
