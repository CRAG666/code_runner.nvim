local au_cd = require("code_runner.hooks.autocmd")
local notify = require("code_runner.hooks.notify")
local pattern = "crunner_"
local Utils = {}
Utils.__index = Utils

function Utils:new(opt)
  local self = setmetatable({}, Utils)
  self.opt = opt
  self.btm_number = self.opt.better_term.init
  self._user_argument = {}
  self.modes = self:getModes()
  return self
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

  command = command:gsub("$fileNameWithoutExt", vim.fn.fnamemodify(path, ":t:r"))
  command = command:gsub("$fileName", vim.fn.fnamemodify(path, ":t"))
  command = command:gsub("$file", path)
  command = command:gsub("$dir", vim.fn.fnamemodify(path, ":p:h"))
  command = command:gsub("$end", "")

  if command == no_sub_command then
    command = command .. " " .. path
  end

  return command
end

function Utils:getCommand(filetype, path)
  path = path or vim.fn.expand("%:p")
  local command = self.opt.filetype[filetype]
  return command and self:replaceVars(command, path) or nil
end

function Utils:execute(command, bufname, prefix)
  prefix = prefix or self.opt.prefix
  bufname = "file " .. bufname
  local current_win_id = vim.api.nvim_get_current_win()

  self:closeRunner(bufname)
  vim.cmd(prefix)
  vim.fn.termopen(command)
  vim.cmd("norm G")

  vim.opt_local.relativenumber = false
  vim.opt_local.number = false
  vim.cmd(bufname)
  vim.api.nvim_buf_set_option(0, "filetype", "crunner")

  if prefix ~= "tabnew" then
    vim.bo.buflisted = false
  end

  if self.opt.focus then
    vim.cmd(self.opt.insert_prefix)
  else
    vim.fn.win_gotoid(current_win_id)
  end

  if self.opt.hot_reload then
    local id = au_cd.create_on_write(function()
      self:execute(command, bufname, prefix)
    end, vim.fn.expand("%:p"))
    utils.create_stop_hot_reload(id)
  end
end

function Utils:betterTermM(command)
  local ok, betterTerm = pcall(require, "betterTerm")
  if ok then
    self.btm_number = self.opt.better_term.number or (self.btm_number + 1)
    betterTerm.send(command, self.btm_number, { clean = self.opt.clean })
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

function Utils:getModes()
  return {
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
      self:betterTermM(command)
    end,
    toggleterm = function(command)
      vim.cmd(string.format('TermExec cmd="%s"', command))
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
return Utils
