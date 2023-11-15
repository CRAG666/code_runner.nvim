local commands = {}
local M = {}

function M.create_au_preview(fn)
  local bufnr = vim.api.nvim_get_current_buf()
  local group = vim.api.nvim_create_augroup("PreviewPDF", { clear = true })
  local id = vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = group,
    buffer = bufnr,
    callback = fn,
  })
  commands[bufnr] = id
end

local stop = function(bufnr)
  if commands[bufnr] ~= nil then
    vim.api.nvim_del_autocmd(commands[bufnr])
  end
end

function M.stop_au_preview()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_create_user_command("PreviewPDFStop" .. bufnr, stop, {})
end

return M
