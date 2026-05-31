local Options = require("code_runner.options")
local FileType = require("code_runner.filetype")
local Project = require("code_runner.project")
local Utils = require("code_runner.utils")

---@param args table User-provided arguments.
---@return Utils
local function get_utils(args)
  local utils = Utils.new(Options.get())
  utils:setUserArgument(args)
  return utils
end

---@return FileType
local function get_filetype()
  return FileType.new(get_utils({}))
end

---@return Project
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
      local filename = vim.fn.shellescape(vim.fn.expand("%:t:r"))
      utils:runMode(cmd_to_execute, filename)
      return
    end
    return
  end

  local context = get_project():run(nil, false)
  if not context then
    get_filetype():run()
  end
end

---@param cmd string? The command to execute.
function M.run_from_fn(cmd)
  return get_filetype():runFromFn(cmd)
end

---@return string? command
function M.get_project_command()
  return get_project():getCommand()
end

---@param mode string? The execution mode.
function M.run_project(mode)
  get_project():run(mode)
end

---@return string? command
function M.get_filetype_command()
  return get_filetype():getCommand()
end

---@param mode string? The execution mode.
function M.run_filetype(mode)
  get_filetype():run(mode)
end

function M.run_close()
  local bufname = nil
  local project = get_project()
  project:setRootPath()
  if project.context then
    bufname = "pattern" .. project.context.name
  end
  get_utils({}):close(bufname)
end

---@return table modes
function M.get_modes()
  local utils = get_utils({})
  return utils and utils.modes or {}
end

return M
