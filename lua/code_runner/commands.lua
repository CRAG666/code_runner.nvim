local Options = require("code_runner.options")
local FileType = require("code_runner.filetype")
local Project = require("code_runner.project")
local Utils = require("code_runner.utils")

local first_run = true

--- Initializes the utility module with options and user arguments.
---@param args table User-provided arguments.
---@return utils Utils initialized utility object.
local function get_utils(args)
  local options = {}
  if first_run then
    options = Options.get()
    first_run = false
  end
  local utils = Utils.new(options)
  utils:setUserArgument(args)
  return utils
end

--- Initializes the file type module.
---@return FileType The initialized file type object.
local function get_filetype()
  return FileType.new(get_utils({}))
end

--- Initializes the project module.
---@return Project The initialized project object.
local function get_project()
  return Project.new(get_utils({}))
end

local M = {}

--- Runs code based on file type or project context.
---@param filetype string? The specific file type to execute, if provided.
---@param user_argument table? Additional user arguments for execution.
function M.run_code(filetype, user_argument)
  local utils = get_utils(user_argument)

  if filetype and filetype ~= "" then
    local cmd_to_execute = utils:getCommand(filetype)
    if cmd_to_execute then
      utils.opt.before_run_filetype()
      utils:runMode(cmd_to_execute, vim.fn.expand("%:t:r"))
      return
    end
    return -- Exit if there is no valid command.
  end

  -- Fallback to project or file type execution
  local context = get_project():run(nil, false)
  if not context then
    get_filetype():run()
  end
end

---@param cmd string? The command to execute.
function M.run_from_fn(cmd)
  return get_filetype():runFromFn(cmd)
end

--- Retrieves the current project command.
---@return string? The project-specific command.
function M.get_project_command()
  return get_project():getCommand()
end

--- Runs the project in a specific mode.
---@param mode string? The execution mode.
function M.run_project(mode)
  get_project():run(mode)
end

--- Retrieves the current file type command.
---@return string? The file type-specific command.
function M.get_filetype_command()
  return get_filetype():getCommand()
end

--- Runs the file type in a specific mode.
---@param mode string? The execution mode.
function M.run_filetype(mode)
  get_filetype():run(mode)
end

--- Closes the currently running execution context.
function M.run_close()
  local bufname = nil
  local project = get_project()
  project:setRootPath()
  if project.context then
    bufname = "pattern" .. project.context.name
  end
  get_utils({}):close(bufname)
end

--- Retrieves the available modes.
---@return table The table of available modes.
function M.get_modes()
  local utils = get_utils({})
  return utils and utils.modes or {}
end

return M
