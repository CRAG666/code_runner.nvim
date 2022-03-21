local M = {}
local o = require("code_runner.options")

local function M.floating(command)
  local opt = o.get()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<ESC>",
		"<C-\\><C-n>:lua vim.api.nvim_win_close(win, true)<CR>",
		{ silent = true }
	)
	vim.api.nvim_buf_set_option(buf, "filetype", "crunner")
	local win_height = math.ceil(vim.api.nvim_get_option("lines") * config.ui.float.height - 4)
	local win_width = math.ceil(vim.api.nvim_get_option("columns") * config.ui.float.width)
	local row = math.ceil((vim.api.nvim_get_option("lines") - win_height) * config.ui.float.y - 1)
	local col = math.ceil((vim.api.nvim_get_option("columns") - win_width) * config.ui.float.x)
	local opts = {
		style = "minimal",
		relative = "editor",
		border = config.ui.float.border,
		width = win_width,
		height = win_height,
		row = row,
		col = col,
	}
	local win = vim.api.nvim_open_win(buf, true, opts)
	vim.fn.termopen(cmd)
	if config.ui.startinsert then
		vim.cmd("startinsert")
	end
	if config.ui.wincmd then
		vim.cmd("wincmd p")
	end
	vim.api.nvim_win_set_option(
		win,
		"winhl",
		"Normal:" .. config.ui.float.float_hl .. ",FloatBorder:" .. config.ui.float.border_hl
	)
	vim.api.nvim_win_set_option(win, "winblend", config.ui.float.blend)
end

return M
