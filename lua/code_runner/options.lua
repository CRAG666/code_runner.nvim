local options = {
  -- choose default mode (valid term, tab, float, toggle)
  mode = "term",
  -- Focus on runner window(only works on toggle, term and tab mode)
  focus = true,
  -- startinsert (see ':h inserting-ex')
  startinsert = false,
  insert_prefix = "",
  term = {
    --  Position to open the terminal, this option is ignored if mode ~= term
    position = "bot",
    -- window size, this option is ignored if mode == tab
    size = 12,
  },
  float = {
    close_key = "<ESC>",
    -- Window border (see ':h nvim_open_win')
    border = "none",

    -- Num from `0 - 1` for measurements
    height = 0.8,
    width = 0.8,
    x = 0.5,
    y = 0.5,

    -- Highlight group for floating window/border (see ':h winhl')
    border_hl = "FloatBorder",
    float_hl = "Normal",

    -- Transparency (see ':h winblend')
    blend = 0,
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
---@param user_options table
M.set = function(user_options)
  if user_options.startinsert then
    user_options.insert_prefix = "startinsert"
  end
  options = vim.tbl_deep_extend("force", options, user_options)
  options.filetype = vim.tbl_map(concat, options.filetype)
  options.prefix = string.format("%s %d new", options.term.position, options.term.size)
end

M.get = function()
  return options
end

return M
