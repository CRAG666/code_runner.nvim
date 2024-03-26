local M = {}

function M.select(options, msg)
  msg = msg or "Select option:"
  vim.ui.select(vim.tbl_keys(options), {
    prompt = msg,
  }, function(opt, _)
    if vim.tbl_get(options, opt) == nil then
      vim.notify("Option not found", vim.log.levels.ERROR, { title = "Invalid option" })
      return
    end
    options[opt]()
  end)
end

return M
