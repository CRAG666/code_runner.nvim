local notify = require("code_runner.hooks.notify")

local M = {}

local job = nil

function M.preview_open(file, command)
  if job == nil then
    notify.warn("Preview already running", "Zathura")
    job = vim.system({ command, file }, {}, function(obj)
      job = nil
    end)
  end
end

function M.preview_close()
  if job ~= nil then
    job:kill(15)
    job = nil
  end
end

function M.create_stop_hot_reload(id)
  vim.api.nvim_create_user_command("CrStopHr", function(opts)
    require("code_runner.hooks.autocmd").stop(id)
  end, { desc = "Stop hot reload for code runner", nargs = 0 })
end

return M
