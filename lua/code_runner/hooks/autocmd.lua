local M = {}

function M.create_on_write(fn, pattern)
  pattern = pattern or "*"
  local group = vim.api.nvim_create_augroup("CodeRunnerJobPosWrite", { clear = true })
  local id = vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = group,
    pattern = pattern,
    callback = fn,
  })
  return id
end

function M.stop(id)
  vim.api.nvim_del_autocmd(id)
end

return M
