local options = {
      term = {
        position = "belowright",
        size = 8,
      },
      filetype = {
        map = "<leader>r",
        json_path = vim.fn.stdpath("data") .. '/site/pack/packer/start/code_runner.nvim/lua/code_runner/code_runner.json',
      },
      project_context = {
        map = "<leader>r",
        json_path = vim.fn.stdpath("data") .. '/site/pack/packer/start/code_runner.nvim/lua/code_runner/project_manager.json'
      }
}

local M = {}
M.set = function(user_options)
  options = vim.tbl_extend("force", user_options, options)
  print(vim.inspect(options))
end

M.get = function() return options end

return M
