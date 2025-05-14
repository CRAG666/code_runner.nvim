local notify = require("code_runner.hooks.notify")
local Singleton = require("code_runner.singleton")
local pattern = "crunner_"

-- Cache for variable replacement results
local var_cache = setmetatable({}, { __mode = "kv" }) -- weak cache table

local Utils = {}
Utils.__index = Utils

function Utils:ctor(opt)
  assert(opt, "opt is required")
  self.opt = opt
  self.btm_number = self.opt.better_term.init
  self._user_argument = {}

  -- Pre-initialize mode table to avoid recreating it each time
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
      if vim.fn.exists(":TermExec") == 2 then
        vim.cmd(string.format('TermExec cmd="%s"', command))
      else
        notify.error("The 'TermExec' does not exist.", "Toggleterm")
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
    end
  }
end

function Utils:setUserArgument(user_argument)
  self._user_argument = user_argument
end

function Utils:replaceVars(command, path)
  -- Process function commands
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

  -- Check if we already have the result cached
  local cache_key = command .. ":" .. path
  local cached = var_cache[cache_key]
  if cached then return cached end

  local no_sub_command = command

  -- Pre-calculate replacement values to avoid multiple vim.fn calls
  local file_info = {
    nameWithoutExt = vim.fn.fnamemodify(path, ":t:r"),
    name = vim.fn.fnamemodify(path, ":t"),
    dir = vim.fn.fnamemodify(path, ":p:h")
  }

  -- Use gsub once with a replacement function
  command = command:gsub("%$(%w+)", function(var)
    if var == "fileNameWithoutExt" then
      return file_info.nameWithoutExt
    elseif var == "fileName" then
      return file_info.name
    elseif var == "file" then
      return path
    elseif var == "dir" then
      return file_info.dir
    elseif var == "end" then
      return ""
    else
      return "$" .. var
    end
  end)

  if command == no_sub_command then
    command = command .. " " .. path
  end

  -- Store result in cache
  var_cache[cache_key] = command
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
  vim.fn.termopen(command)

  -- Group local operations
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_option(buf, "relativenumber", false)
  vim.api.nvim_buf_set_option(buf, "number", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "crunner")

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

return Singleton(Utils)
