local o = require("code_runner.options")

local trun_code = function()
  pos = o.get().term.position
  size = o.get().term.size
  term = string.format("%s %dsplit term://", pos, size)
  command = "python " .. o.get().inspath .. "code_runner.py "
  filepath = vim.fn.expand("%")
  vim_command = term .. command .. filepath
  vim.api.nvim_command(vim_command)
end

return trun_code
