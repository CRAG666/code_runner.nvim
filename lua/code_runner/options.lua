local options = {
  -- choose default mode (valid term, tab, float, better_term, toggle, vimux)
  mode = "term",
  -- add hot reload (Experimental)
  hot_reload = false,
  -- Focus on runner window(only works on term and tab mode)
  focus = true,
  -- startinsert (see ':h inserting-ex')
  startinsert = false,
  insert_prefix = "",
  -- For float mode: jump back to the previous window after opening the runner
  wincmd = false,
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
  before_run_filetype = function() end,
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
    ruby = "ruby",
    rust = {
      "cd $dir &&",
      "rustc $fileName &&",
      "$dir/$fileNameWithoutExt",
    },
  },
  project_path = "",
  project = {},
  -- Root markers checked upward from the current file when no configured
  -- project matches. Ordered: first marker found in the nearest ancestor wins.
  -- A ".crproject.json" file in the project root always takes priority.
  root_markers = {
    { "pom.xml", "mvn compile exec:java" },
    { "build.gradle", "./gradlew run" },
    { "Cargo.toml", "cargo run" },
    { "go.mod", "go run ." },
    { "package.json", "npm start" },
    { "Makefile", "make" },
    { "CMakeLists.txt", "cmake -B build && cmake --build build" },
  },
  prefix = "",
}

local M = {}

local function concat(v)
  if type(v) == "table" then
    return table.concat(v, " ")
  end
  return v
end

-- Paths to JSON config resolved lazily on first access, so reading and
-- decoding them stays off Neovim's startup path.
local pending_filetype_path = nil
local pending_project_path = nil

-- Resolve any pending JSON config. Memoized: each path is loaded at most once,
-- on the first M.get() that needs it (e.g. the first :RunCode or completion).
local function resolve_pending()
  if pending_filetype_path then
    local path = pending_filetype_path
    pending_filetype_path = nil
    local filetype = require("code_runner.load_json")(path)
    if filetype then
      options.filetype = vim.tbl_map(concat, vim.tbl_deep_extend("force", options.filetype, filetype))
    else
      require("code_runner.hooks.notify").error("Error trying to load filetypes commands", "Code Runner Error")
    end
  end
  if pending_project_path then
    local path = pending_project_path
    pending_project_path = nil
    local project = require("code_runner.load_json")(path)
    if project then
      options.project = vim.tbl_deep_extend("force", options.project, project)
    else
      require("code_runner.hooks.notify").error("Error trying to load project commands", "Code Runner Error")
    end
  end
end

---@param user_options table
M.set = function(user_options)
  if user_options.startinsert then
    user_options.insert_prefix = "startinsert"
  end
  -- Defer JSON loading to first use when the user only points at a path.
  if vim.tbl_isempty(user_options.filetype or {}) and (user_options.filetype_path or "") ~= "" then
    pending_filetype_path = user_options.filetype_path
  end
  if vim.tbl_isempty(user_options.project or {}) and (user_options.project_path or "") ~= "" then
    pending_project_path = user_options.project_path
  end
  options = vim.tbl_deep_extend("force", options, user_options)
  options.filetype = vim.tbl_map(concat, options.filetype)
  options.prefix = string.format("%s %d new", options.term.position, options.term.size)
end

-- Full options, resolving any deferred JSON config first. Use this whenever
-- filetype/project commands are needed.
M.get = function()
  resolve_pending()
  return options
end

-- Options without triggering JSON resolution. Use only for scalar settings that
-- never come from JSON (e.g. hot_reload), to avoid forcing a disk read.
M.get_raw = function()
  return options
end

return M
