local notify = require("code_runner.hooks.notify")

-- Cache for normalized paths, shared across instances
local path_cache = {}

---@class Project
local Project = {}
Project.__index = Project

---@param utils Utils
---@return Project
function Project.new(utils)
  local self = setmetatable({}, Project)
  self:ctor(utils)
  return self
end

---@param utils Utils
function Project:ctor(utils)
  assert(utils, "utils is required")
  self.opt = utils.opt
  self.utils = utils
  self.context = nil

  self.normalized_projects = {}
  for project_path, project_data in pairs(self.opt.project) do
    local norm_path = path_cache[project_path]
    if not norm_path then
      norm_path = vim.fs.normalize(project_path)
      path_cache[project_path] = norm_path
    end
    self.normalized_projects[norm_path] = {
      data = project_data,
      length = #norm_path,
    }
  end
end

function Project:setRootPath()
  local file_path = vim.fn.expand("%:p:h")

  -- Reuse the resolved context while we stay inside the same project root.
  if self.context and self.matching_root_path then
    if file_path:sub(1, #self.matching_root_path) == self.matching_root_path then
      self.last_path = file_path
      return
    end
  end

  self.context = nil
  self.matching_root_path = nil
  self.last_path = file_path
  self.initial_command = nil

  -- Pick the project whose root is the longest prefix of the current path.
  local matching_path, matching_data, max_length = nil, nil, 0

  for norm_path, project_info in pairs(self.normalized_projects) do
    local path_len = project_info.length

    if path_len > max_length and file_path:sub(1, path_len) == norm_path then
      matching_path = norm_path
      matching_data = project_info.data
      max_length = path_len
    end
  end

  if matching_path then
    self.matching_root_path = matching_path
    self.initial_command = matching_data.command

    self.context = {
      path = matching_path,
      name = matching_data.name,
      command = matching_data.command,
      file_name = matching_data.file_name,
    }
  end
end

function Project:setCommand()
  if not self.context then
    return
  end

  local path = self.context.path
  local file_name = self.context.file_name

  if file_name then
    local file = path .. "/" .. file_name

    if self.context.command then
      if self.initial_command == self.context.command then
        self.context.command = self.utils:replaceVars(self.context.command, file)
      end
    else
      if not self.context.filetype then
        self.context.filetype = vim.filetype.match({ filename = file })
      end
      self.context.command = self.utils:getCommand(self.context.filetype, file)
    end
  else
    local cmd = self.context.command
    if not cmd:find("^cd%s+") then
      self.context.command = "cd " .. path .. " && " .. cmd
    end
  end
end

---@param mode string? The mode in which to run the project.
---@param notify_enable boolean? Whether notifications are enabled (default: true).
---@return boolean ran Whether a project was found and run.
function Project:run(mode, notify_enable)
  notify_enable = notify_enable ~= false

  self:setRootPath()

  if not self.context then
    if notify_enable then
      notify.warn(":( There is no project associated with this path", "Project")
    end
    return false
  end

  self:setCommand()

  if notify_enable then
    notify.info(self.context.name, "Run Project")
  end

  local run_mode = mode or self.context.mode
  self.utils:runMode(self.context.command, self.context.name, run_mode)
  return true
end

---@return string? command nil when the current path has no associated project.
function Project:getCommand()
  self:setRootPath()

  if not self.context then
    return nil
  end

  self:setCommand()
  return self.context.command
end

return Project
