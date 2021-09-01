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
  for key, _ in pairs(options) do
    options[key] = vim.tbl_extend("force", options[key], user_options[key])
  end
  print(vim.inspect(options))
end

M.get = function() return options end

return M
