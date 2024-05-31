local o = require("code_runner.options")
local cr_bufname_prefix = "crunner_"
local au_cd = require("code_runner.hooks.autocmd")

local M = {}

-- util functions {{{
-- Replace variables with full paths
---@param command (string| table | function) command to run the path
---@param path string absolute path
---@param user_argument? table
---@return string|nil
local function replaceVars(command, path, user_argument)
  if type(command) == "function" then
    local cmd = command(user_argument)
    if type(cmd) == "string" then
      command = cmd
    elseif type(cmd) == "table" then
      command = table.concat(cmd, " ")
    else
      return
    end
  end

  -- command is of type string
  ---@cast command string
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
---@return table|nil project
local function getProjectRootPath()
  local projects = o.get().project
  local file_path = vim.fn.expand("%:p")
  for project_path, _ in pairs(projects) do
    local path_full = vim.fs.normalize(project_path)
    local path_start, path_end = string.find(file_path, path_full)
    if path_start == 1 then
      local current_project = projects[project_path]
      current_project["path"] = string.sub(file_path, path_start, path_end)
      return current_project
    end
  end
end

--- Return a command for filetype
---@param filetype string|nil
---@param path? string
---@param user_argument? table
---@return string?
local function getCommand(filetype, path, user_argument)
  local opt = o.get()
  path = path or vim.fn.expand("%:p")
  local command = opt.filetype[filetype]
  if command == nil or command == "" then
    vim.notify(
      string.format("Can't execute filetype/cmd: %s, check your opts/config", filetype),
      vim.log.levels.WARN,
      { title = "Code Runner (plugin)" }
    )
  else
    local command_vim = replaceVars(command, path, user_argument)
    return command_vim
  end
end

-- Run command in project context
---@param context table
---@return string|nil
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
---@param bufname? string
local function closeRunner(bufname)
  bufname = bufname or cr_bufname_prefix .. vim.fn.expand("%:t:r")

  local current_buf = vim.fn.bufname("%")
  if string.find(current_buf, cr_bufname_prefix) then
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
---@param bufname_prefix? string
local function execute(command, bufname, bufname_prefix)
  local opt = o.get()

  local fn = function()
    bufname_prefix = bufname_prefix or opt.prefix
    local set_bufname = "file " .. bufname
    local current_wind_id = vim.api.nvim_get_current_win()
    closeRunner(bufname)
    vim.cmd(bufname_prefix)
    vim.fn.termopen(command)
    vim.cmd("norm G")
    vim.opt_local.relativenumber = false
    vim.opt_local.number = false
    vim.cmd(set_bufname)
    vim.api.nvim_set_option_value("filetype", "crunner", { buf = 0 })
    if bufname_prefix ~= "tabnew" then
      vim.bo.buflisted = false
    end
    if opt.focus then
      vim.cmd(opt.insert_prefix)
    else
      vim.fn.win_gotoid(current_wind_id)
    end
  end

  fn()

  if opt.hot_reload then
    au_cd.stop_job()
    au_cd.create_au_write(fn)
  end
end

--Execute the selected lines by filetype, display_mode, bufname
---@param lines string
---@param display_mode? CodeRunnerDisplayMode
---@param ft? string
---@param bufname? string
---@return nil
local function executeRange(lines, ft, display_mode, bufname)
  lines = lines:gsub("'", "'\\''")
  local current_filetype = ft or vim.bo.ft
  local cmd = ""
  if current_filetype == "python" then
    cmd = string.format("python -c '%s'", lines)
  elseif current_filetype == "typescript" or current_filetype == "javascript" then
    cmd = string.format("bun -e '%s'", lines)
  elseif current_filetype == "clojure" then
    cmd = string.format("clojure -M -e '%s'", lines)
    -- cmd = string.format("node -e '%s'", lines)
    --NOTE: this could be better there are some similarities for the below repl languages
    -- maybe call getCommand and inject it in string.format() of some similar idea
  elseif current_filetype == "lua" then
    cmd = string.format("lua -e '%s'", lines)
  elseif current_filetype == "ruby" then
    cmd = string.format("ruby -e '%s'", lines)
  elseif current_filetype == "elixir" then
    cmd = string.format("elixir -e '%s'", lines)
  else
    vim.notify("Sorry not supported for this filetype", vim.log.levels.INFO, { title = "Code Runner (plugin)" })
  end

  -- execute(cmd, bufname, "tabnew")
  display_mode = display_mode or o.get().mode
  local displayer = M.display_modes[display_mode]
  bufname = bufname or cr_bufname_prefix .. vim.fn.expand("%:t:r")
  displayer(cmd, bufname)
end

-- get the select line range
---@return string|nil
local function getTextFromRange(opts)
  if opts and opts.range ~= 0 then
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" then
      -- :h getpos()
      local start_pos = vim.fn.getpos("'<") --> [bufnum, lnum, col, off]
      local end_pos = vim.fn.getpos("'>") --> [bufnum, lnum, col, off]
      if end_pos[3] == vim.v.maxcol then -- when mode is "V" the col of '> is v:maxcol
        end_pos[3] = vim.fn.col("'>") - 1
      end
      return table.concat(
        vim.api.nvim_buf_get_text(0, start_pos[2] - 1, start_pos[3] - 1, end_pos[2] - 1, end_pos[3], {}),
        "\n"
      )
    elseif mode == "n" then
      return table.concat(vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false), "\n")
    end
  end
end

--External plugin
local btm_number = o.get().better_term.init
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
-- }}}

