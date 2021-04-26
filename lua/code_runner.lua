local o = require("code_runner.options")
local M = {}

M.setup = function(user_options)
  o.set(user_options)
  vim.api.nvim_exec([[
  command! FRunCode lua require('code_runner').frun_code()
  command! RunCode lua require('code_runner').run_code()
  ]], false)
end

M.frun_code = function()
  run = require("code_runner.fterm_commands")
  run()
end

M.run_code = function()
  run = require("code_runner.term_commands")
  run()
end

return M
