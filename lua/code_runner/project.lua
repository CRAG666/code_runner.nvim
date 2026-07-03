local notify = require("code_runner.hooks.notify")
local load_json = require("code_runner.load_json")

-- Per-project config file: place it in the project root to define the command.
-- Same fields as a `project` entry: { "name": ..., "command": ..., "file_name": ..., "mode": ... }
-- Hidden and prefixed to avoid clashing with the json files used for
-- filetype/project config (the README suggests naming those code_runner.json).
local LOCAL_CONFIG = ".crproject.json"

-- Cache for normalized paths, shared across instances
local path_cache = {}

-- Active watchers, shared across instances: root path -> autocmd id.
-- With `watch = true` (project entry or .crproject.json) running the project
-- re-runs its command on every write under the root; running again stops it.
local watchers = {}
local watch_group = vim.api.nvim_create_augroup("CodeRunnerProjectWatch", { clear = true })

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
      mode = matching_data.mode,
      watch = matching_data.watch,
    }
    return
  end

  self:detectRoot(file_path)
end

-- Fallback when no configured project matches: search upward for a local
-- config file or a known root marker (pom.xml, Cargo.toml, ...).
---@param file_path string Directory of the current buffer.
function Project:detectRoot(file_path)
  local markers = self.opt.root_markers or {}
  local names = { LOCAL_CONFIG }
  for _, marker in ipairs(markers) do
    names[#names + 1] = marker[1]
  end

  -- Nearest ancestor wins; within a directory, `names` order gives the
  -- local config file priority over markers.
  local found = vim.fs.find(names, { upward = true, type = "file", path = file_path })[1]
  if not found then
    return
  end

  local root = vim.fs.dirname(found)
  local file_name = vim.fs.basename(found)
  local data

  if file_name == LOCAL_CONFIG then
    data = load_json(found)
    if not data or not data.command then
      notify.error("Invalid " .. found .. ": expected a json object with a 'command' key", "Code Runner Error")
      return
    end
  else
    for _, marker in ipairs(markers) do
      if marker[1] == file_name then
        data = { name = file_name, command = marker[2] }
        break
      end
    end
  end

  self.matching_root_path = root
  self.initial_command = data.command
  self.context = {
    path = root,
    name = data.name or file_name,
    command = data.command,
    file_name = data.file_name,
    mode = data.mode,
    watch = data.watch,
  }
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

  local run_mode = mode or self.context.mode

  if self.context.watch then
    local root = self.context.path

    -- Toggle: running a watched project again stops the watcher.
    if watchers[root] then
      vim.api.nvim_del_autocmd(watchers[root])
      watchers[root] = nil
      if notify_enable then
        notify.info("Stop watch: " .. self.context.name, "Run Project")
      end
      return true
    end

    local utils, command, name = self.utils, self.context.command, self.context.name
    watchers[root] = vim.api.nvim_create_autocmd("BufWritePost", {
      group = watch_group,
      pattern = root .. "/*",
      callback = function()
        utils:runMode(command, name, run_mode)
      end,
    })
    if notify_enable then
      notify.info("Watch: " .. self.context.name, "Run Project")
    end
  elseif notify_enable then
    notify.info(self.context.name, "Run Project")
  end

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
