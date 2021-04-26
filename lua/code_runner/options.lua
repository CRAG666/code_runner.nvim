local options = {
      term = {
        position = "belowright",
        size = 8
      },
      fterm = {
        height = 0.7,
        width = 0.7
      },
      inspath = "~/.local/share/nvim/site/pack/packer/start/code_runner.nvim/python/"
}

local M = {}
M.set = function(user_options)
    options = vim.tbl_extend("force", options, user_options)
end

M.get = function() return options end

return M

