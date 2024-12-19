local notify = require("code_runner.hooks.notify")

-- Define la clase Project
local Project = {}
Project.__index = Project

-- Constructor
function Project:new(utils)
  assert(utils, "utils is requiered") -- Validación directa
  local self = setmetatable({}, Project)
  self.opt = utils.opt
  self.utils = utils
  self.context = nil
  return self
end

-- Método para establecer la ruta raíz
function Project:setRootPath()
  local file_path = vim.fn.expand("%:p:h")
  for project_path, project_data in pairs(self.opt.project) do
    local normalized_path = vim.fs.normalize(project_path)
    if file_path:sub(1, #normalized_path) == normalized_path then
      self.context = vim.deepcopy(project_data)
      self.context.path = normalized_path
      break
    end
  end
end

-- Método para configurar el comando
function Project:setCommand()
  if not self.context then
    return
  end

  local path = self.context.path
  local file = self.context.file_name and (path .. "/" .. self.context.file_name)

  if file and self.context.command then
    self.context.command = self.utils:replaceVars(self.context.command, file)
  elseif file then
    local filetype = vim.filetype.match({ filename = file })
    self.context.command = self.utils:getCommand(filetype, file)
  else
    self.context.command = "cd " .. path .. " && " .. self.context.command
  end
end

-- Método para ejecutar el proyecto
function Project:run(mode, notify_enable)
  notify_enable = notify_enable ~= false -- Por defecto, habilitar notificaciones

  self:setRootPath()
  if self.context then
    self:setCommand()
    notify.info("File execution as project", "Project")

    mode = mode or self.context.mode
    self.utils:runMode(self.context.command, self.context.name, mode)
    return true
  end

  if notify_enable then
    notify.warn(":( There is no project associated with this path", "Project")
  end
  return false
end

-- Método para obtener el comando actual
function Project:getCommand()
  self:setRootPath()
  self:setCommand()
  return self.context and self.context.command or nil
end

-- Exporta el módulo
return Project
