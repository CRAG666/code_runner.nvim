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

      function! RunnerCompletion(lead, cmd, cursor)
        let valid_args = ['term', 'float', 'toggle']
        let l = len(a:lead) - 1
        if l >= 0
          let filtered_args = copy(valid_args)
          call filter(filtered_args, {_, v -> v[:l] ==# a:lead})
          if !empty(filtered_args)
            return filtered_args
          endif
        endif
        return valid_args
      endfunction

			command! CRProjects lua require('code_runner').open_project_manager()
      command! CRFiletype lua require('code_runner').open_filetype_suported()
			command! -nargs=? -complete=custom,CRunnerGetKeysForCmds RunCode lua require('code_runner').run_code("<args>")
      command! -nargs=? -complete=customlist,RunnerCompletion RunFile lua require('code_runner').run_filetype(<args>)
      command! -nargs=? -complete=customlist,RunnerCompletion RunProject lua require('code_runner').run_project(<args>)
			command! RunClose lua require('code_runner').run_close()
		]],
    false
  )
end

local function open_json(json_path)
  local command = "tabnew " .. json_path
  vim.cmd(command)
end

M.load_json_files = function()
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

  vim.g.runners = {}
  -- Message if json file not exist
  if vim.tbl_isempty(opt.filetype) then
    vim.notify(
      "Not exist command for filetypes or format invalid, if use json please execute :CRFiletype or if use lua edit setup",
      vim.log.levels.ERROR,
      { title = "Code Runner Error" }
    )
  end
end

M.run_code = commands.run
M.run_filetype = commands.run_filetype
M.run_project = commands.run_project
M.run_close = commands.run_close
M.get_filetype_command = commands.get_filetype_command
M.get_project_command = commands.get_project_command

M.open_filetype_suported = function()
  open_json(o.get().filetype_path)
end

M.open_project_manager = function()
  open_json(o.get().project_path)
end

return M
