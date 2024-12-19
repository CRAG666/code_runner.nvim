local Singleton = require("code_runner.singleton")
local notify = require("code_runner.hooks.notify")

-- Definition of the FileType class
local FileType = {}
FileType.__index = FileType

--- Constructor for the FileType class.
---@param utils table A utility object, required for execution.
function FileType:ctor(utils)
  assert(utils, "utils is required") -- Direct validation
  self.opt = utils.opt
  self.utils = utils
end

--- Retrieves the command associated with the current file type.
---@return string The command for the current file type, or an empty string if none exists.
function FileType:getCommand()
  return self.utils:getCommand(vim.bo.filetype) or ""
end

--- Executes the current file based on its file type.
---@param mode string? The mode in which the command should run.
function FileType:run(mode)
  local command = self:getCommand()
  if command ~= "" then
    if self.opt.before_run_filetype then
      self.opt.before_run_filetype()
    end
    self.utils:runMode(command, vim.fn.expand("%:t:r"), mode)
    return
  end

  local nvim_files = {
    lua = "luafile %",
    vim = "source %",
  }
  local cmd = nvim_files[vim.bo.filetype]
  if cmd then
    vim.cmd(cmd)
  else
    notify.warn("No command available for this file type", "CodeRunner")
  end
end

--- Executes a specific command provided as a function parameter.
---@param cmd string|table The command to execute, either as a string or a table.
function FileType:runFromFn(cmd)
  local command = type(cmd) == "table" and table.concat(cmd, " ") or cmd
  assert(type(command) == "string", "The parameter 'cmd' must be a string or a table")
  local path = vim.fn.expand("%:p")
  local expanded_command = self.utils:replaceVars(command, path)
  self.utils:runMode(expanded_command, vim.fn.expand("%:t:r"))
end

-- Convert FileType into a singleton
return Singleton(FileType)
