local FileType = {}
FileType.__index = FileType

--- Crea una nueva instancia de FileType
function FileType:new(utils)
  assert(utils, "utils es requerido") -- Validación directa
  local self = setmetatable({}, FileType)
  self.opt = utils.opt
  self.utils = utils
  return self
end

--- Obtiene el comando asociado al tipo de archivo actual
---@return string Comando correspondiente al tipo de archivo
function FileType:getCommand()
  return self.utils:getCommand(vim.bo.filetype) or ""
end

--- Ejecuta el archivo actual según su tipo de archivo
---@param mode string? Modo de ejecución opcional
function FileType:run(mode)
  local command = self:getCommand()
  if command ~= "" then
    if self.opt.before_run_filetype then
      self.opt.before_run_filetype() -- Llama a before_run_filetype si está definido
    end
    self.utils:runMode(command, vim.fn.expand("%:t:r"), mode)
    return
  end

  -- Comandos específicos de Neovim
  local nvim_files = {
    lua = "luafile %",
    vim = "source %",
  }
  local cmd = nvim_files[vim.bo.filetype]
  if cmd then
    vim.cmd(cmd)
  else
    vim.notify("No hay comando disponible para este tipo de archivo", vim.log.levels.WARN)
  end
end

--- Ejecuta un comando específico desde una función
---@param cmd string|table Comando como cadena o tabla
function FileType:run_from_fn(cmd)
  local command = type(cmd) == "table" and table.concat(cmd, " ") or cmd
  assert(type(command) == "string", "El parámetro cmd debe ser una cadena o una tabla")

  local path = vim.fn.expand("%:p")
  local expanded_command = self.utils:replaceVars(command, path)
  self.utils:runMode(expanded_command, vim.fn.expand("%:t:r"))
end

return FileType
