local o = require("code_runner.options")
local FileType = require("code_runner.filetype")
local Project = require("code_runner.project")
local Utils = require("code_runner.utils")

--- Close runner
---@param bufname string?
local function closeRunner(bufname)
  bufname = bufname or pattern .. vim.fn.expand("%:t:r")
  local current_buf = vim.fn.bufname("%")

  if string.find(current_buf, pattern) then
    vim.cmd("bwipeout!")
  else
    local bufid = vim.fn.bufnr(bufname)
    if bufid ~= -1 then
      vim.cmd("bwipeout! " .. bufid)
    end
  end
end

-- Variables globales dentro del módulo
local ft, project, utils = nil, nil, nil

local M = {}

--- Inicializa utils con las opciones proporcionadas
---@param opt table
function M.set_utils(opt)
  utils = Utils:new(opt)
end

--- Ejecuta el código para un tipo de archivo o proyecto
---@param filetype string?
---@param user_argument table?
function M.run_code(filetype, user_argument)
  local opt = o.get()
  utils:setUserArgument(user_argument)

  ft = FileType:new(utils)

  if filetype and filetype ~= "" then
    local cmd_to_execute = ft:getCommand(filetype)
    if cmd_to_execute then
      opt.before_run_filetype()
      ft:runMode(cmd_to_execute, vim.fn.expand("%:t:r"))
      return
    end
    return -- Salir si es una función Lua sin salida
  end

  -- Proceder si no hay argumentos de entrada
  project = Project:new(utils)
  local context = project:run(false)
  if not context then
    ft:run()
  end
end

--- Obtiene el comando del proyecto actual
---@return string?
function M.get_project_command()
  if not project then
    utils:setUserArgument({})
    project = Project:new(utils)
  end
  return project:getCommand()
end

--- Ejecuta el proyecto en un modo específico
---@param mode string?
function M.run_project(mode)
  if not project then
    utils:setUserArgument({})
    project = Project:new(utils)
  end
  project:run(mode)
end

--- Obtiene el comando del tipo de archivo actual
---@return string?
function M.get_filetype_command()
  if not ft then
    utils:setUserArgument({})
    ft = FileType:new(utils)
  end
  return ft:getCommand()
end

--- Ejecuta el tipo de archivo en un modo específico
---@param mode string?
function M.run_filetype(mode)
  if not ft then
    utils:setUserArgument({})
    ft = FileType:new(utils)
  end
  ft:run(mode)
end

--- Cierra la ejecución actual
function M.run_close()
  if project then
    project:setRootPath()
    if project.context then
      closeRunner(pattern .. project.context.name)
    else
      closeRunner()
    end
  end
end

--- Obtiene los modos disponibles
---@return table
function M.get_modes()
  return utils and utils.modes or {}
end

return M
