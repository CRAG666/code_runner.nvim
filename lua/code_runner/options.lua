---@type CodeRunnerOptions
local default_options = {
  mode = "term", -- default display mode
  hot_reload = true, -- hot reload enabled/disabled
  focus = false, -- Focus window/viewport on the buffer (only works term and tab display mode)
  startinsert = false, -- startinsert (see ':h inserting-ex')
  insert_prefix = "", --  this key is controlled by startinsert
  term = { -- this configs are ignored if mode ~= "term"
    position = "vert", --  Position to open the terminal,
    size = 64, -- window size, if position 'bot'(bottom) 8 is a good default
  },
  float = {
    close_key = "<ESC>",
    border = "solid", -- Window border (see ':h nvim_open_win()' ; /border)

    height = 0.8,
    width = 0.8,
    x = 0.5,
    y = 0.5,

    border_hl = "FloatBorder", -- Highlight group for floating window/border (see ':h winhl')
    float_hl = "Normal",

    blend = 0, -- Transparency (see ':h winblend')
  },
  better_term = { -- Toggle mode replacement
    clean = false, -- Clean terminal before launch
    number = 10, -- Use nil for dynamic number and set init
    init = nil,
  },
  filetype_path = "",
  -- Execute before executing a file
  before_run_filetype = function()
    vim.cmd(":w")
  end,
  filetype = {
    javascript = "node",
    java = {
      "cd $dir &&",
      "javac $fileName &&",
      "java $fileNameWithoutExt",
    },
    c = {
      "cd $dir &&",
      "gcc $fileName",
      "-o $fileNameWithoutExt &&",
      "$dir/$fileNameWithoutExt",
    },
    cpp = {
      "cd $dir &&",
      "g++ $fileName",
      "-o $fileNameWithoutExt &&",
      "$dir/$fileNameWithoutExt",
    },
    python = "python -u",
    sh = "bash",
    rust = {
      "cd $dir &&",
      "rustc $fileName &&",
      "$dir/$fileNameWithoutExt",
    },
  },
  project_path = "",
  project = {},
  prefix = "",
}

local M = {}

local function concat(v)
  if type(v) == "table" then
    return table.concat(v, " ")
  end
  return v
end

-- set user config
---@param user_options CodeRunnerUserOptions
M.set = function(user_options)
  if user_options.startinsert then
    user_options.insert_prefix = "startinsert"
  end
  default_options = vim.tbl_deep_extend("force", default_options, user_options)
  default_options.filetype = vim.tbl_map(concat, default_options.filetype)
  default_options.prefix = string.format("%s %d new", default_options.term.position, default_options.term.size)
end

M.get = function()
  return default_options
end

return M
