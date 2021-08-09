local options = {
      term = {
        position = "belowright",
        size = 8
      },
      map = "<leader>r",
      json_path = vim.fn.expand('~/.config/nvim/code_runner.json')
}

local M = {}
M.set = function(user_options)
    options = vim.tbl_extend("force", options, user_options)
end

M.get = function() return options end

return M
