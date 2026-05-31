local M = {}
local o = require("code_runner.options")

-- Open a terminal running `command` in the current buffer, using the modern
-- jobstart API when available and falling back to termopen on older Neovim.
local function term_open(command)
  if vim.fn.has("nvim-0.11") == 1 then
    vim.fn.jobstart(command, { term = true })
  else
    vim.fn.termopen(command)
  end
end

function M.floating(command)
  local opt = o.get()
  local buf = vim.api.nvim_create_buf(false, true)

  vim.keymap.set("t", "<ESC>", "<C-\\><C-n>", { silent = true, buffer = buf })
  vim.keymap.set("n", opt.float.close_key, "<CMD>q!<CR>", { silent = true, buffer = buf })

  vim.bo[buf].filetype = "crunner"

  local win_height = math.ceil(vim.o.lines * opt.float.height - 4)
  local win_width = math.ceil(vim.o.columns * opt.float.width)
  local row = math.ceil((vim.o.lines - win_height) * opt.float.y - 1)
  local col = math.ceil((vim.o.columns - win_width) * opt.float.x)

  local win = vim.api.nvim_open_win(buf, true, {
    style = "minimal",
    relative = "editor",
    border = opt.float.border,
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  })

  term_open(command)

  if opt.startinsert then
    vim.cmd("startinsert")
  end

  if opt.wincmd then
    vim.cmd("wincmd p")
  end

  vim.wo[win].winhl = "Normal:" .. opt.float.float_hl .. ",FloatBorder:" .. opt.float.border_hl
  vim.wo[win].winblend = opt.float.blend
end

return M
