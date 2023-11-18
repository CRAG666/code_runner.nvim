local o = require("code_runner.options")
local pattern = "crunner_"

-- Replace variables with full paths
---@param command string command to run the path
---@param path string absolute path
---@param user_argument table?
---@return string?
local function replaceVars(command, path, user_argument)
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
  command = command:gsub("$end", "")

  if command == no_sub_command then
    command = command .. " " .. path
  end

  return command
end

-- Check if current buffer is in project
-- if a project return table of project
---@return table?
local function getProjectRootPath()
  local projects = o.get().project
  local path = vim.fn.expand("%:p")
  for project_path, _ in pairs(projects) do
    path_full = vim.fs.normalize(project_path)
    if string.find(path, path_full) == 1 then
      current_proyect = projects[project_path]
      current_proyect["path"] = project_path
      return current_proyect
    end
  end
end

--- Return a command for filetype
---@param filetype string
---@param path string?
---@param user_argument table?
---@return string?
local function getCommand(filetype, path, user_argument)
  local opt = o.get()
  path = path or vim.fn.expand("%:p")
  local command = opt.filetype[filetype]
  if command then
    local command_vim = replaceVars(command, path, user_argument)
    return command_vim
  end
end

-- Run command in project context
---@param context table
---@return string?
local function getProjectCommand(context)
  local command = nil
  if context.file_name then
    local file = context.path .. "/" .. context.file_name
    if context.command then
      command = replaceVars(context.command, file)
    else
      -- Plenary version:
      -- https://github.com/CRAG666/code_runner.nvim/commit/825a0d5a450e269b450016b2a390026c68af3588
      local filetype = vim.filetype.match({ filename = file })
      command = getCommand(filetype, file)
    end
  else
    command = "cd " .. context.path .. " &&" .. context.command
  end
  return command
end

--- Close runner
---@param bufname string?
local function closeRunner(bufname)
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
  closeRunner(bufname)
  vim.cmd(prefix)
  vim.fn.termopen(command)
  vim.cmd("norm G")
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

btm_number = o.get().better_term.init
local function betterTermM(command)
  local opt = o.get().better_term
  local betterTerm_ok, betterTerm = pcall(require, "betterTerm")
  if betterTerm_ok then
    if opt.number == nil then
      btm_number = btm_number + 1
    else
      btm_number = opt.number
    end
    betterTerm.send(command, btm_number, { clean = opt.clean })
  end
end

local M = {}

-- Valid modes
M.modes = {
  term = function(command, bufname)
    execute(command, bufname)
  end,
  tab = function(command, bufname)
    execute(command, bufname, "tabnew")
  end,
  float = function(command, ...)
    local window = require("code_runner.floats")
    window.floating(command)
  end,
  better_term = function(command, ...)
    betterTermM(command)
  end,
  toggleterm = function(command, ...)
    local tcmd = string.format('TermExec cmd="%s"', command)
    vim.cmd(tcmd)
  end,
}
--- Run according to a mode
---@param command string
---@param bufname string
---@param mode string?
local function runMode(command, bufname, mode)
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

M.run_mode = runMode

-- Get command for the current filetype
function M.get_filetype_command()
  local filetype = vim.bo.filetype
  return getCommand(filetype) or ""
end

-- Get command for this current project
---@return table?
function M.get_project_command()
  local project_context = {}
  local opt = o.get()
  local context = nil
  if not vim.tbl_isempty(opt.project) then
    context = getProjectRootPath()
  end
  if context then
    project_context.command = getProjectCommand(context) or ""
    project_context.name = context.name
    project_context.mode = context.mode
    return project_context
  end
end

-- Execute current file
---@param mode string?
function M.run_filetype(mode)
  local command = M.get_filetype_command()
  if command ~= "" then
    o.get().before_run_filetype()
    runMode(command, vim.fn.expand("%:t:r"), mode)
  else
    local nvim_files = {
      lua = "luafile %",
      vim = "source %",
    }
    local cmd = nvim_files[vim.bo.filetype] or ""
    vim.cmd(cmd)
  end
end

--- Run a project associated with the current path
---@param mode string?
---@param notify boolean?
---@return boolean
function M.run_project(mode, notify)
  if notify == nil then
    notify = true
  end
  local project = M.get_project_command()
  if project then
    if not mode then
      mode = project.mode
    end
    runMode(project.command, project.name, mode)
    return true
  end
  if notify then
    vim.notify(":( There is no project associated with this path", vim.log.levels.INFO, { title = "Project" })
  end
  return false
end

-- Execute filetype or project
---@param filetype string?
---@param user_argument table?
function M.run_code(filetype, user_argument)
  if filetype ~= nil and filetype ~= "" then
    -- since we have reached here, means we have our command key
    local cmd_to_execute = getCommand(filetype, nil, user_argument)
    if cmd_to_execute then
      o.get().before_run_filetype()
      runMode(cmd_to_execute, vim.fn.expand("%:t:r"))
      return
    else
      -- command was a lua function with no output
      -- it already run
      return
    end
  end
  --  procede here if no input arguments
  local project = M.run_project(nil, false)
  if not project then
    M.run_filetype()
  end
end

--- Close current execution
function M.run_close()
  local context = getProjectRootPath()
  if context then
    closeRunner(pattern .. context.name)
  else
    closeRunner()
  end
end

return M
