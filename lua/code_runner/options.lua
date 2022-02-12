local options = {
	term = {
		tab = false,
		mode = "",
		position = "belowright",
		size = 8
	},
	filetype_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/code_runner.nvim/lua/code_runner/code_runner.json",
	filetype = {},
	project_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/code_runner.nvim/lua/code_runner/project_manager.json",
	project = {},
	prefix = ""
}

local M = {}
-- set user config
M.set = function(user_options)
	if user_options.term.mode then
		user_options.term.mode = "| :" .. user_options.term.mode
	end
	options = vim.tbl_deep_extend("force", options, user_options)
	options.prefix = string.format("%s %dsplit term://", options.term.position, options.term.size)
end

M.get = function()
	return options
end

return M
