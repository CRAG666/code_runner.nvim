local commands = require("code_runner.commands")
local o = require("code_runner.options")

local function setup(opt)
  -- Load json config and convert to table
  local load_json_as_table = require("code_runner.load_json")

  -- Convert json filetype as table lua
  if vim.tbl_isempty(opt.filetype or {}) then
    opt.filetype_path = opt.filetype_path or ""
    if opt.filetype_path ~= "" then
      local filetype = load_json_as_table(opt.filetype_path)
      if not filetype then
        vim.notify("Error trying to load filetypes commands", vim.log.levels.ERROR, { title = "Code Runner Error" })
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
        vim.notify("Error trying to load project commands", vim.log.levels.ERROR, { title = "Code Runner Error" })
      end
      opt.project = project or {}
    end
  end

  -- set user options
  o.set(opt)

  -- Message if json file not exist
  if vim.tbl_isempty(o.get().filetype) then
    vim.notify(
      "Not exist command for filetypes or format invalid, if use json please execute :CRFiletype or if use lua edit setup",
      vim.log.levels.ERROR,
      { title = "Code Runner Error" }
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

local M = {}

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
  local modes = vim.tbl_keys(commands.modes)
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
  M.run_filetype = commands.run_filetype
  M.run_project = commands.run_project
end

return M
