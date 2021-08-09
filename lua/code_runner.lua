local o = require("code_runner.options")
local M = {}

M.setup = function(user_options)
  o.set(user_options)
  vim.api.nvim_exec([[
  command! SRunCode lua require('code_runner').open_filetype_suported()
  ]], false)
  vim.cmd [[lua require('code_runner').run_code()]]
end

M.run_code = function()
  local run = require("code_runner.commands")
  run()
end

M.open_filetype_suported = function()
  local command ="tabnew " .. o.get().json_path
  vim.cmd(command)
end

return M
