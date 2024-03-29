local commands = {}
local M = {}

function M.create_au_write(fn)
  local bufnr = vim.api.nvim_get_current_buf()
  local group = vim.api.nvim_create_augroup("CodeRunnerJobPosWrite", { clear = true })
  local id = vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = group,
    buffer = bufnr,
    callback = fn,
  })
  commands[bufnr] = id
end

local function stop(bufnr)
  if commands[bufnr] ~= nil then
    vim.api.nvim_del_autocmd(commands[bufnr])
    commands[bufnr] = nil
  end
end

function M.stop_job()
  local bufnr = vim.api.nvim_get_current_buf()
  stop(bufnr)
end

return M
