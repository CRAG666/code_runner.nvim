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
  -- for key, value in pairs(M.options) do
  --   local user_value = user_options[key]
  --   if user_value and type(user_value) == "table" then
  --     M.options[key] = vim.tbl_deep_extend("force", value, user_value)
  --   else
  --     M.options[key] = user_value or value
  --   end
  -- end
end


return M
