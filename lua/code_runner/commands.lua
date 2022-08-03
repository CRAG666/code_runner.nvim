local o = require("code_runner.options")
local pattern = "crunner_"

-- Replace json variables with vim variables in command.
-- If a command has no arguments, one is added with the current file path
-- @param command command to run the path
-- @param path absolute path
-- @return command with variables replaced by modifiers
local function jsonVars_to_vimVars(command, path)

  if type(command) == "function" then
    command()
    return
  end

  local no_sub_command = command

  command = command:gsub("$fileNameWithoutExt", vim.fn.fnamemodify(path, ":t:r"))
  command = command:gsub("$fileName", vim.fn.fnamemodify(path, ":t"))
  command = command:gsub("$file", path)
  command = command:gsub("$dir", vim.fn.fnamemodify(path, ":p:h"))

  if command == no_sub_command then
    command = command .. " $fileName"
    command = command:gsub("$fileName", vim.fn.fnamemodify(path, ":t"))
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
  bufname = bufname or pattern .. vim.fn.expand("%:t:r")
  local current_buf = vim.fn.bufname("%")
  if string.find(current_buf, pattern) then
    vim.cmd("bwipeout!")
  else
    local bufid = vim.fn.bufnr(bufname)
    if bufid ~= -1 then
      vim.cmd("bwipeout!" .. bufid)
    end
  end
end

--- Execute comanda and create name buffer
---@param command comando a ejecutar
---@param bufname buffer name
-- @param hide not show output
local function execute(command, bufname, prefix)
  local opt = o.get()
  prefix = prefix or opt.prefix
  local set_bufname = "file " .. bufname
  local current_wind_id = vim.api.nvim_get_current_win()
  close_runner(bufname)
  vim.cmd(prefix .. " | term " .. command)
  vim.opt_local.relativenumber = false
  vim.opt_local.number = false
  vim.cmd(set_bufname)
  if prefix ~= "tabnew" then
    vim.bo.buflisted = false
  end
  if opt.focus then
    vim.cmd(opt.insert_prefix)
  else
    vim.fn.win_gotoid(current_wind_id)
  end
end

local function toggle(command, bufname)
  local bufid = vim.fn.bufnr(bufname)
  local buf_exist = vim.api.nvim_buf_is_valid(bufid)
  if buf_exist then
    local bufinfo = vim.fn.getbufinfo(bufid)[1]
    if bufinfo.hidden == 1 then
      local opt = o.get()
      vim.cmd(opt.prefix .. " | buffer " .. bufname)
    else
      local winid = bufinfo.windows[1]
      vim.fn.win_gotoid(winid)
      vim.cmd(":hide")
    end
  else
    execute(command, bufname)
  end
end

--- Run according to a mode
---@param command string
---@param bufname string
---@param mode string
local function run_mode(command, bufname, mode)
  local opt = o.get()
  mode = mode or opt.mode
  if mode == "" then
    mode = opt.mode
  end
  bufname = pattern .. bufname
  if mode == "float" then
    local window = require("code_runner.floats")
    window.floating(command)
  elseif mode == "toggle" then
    toggle(command, bufname)
  elseif mode == "tab" then
    execute(command, bufname, "tabnew")
  elseif mode == "term" then
    execute(command, bufname)
  elseif mode == "toggleterm" then
    local tcmd = string.format('TermExec cmd="%s"', command)
    vim.cmd(tcmd)
    vim.cmd(opt.insert_prefix)
  elseif mode == "buf" then
    execute(command, bufname, "bufdo")
  else
    vim.notify(
      ":( mode not found, valid modes term, tab, float, toggle, buf",
      vim.log.levels.INFO,
      { title = "Project" }
    )
  end
end

local M = {}

-- Get command for the current filetype
function M.get_filetype_command()
  local filetype = vim.bo.filetype
  return get_command(filetype) or ""
end

-- Get command for this current project
---@return table or nil
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
  local command = M.get_filetype_command()
  if command ~= "" then
    run_mode(command, vim.fn.expand("%:t:r"), mode)
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
  local project = M.get_project_command()
  if project then
    run_mode(project.command, project.name, mode)
  else
    vim.notify(
      "Not a project context",
      vim.log.levels.INFO,
      { title = "Project" }
    )
  end
end

-- Execute filetype or project
function M.run_code(filetype)
  if filetype ~= "" then
    -- since we have reached here, means we have our command key
    local cmd_to_execute = get_command(filetype)
    if cmd_to_execute then
      run_mode(cmd_to_execute, vim.fn.expand("%:t:r"))
    end
  end

  --  procede here if no input arguments
  local project = M.get_project_command()
  if project then
    run_mode(project.command, project.name)
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
