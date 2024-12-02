local notify = require("code_runner.hooks.notify")

local M = {}

function M.preview_open(file, command)
  local cmd = string.format("ps aux | grep '%s %s' | grep -v grep", command, file)
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()

  result = result:gsub("^%s*(.-)%s*$", "%1")

  if result == "" then
    notify.info("Preview Open", "Zathura")
    vim.fn.jobstart(string.format("%s %s", command, file))
  else
    notify.warn("Preview already running", "Zathura")
  end
end

function M.preview_close(file, command)
  -- Construir el comando de shell para encontrar el PID del proceso
  local cmd = string.format("ps aux | grep '%s %s' | grep -v grep | awk '{print $2}'", command, file)
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()

  -- Limpiar espacios en blanco y obtener el PID
  result = result:gsub("^%s*(.-)%s*$", "%1")

  if result == "" then
    notify.warn("No instance found to close", "Zathura")
  else
    -- Cerrar el proceso usando `kill`
    local pid = result:match("%d+")
    if pid then
      local kill_cmd = string.format("kill -9 %s", pid)
      os.execute(kill_cmd)
      notify.info("Preview Closed", "Zathura")
    else
      notify.error("Failed to retrieve PID", "Zathura")
    end
  end
end

return M
