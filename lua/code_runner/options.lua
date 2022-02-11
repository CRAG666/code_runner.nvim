local options = {
  term = {
    position = "belowright",
    size = 8,
  },
  filetype_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/code_runner.nvim/lua/code_runner/code_runner.json",
  filetype = {},
  project_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/code_runner.nvim/lua/code_runner/project_manager.json",
  project = {},
	mode = ""
}

local M = {}
-- set user config
M.set = function(user_options)
	if options.mode ~= "" then
		options.mode = "&& :" .. options.mode
		print(vim.inspect("Entre"))
	end
  options = vim.tbl_deep_extend("force", options, user_options)
end

M.get = function()
  return options
end

return M
