local M = {}
M.options = {
  term = {
    position = "belowright",
    size = 8,
  },
  filetype_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/code_runner.nvim/lua/code_runner/code_runner.json",
  project_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/code_runner.nvim/lua/code_runner/project_manager.json",
}

-- set user config
M.set = function(user_options)
  M.options = vim.tbl_deep_extend("force", M.options, user_options)
  print(vim.inspect(M.options))
end


return M
