local options = {
  -- startinsert (see ':h inserting-ex')
  startinsert = false,
  insert_prefix = ""
  -- choose default mode (valid term or float)
  mode="term",
  term = {
    --  Open in a new tab
    tab = false,
    --  Position to open the terminal, this option is ignored if tab is true
    position = "bot",
    -- window size, this option is ignored if tab is true
    size = 8,
  },
  float = {
    -- Window border (see ':h nvim_open_win')
    border    = "none",

    -- Num from `0 - 1` for measurements
    height    = 0.8,
    width     = 0.8,
    x         = 0.5,
    y         = 0.5,

    -- Highlight group for floating window/border (see ':h winhl')
    border_hl = "FloatBorder",
    float_hl  = "Normal",

    -- Transparency (see ':h winblend')
    blend     = 0
  },
  filetype_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/code_runner.nvim/lua/code_runner/code_runner.json",
  filetype = {},
  project_path = vim.fn.stdpath("data")
    .. "/site/pack/packer/start/code_runner.nvim/lua/code_runner/project_manager.json",
  project = {},
  prefix = "",
}

local M = {}
-- set user config
M.set = function(user_options)
  if user_options.startinsert then
    user_options.insert_prefix = "| :startinsert"
  end
  options = vim.tbl_deep_extend("force", options, user_options)
  if options.term.tab then
    options.prefix = "tabnew | term "
  else
    options.prefix = string.format("%s %d new | term ", options.term.position, options.term.size)
  end
end

M.get = function()
  return options
end

return M
