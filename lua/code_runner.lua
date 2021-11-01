local commands = require("code_runner.commands")
local M = {}
local o = require("code_runner.options")


M.setup = function(user_options)
  o.set(user_options)
  M.load_json_files()
  vim.api.nvim_exec(
    [[
    function! CRunnerGetKeysForCmds(Arg,Cmd,Curs)
    let cmd_keys = ""
    for x in keys(g:fileCommands)
    let cmd_keys = cmd_keys.x."\n"
    endfor
    return cmd_keys
    endfunction

    command! CRFiletype lua require('code_runner').open_filetype_suported()
    command! CRProjects lua require('code_runner').open_project_manager()
    command! CRFiletype lua require('code_runner').open_filetype_suported()
    command! CRProjects lua require('code_runner').open_project_manager()
    command! -nargs=? -complete=custom,CRunnerGetKeysForCmds RunCode lua require('code_runner').run_code("<args>")
    command! RunFile lua require('code_runner').run_filetype()
    command! RunProject lua require('code_runner').run_project()
    ]],
    false
  )
end


local function open_json(json_path)
  local command = "tabnew " .. json_path
  vim.cmd(command)
end

local function get_conf_runners(option)
  if option and #option > 0 then
    return vim.deepcopy(option)
  end
  return nil
end

M.load_json_files = function()
  -- Load json config and convert to table
  local load_json_as_table = require("code_runner.load_json")
  local opt = o.get()
  vim.g.fileCommands = load_json_as_table(opt.filetype_path) or get_conf_runners(opt.filetype)
  vim.g.projectManager = load_json_as_table(o.get().project_path) or get_conf_runners(opt.projects)
  vim.g.crPrefix = string.format("%s %dsplit term://", opt.term.position, opt.term.size)

  -- Message if json file not exist
  if not vim.g.fileCommands then
    print("Not exist command for filetypes or format invalid, if use json please execute :CRFiletype")
  end
end

M.run_code = commands.run
M.run_filetype = commands.run_filetype
M.run_project = commands.run_project
M.get_filetype_command = commands.get_filetype_command
M.get_project_command = commands.get_project_command

M.open_filetype_suported = function()
  open_json(o.get().filetype_path)
end

M.open_project_manager = function()
  open_json(o.get().project_path)
end

return M
