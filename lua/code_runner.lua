local o = require("code_runner.options")

local M = {}

local function setup(opt)
  -- Store user options. JSON config (filetype_path/project_path) is loaded
  -- lazily on first use, not here, to keep setup off the startup hot path.
  o.set(opt)
end

local function open_json(json_path)
  vim.cmd("tabnew " .. json_path)
end

local function completion(ArgLead, options)
  local filterd_args = vim.tbl_filter(function(v)
    return v:find(ArgLead:lower(), 1, true) == 1
  end, options)
  if not vim.tbl_isempty(filterd_args) then
    return filterd_args
  end
  return options
end

M.open_filetype_suported = function()
  open_json(o.get().filetype_path)
end

M.open_project_manager = function()
  open_json(o.get().project_path)
end

-- The mode list is static; building it pulls in the command chain, so we cache
-- it and only build it the first time :RunFile/:RunProject completion is used.
local modes_cache = nil
local function get_modes()
  if not modes_cache then
    modes_cache = vim.tbl_keys(require("code_runner.commands").get_modes())
  end
  return modes_cache
end

M.setup = function(user_options)
  setup(user_options or {})

  -- Simple commands lazily pull in the command module only when invoked.
  vim.api.nvim_create_user_command("RunClose", function()
    require("code_runner.commands").run_close()
  end, { nargs = 0 })
  vim.api.nvim_create_user_command("CRFiletype", M.open_filetype_suported, { nargs = 0 })
  vim.api.nvim_create_user_command("CRProjects", M.open_project_manager, { nargs = 0 })

  -- Commands with autocomplete.
  -- Format: CommandName = { command_fn_name, options_provider }
  local completion_cmds = {
    RunCode = {
      "run_code",
      function()
        return vim.tbl_keys(o.get().filetype)
      end,
    },
    RunFile = { "run_filetype", get_modes },
    RunProject = { "run_project", get_modes },
  }
  for cmd, cmo in pairs(completion_cmds) do
    vim.api.nvim_create_user_command(cmd, function(opts)
      require("code_runner.commands")[cmo[1]](unpack(opts.fargs))
    end, {
      nargs = "*",
      complete = function(ArgLead, word, ...)
        -- only complete the first argument
        if #vim.split(word, "%s+") > 2 then
          return
        end
        return completion(ArgLead, cmo[2]())
      end,
    })
  end

  -- Public API as thin lazy wrappers, so requiring this module never pulls in
  -- the heavier command/filetype/project/utils chain on its own.
  M.run_code = function(...)
    return require("code_runner.commands").run_code(...)
  end
  M.run_from_fn = function(...)
    return require("code_runner.commands").run_from_fn(...)
  end
  M.run_filetype = function(...)
    return require("code_runner.commands").run_filetype(...)
  end
  M.run_project = function(...)
    return require("code_runner.commands").run_project(...)
  end
  M.run_close = function(...)
    return require("code_runner.commands").run_close(...)
  end
  M.get_filetype_command = function(...)
    return require("code_runner.commands").get_filetype_command(...)
  end
  M.get_project_command = function(...)
    return require("code_runner.commands").get_project_command(...)
  end

  if o.get_raw().hot_reload then
    local id = require("code_runner.hooks.autocmd").create_on_write(function(...)
      require("code_runner.commands").run_code()
    end)
    require("code_runner.hooks.utils").create_stop_hot_reload(id)
  end
end

return M
