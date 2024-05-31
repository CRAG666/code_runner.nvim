local commands = require("code_runner.commands")
local o = require("code_runner.options")

local function config(opt)
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

  o.set(opt) -- set user options

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
  config(user_options or {})

  local Subcmds = {
    on = "on",
    with = "with",
    project = "project",
    close = "closeRunnerWindow",
    openProject = "openProjectList",
    openProjectFtSupported = "openProjectFiletypes",
  }

  vim.api.nvim_create_user_command("Run", function(opts)
    if opts.args == "" then
      return commands.run_current_file(nil, opts)
    end

    local args = vim.split(opts.args, "%s+")
    local subcommand = args[1]
    local value = args[2]

    if subcommand == Subcmds.on then
      return commands.run_current_file(value, opts)
    elseif subcommand == Subcmds.with then
      return commands.run_code(value, opts)
    elseif subcommand == Subcmds.project then
      return commands.run_project(value, opts)
    elseif subcommand == Subcmds.close then
      return commands.close_current_execution()
    elseif subcommand == Subcmds.openProject then
      return M.open_project_manager()
    elseif subcommand == Subcmds.openProjectFtSupported then
      return M.open_filetype_suported()
    else
      return vim.notify(
        string.format("Invalid operation %s"),
        vim.log.levels.ERROR,
        { title = "Code Runner plugin Error" }
      )
    end
  end, {
    range = 0,
    nargs = "?",
    complete = function(ArgLead, CmdLine, _) -- :help :command-completion-custom
      local cmdline_values = vim.split(CmdLine, "%s+")

      if #cmdline_values > 2 and #cmdline_values < 4 then
        local sub_cmd = cmdline_values[2]
        if sub_cmd == Subcmds.with then
          return completion(ArgLead, vim.tbl_keys(o.get().filetype))
        elseif sub_cmd == Subcmds.on or sub_cmd == Subcmds.project then
          return completion(ArgLead, vim.tbl_keys(commands.display_modes))
        end
      elseif #cmdline_values == 2 then
        return completion(ArgLead, vim.tbl_values(Subcmds))
      end
    end,
  })

  M.run_code = commands.run_code
  M.run_current_file = commands.run_current_file
  M.run_project = commands.run_project
end

return M
