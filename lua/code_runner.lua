local commands = require("code_runner.commands")
local au_cd = require("code_runner.hooks.autocmd")
local utils = require("code_runner.hooks.utils")
local notify = require("code_runner.hooks.notify")
local o = require("code_runner.options")

local M = {}

local function setup(opt)
  -- Load json config and convert to table
  local load_json_as_table = require("code_runner.load_json")

  -- Convert json filetype as table lua
  if vim.tbl_isempty(opt.filetype or {}) then
    opt.filetype_path = opt.filetype_path or ""
    if opt.filetype_path ~= "" then
      local filetype = load_json_as_table(opt.filetype_path)
      if not filetype then
        notify.error("Error trying to load filetypes commands", "Code Runner Error")
      end
      opt.filetype = filetype or {}
    end
  end

  -- Convert json project as table lua
  if vim.tbl_isempty(opt.project or {}) then
    opt.project_path = opt.project_path or ""
    if opt.project_path ~= "" then
      local project = load_json_as_table(opt.project_path)
      if not project then
        notify.error("Error trying to load project commands", "Code Runner Error")
      end
      opt.project = project or {}
    end
  end

  -- set user options
  o.set(opt)

  -- Message if json file not exist
  if vim.tbl_isempty(o.get().filetype) then
    notify.error(
      "Not exist command for filetypes or format invalid, if use json please execute :CRFiletype or if use lua edit setup",
      "Code Runner Error"
    )
  end
end

local function open_json(json_path)
  local command = "tabnew " .. json_path
  vim.cmd(command)
end

local function completion(ArgLead, options)
  local filterd_args = vim.tbl_filter(function(v)
    return v:find(ArgLead:lower(), 1, true) == 1
  end, options)
  if not vim.tbl_isempty(filterd_args) then
    return filterd_args
  end
  return options
end

M.open_filetype_suported = function()
  open_json(o.get().filetype_path)
end

M.open_project_manager = function()
  open_json(o.get().project_path)
end

M.setup = function(user_options)
  setup(user_options or {})

  local simple_cmds = {
    RunClose = commands.run_close,
    CRFiletype = M.open_filetype_suported,
    CRProjects = M.open_project_manager,
  }
  for cmd, func in pairs(simple_cmds) do
    vim.api.nvim_create_user_command(cmd, func, { nargs = 0 })
  end

  -- Commands with autocomplete
  local modes = vim.tbl_keys(commands.get_modes())
  -- Format:
  --  CoomandName = { function, option_list }
  local completion_cmds = {
    RunCode = { commands.run_code, vim.tbl_keys(o.get().filetype) },
    RunFile = { commands.run_filetype, modes },
    RunProject = { commands.run_project, modes },
  }
  for cmd, cmo in pairs(completion_cmds) do
    vim.api.nvim_create_user_command(cmd, function(opts)
      cmo[1](unpack(opts.fargs))
    end, {
      nargs = "*",
      complete = function(ArgLead, word, ...)
        -- only complete the first argument
        if #vim.split(word, "%s+") > 2 then
          return
        end
        return completion(ArgLead, cmo[2])
      end,
    })
  end
  M.run_code = commands.run_code
  M.run_from_fn = commands.run_from_fn
  M.run_filetype = commands.run_filetype
  M.run_project = commands.run_project
  M.run_close = commands.run_close
  M.get_filetype_command = commands.get_filetype_command
  M.get_project_command = commands.get_project_command
  if o.get().hot_reload then
    local id = au_cd.create_on_write(function(...)
      commands.run_code()
    end)
    utils.create_stop_hot_reload(id)
  end
end

return M
