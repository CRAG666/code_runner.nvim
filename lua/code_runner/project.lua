local notify = require("code_runner.hooks.notify")
local Singleton = require("code_runner.singleton")

-- Define the Project class
local Project = {}
Project.__index = Project

--- Constructor for the Project class.
---@param utils table A utility object, required for execution.
function Project:ctor(utils)
  assert(utils, "utils is required") -- Direct validation
  self.opt = utils.opt
  self.utils = utils
  self.context = nil
end

--- Sets the root path of the project.
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

--- Configures the command for the project.
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

--- Executes the project with the specified mode.
---@param mode string? The mode in which to run the project.
---@param notify_enable boolean? Whether notifications are enabled (default: true).
---@return boolean True if the project runs successfully, false otherwise.
function Project:run(mode, notify_enable)
  notify_enable = notify_enable ~= false -- Enable notifications by default

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

--- Retrieves the current command for the project.
---@return string|nil The command if available, or nil if no project is associated.
function Project:getCommand()
  self:setRootPath()
  self:setCommand()
  return self.context and self.context.command or nil
end

return Singleton(Project)
