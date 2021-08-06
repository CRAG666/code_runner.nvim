local o = require("code_runner.options")
local M = {}

M.setup = function(user_options)
  o.set(user_options)
  vim.api.nvim_exec([[
  command! SRunCode lua require('code_runner').open_filetype_suported()
  ]], false)
  vim.cmd 'lua require('code_runner').run_code()'
end

M.frun_code = function()
  run = require("code_runner.fterm_commands")
  run()
end

M.run_code = function()
  run = require("code_runner.commands")
  run()
end

M.open_filetype_suported = function()
  command ="tabnew " .. "code_runner/code_runner.json"
  vim.cmd(command)
end

return M
