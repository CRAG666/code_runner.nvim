local M = {}
local o = require("code_runner.options")

function M.floating(command)
  local opt = o.get()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_keymap(buf, "t", "<ESC>", "<C-\\><C-n>", { silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", opt.float.close_key, "<CMD>q!<CR>", { silent = true })
  vim.api.nvim_buf_set_option(buf, "filetype", "crunner")
  local win_height = math.ceil(vim.api.nvim_get_option("lines") * opt.float.height - 4)
  local win_width = math.ceil(vim.api.nvim_get_option("columns") * opt.float.width)
  local row = math.ceil((vim.api.nvim_get_option("lines") - win_height) * opt.float.y - 1)
  local col = math.ceil((vim.api.nvim_get_option("columns") - win_width) * opt.float.x)
  local opts = {
    style = "minimal",
    relative = "editor",
    border = opt.float.border,
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  }
  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.fn.termopen(command)
  if opt.startinsert then
    vim.cmd("startinsert")
  end
  if opt.wincmd then
    vim.cmd("wincmd p")
  end
  vim.api.nvim_win_set_option(win, "winhl", "Normal:" .. opt.float.float_hl .. ",FloatBorder:" .. opt.float.border_hl)
  vim.api.nvim_win_set_option(win, "winblend", opt.float.blend)
end

return M
