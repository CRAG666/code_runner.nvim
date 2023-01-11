local o = require("code_runner.options")
local pattern = "crunner_"

--Replace json variables with vim variables in command.
---@param command string command to run the path
---@param path string absolute path
---@param user_argument table?
---@return string?
local function jsonVars_to_vimVars(command, path, user_argument)
  if type(command) == "function" then
    local cmd = command(user_argument)
    if type(cmd) == "string" then
      command = cmd
    else
      return
    end
  end

  -- command is of type string

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
---@return table?
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
end

-- Return a command for filetype
-- @param filetype filetype of path
-- @param path absolute path to file
-- @return command
--- Return a command for filetype
---@param filetype string
---@param path string?
---@param user_argument table?
---@return string?
local function get_command(filetype, path, user_argument)
  local opt = o.get()
  path = path or vim.fn.expand("%:p")
  local command = opt.filetype[filetype]
  if command then
    local command_vim = jsonVars_to_vimVars(command, path, user_argument)
    return command_vim
  end
end

-- Run command in project context
---@param context table
---@return string?
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

--- Close runner
---@param bufname string?
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

--- Execute command and create name buffer
---@param command string
---@param bufname string
---@param prefix string?
local function execute(command, bufname, prefix)
  local opt = o.get()
  prefix = prefix or opt.prefix
  local set_bufname = "file " .. bufname
  local current_wind_id = vim.api.nvim_get_current_win()
  close_runner(bufname)
  if prefix ~= "bufdo" then
    prefix = prefix .. " |"
  end
  vim.cmd(prefix .. " term " .. command)
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

--- Toggle mode
---@param command string
---@param bufname string
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

local M = {}

-- Valid modes
M.modes = {
  local opt = o.get()
  term = function(command, bufname)
    execute(command, bufname)
  end,
  toggle = function(command, bufname)
    toggle(command, bufname)
  end,
  float = function(command, ...)
    local window = require("code_runner.floats")
    window.floating(command)
  end,
  tab = function(command, bufname)
    execute(command, bufname, "tabnew")
  end,
  buf = function(command, bufname)
    execute(command, bufname, "bufdo")
  end,
  toggleterm = function(command, ...)
    local tcmd = string.format('TermExec cmd="%s"', command)
    vim.cmd(tcmd)
    vim.cmd(opt.insert_prefix)
  end,
}
--- Run according to a mode
---@param command string
---@param bufname string
---@param mode string?
local function run_mode(command, bufname, mode)
  local opt = o.get()
  mode = mode or opt.mode
  if mode == "" then
    mode = opt.mode
  end
  bufname = pattern .. bufname
  local call_mode = M.modes[mode]
  if call_mode == nil then
    vim.notify(":( mode not found, Select valid mode", vim.log.levels.INFO, { title = "Project" })
    return
  end
  call_mode(command, bufname)
end

--- Run according to a mode
---@param command string
---@param bufname string
---@param mode string
function M.run_mode(command, bufname, mode)
  run_mode(command, bufname, mode)
end

-- Get command for the current filetype
function M.get_filetype_command()
  local filetype = vim.bo.filetype
  return get_command(filetype) or ""
end

-- Get command for this current project
---@return table?
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
end

-- Execute current file
---@param mode string?
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

-- Execute filetype or project
---@param filetype string?
---@param user_argument table?
function M.run_code(filetype, user_argument)
  if filetype ~= nil and filetype ~= "" then
    -- since we have reached here, means we have our command key
    local cmd_to_execute = get_command(filetype, nil, user_argument)
    if cmd_to_execute then
      run_mode(cmd_to_execute, vim.fn.expand("%:t:r"))
    else
      -- command was a lua function with no output
      -- it already run
      return
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

--- Run a project associated with the current path
---@param mode string?
function M.run_project(mode)
  local project = M.get_project_command()
  if project then
    run_mode(project.command, project.name, mode)
  end
  vim.notify(":( There is no project associated with this path", vim.log.levels.INFO, { title = "Project" })
end

--- Close current execution
function M.run_close()
  local context = get_project_rootpath()
  if context then
    close_runner(pattern .. context.name)
  else
    close_runner()
  end
end
return M
