local commands = require("code_runner.commands")
local o = require("code_runner.options")
local M = {}

M.run_code = commands.run
M.run_filetype = commands.run_filetype
M.run_project = commands.run_project
M.run_close = commands.run_close
M.get_filetype_command = commands.get_filetype_command
M.get_project_command = commands.get_project_command

local function open_json(json_path)
  local command = "tabnew " .. json_path
  vim.cmd(command)
end

M.open_filetype_suported = function()
  open_json(o.get().filetype_path)
end

M.open_project_manager = function()
  open_json(o.get().project_path)
end

local function load_runners()
  -- Load json config and convert to table
  local opt = o.get()
  local load_json_as_table = require("code_runner.load_json")

  -- convert json filetype as table lua
  if vim.tbl_isempty(opt.filetype) then
    opt.filetype = load_json_as_table(opt.filetype_path)
  end

  -- convert json project as table lua
  if vim.tbl_isempty(opt.project) then
    opt.project = load_json_as_table(opt.project_path)
  end

  -- Message if json file not exist
  if vim.tbl_isempty(opt.filetype) then
    vim.notify(
    "Not exist command for filetypes or format invalid, if use json please execute :CRFiletype or if use lua edit setup",
    vim.log.levels.ERROR,
    { title = "Code Runner Error" }
    )
  end
end

local function completion(ArgLead, options)
  local filterd_args = vim.tbl_filter(function(v) return v:find(ArgLead:lower(), 1, true) == 1 end, options)
  if not vim.tbl_isempty(filterd_args) then
    return filterd_args
  end
  return options
end

M.setup = function(user_options)
  o.set(user_options or {})
  load_runners()

  local simple_cmds = {
    RunClose = commands.run_close,
    CRFiletype = M.open_filetype_suported,
    CRProjects = M.open_project_manager
  }
  for cmd,func in pairs(simple_cmds) do
    vim.api.nvim_create_user_command(cmd, func, {nargs=0})
  end

  local valid_filetypes = vim.tbl_keys(o.get().filetype)
  vim.api.nvim_create_user_command('RunCode',function(opts) commands.run(opts.args) end, {
    nargs = '?',
    complete = function(ArgLead, CmdLine, CursorPos)
      return completion(ArgLead, valid_filetypes)
    end,
  })

  -- Add here the way you want
  local modes = {'float', 'tab', 'term', 'toggle', 'toggleterm'}
  vim.api.nvim_create_user_command('RunFile', function(opts) commands.run_filetype(opts.args) end, {
    nargs = '?',
    complete = function(ArgLead, CmdLine, CursorPos)
      return completion(ArgLead, modes)
    end,
  })
  vim.api.nvim_create_user_command('RunProject',function(opts) commands.run_project(opts.args) end, {
    nargs = '?',
    complete = function(ArgLead, CmdLine, CursorPos)
      return completion(ArgLead, modes)
    end,
  })
end

return M
