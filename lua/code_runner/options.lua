local defaults = {
  term = {
    position = "belowright",
    size = 8,
  },
  filetype_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/code_runner.nvim/lua/code_runner/code_runner.json",
  project_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/code_runner.nvim/lua/code_runner/project_manager.json",
}

local M = {}
-- set user config
M.options = nil
M.set = function(user_options)
  for key, value in pairs(defaults) do
    local u_o = user_options[key] or {}
    M.options[key] = vim.tbl_extend("force", value, u_o)
  end
end


return M
