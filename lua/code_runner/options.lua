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
M.options = {}
M.set = function(user_options)
  M.options = vim.tbl_deep_extend("force",{}, defaults, M.options or {}, user_options)
end


return M
