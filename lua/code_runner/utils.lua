local notify = require("code_runner.hooks.notify")
local pattern = "crunner_"

-- Open a terminal running `command` in the current buffer, using the modern
-- jobstart API when available and falling back to termopen on older Neovim.
local function term_open(command)
  if vim.fn.has("nvim-0.11") == 1 then
    vim.fn.jobstart(command, { term = true })
  else
    vim.fn.termopen(command)
  end
end

---@class Utils
local Utils = {}
Utils.__index = Utils

function Utils.new(opt)
  local self = setmetatable({}, Utils)
  self:ctor(opt)
  return self
end

function Utils:ctor(opt)
  assert(opt, "opt is required")
  self.opt = opt
  self.btm_number = self.opt.better_term.init
  self._user_argument = {}

  self.modes = {
    term = function(command, bufname)
      self:execute(command, bufname)
    end,
    tab = function(command, bufname)
      self:execute(command, bufname, "tabnew")
    end,
    float = function(command)
      require("code_runner.floats").floating(command)
    end,
    better_term = function(command)
      self:betterTerm(command)
    end,
    toggleterm = function(command)
      local ok, toggleterm = pcall(require, "toggleterm")
      if ok then
        toggleterm.exec(command)
      else
        notify.error("The 'toggleterm' plugin is not installed.", "Toggleterm")
      end
    end,
    vimux = function(command)
      if vim.fn.exists(":VimuxRunCommand") == 2 then
        vim.fn.VimuxRunCommand(command)
      else
        notify.error(
          "The 'VimuxRunCommand' does not exist. Please add 'preservim/vimux' plugin to your dependencies.",
          "Vimux"
        )
      end
    end,
  }
end

function Utils:setUserArgument(user_argument)
  self._user_argument = user_argument
end

function Utils:replaceVars(command, path)
  if type(command) == "function" then
    local cmd = command(self._user_argument)
    if type(cmd) == "string" then
      command = cmd
    elseif type(cmd) == "table" then
      command = table.concat(cmd, " ")
    else
      return nil
    end
  end

  local no_sub_command = command

  local file_info = {
    nameWithoutExt = vim.fn.shellescape(vim.fn.fnamemodify(path, ":t:r")),
    name = vim.fn.shellescape(vim.fn.fnamemodify(path, ":t")),
    dir = vim.fn.shellescape(vim.fn.fnamemodify(path, ":p:h")),
  }

  command = command:gsub("%$(%w+)", function(var)
    if var == "fileNameWithoutExt" then
      return file_info.nameWithoutExt
    elseif var == "fileName" then
      return file_info.name
    elseif var == "file" then
      return vim.fn.shellescape(path)
    elseif var == "dir" then
      return file_info.dir
    elseif var == "end" then
      return ""
    else
      return "$" .. var
    end
  end)

  if command == no_sub_command then
    command = command .. " " .. vim.fn.shellescape(path)
  end

  return command
end

function Utils:getCommand(filetype, path)
  path = path or vim.fn.expand("%:p")
  local command = self.opt.filetype[filetype]
  return command and self:replaceVars(command, path) or nil
end

function Utils:close(bufname)
  bufname = bufname or pattern .. vim.fn.expand("%:t:r")
  local current_buf = vim.fn.bufname("%")

  if current_buf:find(pattern, 1, true) then -- use direct search instead of string.find
    vim.cmd("bwipeout!")
  else
    local bufid = vim.fn.bufnr(bufname)
    if bufid ~= -1 then
      vim.cmd("bwipeout! " .. bufid)
    end
  end
end

function Utils:execute(command, bufname, prefix)
  prefix = prefix or self.opt.prefix
  self:close(bufname)
  bufname = "file " .. bufname
  local current_win_id = vim.api.nvim_get_current_win()

  vim.cmd(prefix)
  term_open(command)

  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].relativenumber = false
  vim.bo[buf].number = false
  vim.bo[buf].filetype = "crunner"

  vim.cmd(bufname)

  if prefix ~= "tabnew" then
    vim.bo.buflisted = false
  end

  if self.opt.focus then
    vim.cmd(self.opt.insert_prefix)
  else
    vim.fn.win_gotoid(current_win_id)
  end
end

function Utils:betterTerm(command)
  local betterTerm = package.loaded["betterTerm"] or require("betterTerm")
  if betterTerm then
    self.btm_number = self.opt.better_term.number or (self.btm_number + 1)
    betterTerm.send(command, self.btm_number, { clean = self.opt.better_term.clean })
  end
end

function Utils:runMode(command, bufname, mode)
  mode = mode or self.opt.mode
  bufname = pattern .. bufname
  local mode_func = self.modes[mode]

  if not mode_func then
    notify.warn(":( mode not found, Select valid mode", "Project")
    return
  end

  mode_func(command, bufname)
end

return Utils