-- Valid display modes
---@class (exact) CodeRunnerDisplayModes
---@field term function
---@field tab function
---@field float function
---@field better_term function
---@field toggleterm function
M.display_modes = {
  term = function(command, bufname)
    execute(command, bufname)
  end,
  tab = function(command, bufname)
    execute(command, bufname, "tabnew")
  end,
  float = function(command, _)
    local window = require("code_runner.floats")
    window.floating(command)
  end,
  --External plugin required
  better_term = function(command, _)
    betterTermM(command)
  end,
  --External plugin required
  toggleterm = function(command, _)
    local tcmd = string.format('TermExec cmd="%s"', command)
    vim.cmd(tcmd)
  end,
}

--- Run according to a display mode
---@param command string
---@param bufname string
---@param display_mode? CodeRunnerDisplayMode
local function getDisplayMode(command, bufname, display_mode)
  local opt = o.get()
  display_mode = display_mode or opt.mode
  if display_mode == "" then
    display_mode = opt.mode
  elseif display_mode == "better_term" and vim.fn.exepath("better_term") == "" then
    return vim.notify(
      "external plugin required: https://github.com/CRAG666/betterTerm.nvim\nplease install it, to properly enable this display mode.",
      vim.log.levels.WARN,
      { title = "Code Runner (plugin) config" }
    )
  elseif display_mode == "toggleterm" and vim.fn.exepath("toggleterm") == "" then
    return vim.notify(
      "external plugin required: https://github.com/akinsho/toggleterm.nvim\nplease install it, to properly enable this display mode.",
      vim.log.levels.WARN,
      { title = "Code Runner (plugin) config" }
    )
  end
  local call_mode = M.display_modes[display_mode]
  if call_mode == nil then
    vim.notify(
      string.format(
        "Invalid display mode: %s, set one of these valid modes: {'term', 'float', 'tab', 'better_term', 'toggleterm'}.\
        :h code_runner_settings-mode",
        display_mode
      ),
      vim.log.levels.WARN,
      { title = "Code Runner (plugin) config:" }
    )
    return
  end
  bufname = cr_bufname_prefix .. bufname
  call_mode(command, bufname)
end

function M.run_from_fn(cmd)
  local command = nil
  if type(cmd) == "string" then
    command = cmd
  elseif type(cmd) == "table" then
    command = table.concat(cmd, " ")
  end
  local path = vim.fn.expand("%:p")
  local command_vim = replaceVars(command, path)
  getDisplayMode(command_vim --[[@as string]], vim.fn.expand("%:t:r"))
end

-- Get command for the current filetype
function M.get_filetype_command()
  local filetype = vim.bo.filetype
  return getCommand(filetype) or ""
end

-- Get command for the current project
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

-- Execute current file with the specified display mode
-- if called without argument uses the default display mode
---@param display_mode? CodeRunnerDisplayMode
---@param opts? table
function M.run_current_file(display_mode, opts)
  local code_range = getTextFromRange(opts)
  if code_range then
    return executeRange(code_range, nil, display_mode)
  end
  local command = M.get_filetype_command()
  if command ~= "" then
    o.get().before_run_filetype() --write buffer
    getDisplayMode(command, vim.fn.expand("%:t:r"), display_mode)
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
---@param display_mode? CodeRunnerDisplayMode
---@param notify? boolean
---@return boolean
function M.run_project(display_mode, notify)
  if notify == nil then
    notify = true
  end
  if notify then
    vim.notify(
      ":( There is no project associated with this path",
      vim.log.levels.INFO,
      { title = "Code Runner plugin" }
    )
  end
  local project = M.get_project_command()
  if project then
    if not display_mode then
      display_mode = project.mode
    end
    getDisplayMode(project.command, project.name, display_mode)
    return true
  end
  return false
end

-- Execute filetype or project
---@param filetype? string
---@param user_argument? table
function M.run_code(filetype, user_argument)
  local code_range = getTextFromRange(user_argument)
  if code_range then
    return executeRange(code_range, filetype)
  end
  if filetype ~= nil and filetype ~= "" then
    -- since we have reached here, means we have our command key
    local cmd_to_execute = getCommand(filetype, nil, user_argument)
    if cmd_to_execute then
      o.get().before_run_filetype() --write buffer
      getDisplayMode(cmd_to_execute, vim.fn.expand("%:t:r"))
      return
    else
      -- command was a lua function with no output
      -- it already run
      return
    end
  end
  --  procure here if no input arguments
  local project = M.run_project(nil, false)
  if not project then
    M.run_current_file()
  end
end

--- Close current execution window/viewport
function M.close_current_execution()
  local context = getProjectRootPath()
  if context then
    closeRunner(cr_bufname_prefix .. context.name)
  else
    closeRunner()
  end
  au_cd.stop_job() -- stop auto_cmd
end

return M
