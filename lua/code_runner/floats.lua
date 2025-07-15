local M = {}
local o = require("code_runner.options")

function M.floating(command)
  local opt = o.get()
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_keymap(buf, "t", "<ESC>", "<C-\\><C-n>", { silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", opt.float.close_key, "<CMD>q!<CR>", { silent = true })
  vim.api.nvim_set_option_value("filetype", "crunner", { buf = buf })

  -- stylua: ignore start
  local win_height = math.ceil(vim.api.nvim_get_option_value("lines", { filetype = "crunner" }) * opt.float.height - 4)
  local win_width = math.ceil(vim.api.nvim_get_option_value("columns", { filetype = "crunner" }) * opt.float.width)
  local row = math.ceil((vim.api.nvim_get_option_value("lines", { filetype = "crunner" }) - win_height) * opt.float.y - 1)
  local col = math.ceil((vim.api.nvim_get_option_value("columns", { filetype = "crunner" }) - win_width) * opt.float.x)
  -- stylua: ignore end

  local config = {
    style = "minimal",
    relative = "editor",
    border = opt.float.border,
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  }
  local win_id = vim.api.nvim_open_win(buf, true, config)

  vim.api.nvim_set_option_value(
    "winhl",
    "Normal:" .. opt.float.float_hl .. ",FloatBorder:" .. opt.float.border_hl,
    { win = win_id }
  )
  vim.api.nvim_set_option_value("winblend", opt.float.blend, { win = win_id })

  vim.fn.jobstart(command)
  if opt.startinsert then
    vim.cmd("startinsert")
  end
end

return M
