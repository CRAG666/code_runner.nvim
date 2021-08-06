local options = {
      term = {
        position = "belowright",
        size = 8
      },
      fterm = {
        height = 0.7,
        width = 0.7
      },
      map = "<leader>r",
      json_path = os.getenv("HOME") .. '/.local/share/nvim/site/pack/packer/start/code_runner.nvim/lua/code_runner/code_runner.json'
}

local M = {}
M.set = function(user_options)
    options = vim.tbl_extend("force", options, user_options)
end

M.get = function() return options end

return M

