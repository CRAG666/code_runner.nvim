-- Built-in commands for native Neovim files
local NVIM_FILES = {
  lua = "luafile %",
  vim = "source %",
}

---@class FileType
local FileType = {}
FileType.__index = FileType

---@param utils Utils
---@return FileType
function FileType.new(utils)
  local self = setmetatable({}, FileType)
  self:ctor(utils)
  return self
end

---@param utils Utils
function FileType:ctor(utils)
  assert(utils, "utils is required")
  self.opt = utils.opt
  self.utils = utils

  self.get_filename = function()
    return vim.fn.expand("%:t:r")
  end
end

---@return string command Empty string when the filetype has no command.
function FileType:getCommand()
  return self.utils:getCommand(vim.bo.filetype) or ""
end

---@param mode string? The mode in which the command should run.
function FileType:run(mode)
  local command = self:getCommand()

  if command ~= "" then
    local before_run = self.opt.before_run_filetype
    if before_run then
      before_run()
    end

    local filename = self.get_filename()
    self.utils:runMode(command, filename, mode)
    return
  end

  local cmd = NVIM_FILES[vim.bo.filetype]
  if cmd then
    vim.cmd(cmd)
  end
end

---@param cmd string|table The command to execute, as a string or list of parts.
function FileType:runFromFn(cmd)
  local command
  if type(cmd) == "table" then
    command = table.concat(cmd, " ")
  else
    command = cmd
  end

  assert(type(command) == "string", "The parameter 'cmd' must be a string or a table")

  local path = vim.fn.expand("%:p")
  local expanded_command = self.utils:replaceVars(command, path)

  self.utils:runMode(expanded_command, self.get_filename())
end

return FileType
