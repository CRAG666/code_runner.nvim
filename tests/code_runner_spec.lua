-- Minimal, dependency-free test suite for code_runner.nvim.
-- Run with:
--   nvim --headless -u NONE --cmd "set rtp+=$PWD" -l tests/code_runner_spec.lua
-- Exits with a non-zero status if any assertion fails.
--
-- Covers everything that runs without opening a terminal: json loading,
-- option resolution, variable substitution, filetype/project command
-- building, root detection and the public API. Terminal/float/hook
-- execution paths are intentionally out of scope.

vim.opt.runtimepath:append(vim.fn.getcwd())

local Options = require("code_runner.options")
local Utils = require("code_runner.utils")
local Project = require("code_runner.project")
local FileType = require("code_runner.filetype")
local load_json = require("code_runner.load_json")

local results = { pass = 0, fail = 0 }

local function check(cond, msg)
  if cond then
    results.pass = results.pass + 1
  else
    results.fail = results.fail + 1
    print("  FAIL: " .. msg)
  end
end

local function eq(got, want, msg)
  check(got == want, string.format("%s\n    expected: %s\n    got:      %s", msg, vim.inspect(want), vim.inspect(got)))
end

local function contains(haystack, needle, msg)
  check(type(haystack) == "string" and haystack:find(needle, 1, true) ~= nil, msg .. " (got: " .. tostring(haystack) .. ")")
end

-- Fresh temp dir. Every test uses its own so that project entries accumulated
-- in the Options singleton by earlier tests can never match by accident.
local function tmpdir(subpath)
  local dir = vim.fn.tempname() .. (subpath and ("/" .. subpath) or "")
  vim.fn.mkdir(dir, "p")
  return dir
end

-- Run fn while capturing vim.notify calls; returns the captured list.
local function with_notify(fn)
  local captured = {}
  local orig = vim.notify
  vim.notify = function(msg, level)
    captured[#captured + 1] = { msg = msg, level = level }
  end
  local ok, err = pcall(fn)
  vim.notify = orig
  check(ok, "no error inside with_notify: " .. tostring(err))
  return captured
end

local function write_file(path, lines)
  vim.fn.writefile(lines, path)
  return path
end

-- ---------------------------------------------------------------------------
-- load_json
-- ---------------------------------------------------------------------------
print("load_json")
do
  local dir = tmpdir()
  local good = write_file(dir .. "/good.json", { '{ "a": 1, "b": "two" }' })
  local bad = write_file(dir .. "/bad.json", { "{ not json !" })

  local t = load_json(good)
  eq(type(t), "table", "valid json decodes to a table")
  eq(t and t.a, 1, "decoded values are accessible")
  eq(load_json(bad), nil, "invalid json returns nil instead of raising")
  eq(load_json(dir .. "/missing.json"), nil, "missing file returns nil")
end

-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------
print("options")
do
  local opt = Options.get()
  eq(opt.mode, "term", "default mode is term")
  eq(opt.prefix, "", "prefix is empty before setup")
  check(#opt.root_markers > 0, "root_markers has defaults")

  Options.set({ startinsert = true })
  eq(Options.get().insert_prefix, "startinsert", "startinsert=true sets insert_prefix")

  Options.set({ term = { position = "vert", size = 33 } })
  eq(Options.get().prefix, "vert 33 new", "prefix is built from term position and size")

  -- Table commands are concatenated into a single string.
  Options.set({ filetype = { fake_ft = { "cd $dir &&", "run $fileName" } } })
  eq(Options.get().filetype.fake_ft, "cd $dir && run $fileName", "table filetype commands are concatenated")

  -- A user root_markers list replaces the defaults entirely (no index merge).
  local defaults = Options.get().root_markers
  Options.set({ root_markers = { { "onlymarker", "echo only" } } })
  eq(#Options.get().root_markers, 1, "user root_markers replaces the default list")
  Options.set({ root_markers = defaults })
end

print("options: lazy json config")
do
  local dir = tmpdir()
  local ft_json = write_file(dir .. "/filetypes.json", { '{ "crystal": ["crystal", "run"] }' })
  local pr_root = tmpdir("lazyproj")
  local pr_json = write_file(dir .. "/projects.json", {
    string.format('{ "%s": { "name": "lazy", "command": "echo lazy" } }', pr_root),
  })

  Options.set({ filetype_path = ft_json, project_path = pr_json })
  local opt = Options.get()
  eq(opt.filetype.crystal, "crystal run", "filetype json is loaded lazily and concatenated on get()")
  eq(opt.project[pr_root] and opt.project[pr_root].name, "lazy", "project json is loaded lazily on get()")

  -- A broken json path notifies an error instead of raising.
  local bad = write_file(dir .. "/broken.json", { "nope{" })
  Options.set({ filetype_path = bad, filetype = {} })
  local notes = with_notify(function()
    Options.get()
  end)
  check(#notes > 0 and notes[1].level == vim.log.levels.ERROR, "broken json config notifies an error")
end

-- ---------------------------------------------------------------------------
-- Variable substitution (Utils:replaceVars)
-- ---------------------------------------------------------------------------
print("replaceVars")
do
  local u = Utils.new(Options.get())
  local path = "/home/foo/bar.py"

  contains(u:replaceVars("python $fileName", path), "'bar.py'", "$fileName expands to the escaped basename")
  contains(u:replaceVars("run $fileNameWithoutExt", path), "'bar'", "$fileNameWithoutExt drops the extension")
  contains(u:replaceVars("cd $dir", path), "'/home/foo'", "$dir expands to the escaped parent dir")
  contains(u:replaceVars("cat $file", path), "'/home/foo/bar.py'", "$file expands to the escaped full path")
  eq(u:replaceVars("end$end here", path), "end here", "$end expands to empty string")

  -- A command without any variable gets the file path appended.
  contains(u:replaceVars("cat", path), "cat '/home/foo/bar.py'", "no-var command gets the path appended")

  -- Unknown variables are left untouched.
  contains(u:replaceVars("echo $unknown", path), "$unknown", "unknown variables are preserved")

  -- Function commands: receive the user argument, may return string or table.
  u:setUserArgument({ flag = "--fast" })
  local as_string = u:replaceVars(function(arg)
    return "run " .. arg.flag .. " $fileName"
  end, path)
  contains(as_string, "--fast", "function command receives the user argument")
  contains(as_string, "'bar.py'", "function command result goes through substitution")

  local as_table = u:replaceVars(function()
    return { "cd $dir &&", "make" }
  end, path)
  contains(as_table, "cd '/home/foo' && make", "function command may return a table of parts")

  eq(
    u:replaceVars(function()
      return 42
    end, path),
    nil,
    "function command returning a non string/table yields nil"
  )
end

-- ---------------------------------------------------------------------------
-- Utils: getCommand / runMode
-- ---------------------------------------------------------------------------
print("utils")
do
  local u = Utils.new(Options.get())

  contains(u:getCommand("python", "/tmp/x.py"), "python -u '/tmp/x.py'", "getCommand builds the filetype command")
  eq(u:getCommand("no_such_ft", "/tmp/x.zz"), nil, "getCommand returns nil for unmapped filetypes")

  for _, mode in ipairs({ "term", "tab", "float", "better_term", "toggleterm", "vimux", "snacks", "quickfix" }) do
    eq(type(u.modes[mode]), "function", "mode '" .. mode .. "' is registered")
  end

  local notes = with_notify(function()
    u:runMode("echo hi", "bufname", "not_a_mode")
  end)
  check(#notes > 0 and notes[1].level == vim.log.levels.WARN, "runMode warns on an unknown mode")

  -- Modes backed by optional plugins notify an error when the plugin is absent.
  for _, mode in ipairs({ "toggleterm", "snacks" }) do
    local plugin_notes = with_notify(function()
      u:runMode("echo hi", "bufname", mode)
    end)
    check(
      #plugin_notes > 0 and plugin_notes[1].level == vim.log.levels.ERROR,
      "mode '" .. mode .. "' errors when its plugin is missing"
    )
  end

  -- With snacks installed (stubbed), the command is forwarded to its terminal.
  local opened
  package.loaded["snacks.terminal"] = {
    open = function(cmd, opts)
      opened = { cmd = cmd, opts = opts }
    end,
  }
  u:runMode("echo snack", "bufname", "snacks")
  package.loaded["snacks.terminal"] = nil
  eq(opened and opened.cmd, "echo snack", "snacks mode forwards the command to Snacks.terminal.open")
  eq(opened and opened.opts.auto_close, false, "snacks terminal stays open after the command exits")
end

-- ---------------------------------------------------------------------------
-- Quickfix mode (dispatch-style error handling)
-- ---------------------------------------------------------------------------
print("quickfix mode")
do
  local u = Utils.new(Options.get())
  local dir = tmpdir()

  -- Errors in the output land in the quickfix list and are parsed with the
  -- buffer-local errorformat.
  vim.cmd("edit " .. dir .. "/qf_src.py")
  vim.bo.errorformat = "%f:%l: %m"
  u:runMode("printf 'qf_src.py:3: boom\\n'; exit 1", "qf", "quickfix")
  local ok = vim.wait(3000, function()
    return vim.fn.getqflist({ title = 1 }).title:find("qf_src", 1, true) ~= nil
  end)
  check(ok, "quickfix list is populated after the command exits")
  local items = vim.fn.getqflist()
  eq(#items, 1, "one entry parsed from the error output")
  eq(items[1] and items[1].lnum, 3, "line number is parsed via errorformat")
  contains(items[1] and items[1].text, "boom", "error text is kept")
  eq(items[1] and items[1].valid, 1, "the entry is a valid error")
  check(vim.fn.getwininfo and #vim.tbl_filter(function(w)
    return w.quickfix == 1
  end, vim.fn.getwininfo()) > 0, "quickfix window opens when there are errors")
  vim.cmd("cclose")

  -- Real compiler errors: gcc output parsed with gcc's errorformat.
  if vim.fn.executable("gcc") == 1 then
    local cdir = tmpdir()
    write_file(cdir .. "/bad.c", {
      "int main(void) {",
      "  return x;", -- 'x' is undeclared: error at line 2
      "}",
    })
    vim.cmd("edit " .. cdir .. "/bad.c")
    vim.bo.errorformat = "%f:%l:%c: %t%*[^:]: %m"
    u:runMode("cd " .. cdir .. " && gcc bad.c -o bad", "qf", "quickfix")
    local compiled = vim.wait(5000, function()
      return vim.fn.getqflist({ title = 1 }).title:find("gcc bad.c", 1, true) ~= nil
    end)
    check(compiled, "quickfix list is populated from a real gcc run")
    local errors = vim.tbl_filter(function(i)
      return i.valid == 1
    end, vim.fn.getqflist())
    check(#errors > 0, "gcc errors produce valid quickfix entries")
    local first = errors[1] or {}
    eq(first.lnum, 2, "gcc error points at the offending line")
    eq(vim.fn.bufname(first.bufnr or -1):find("bad.c", 1, true) ~= nil, true, "gcc error points at the source file")
    check(first.col > 0, "gcc error carries a column")
    contains(first.text, "x", "gcc error message mentions the undeclared symbol")
    vim.cmd("cclose")
  else
    print("  SKIP: gcc not available, real-compiler quickfix test skipped")
  end

  -- Relative paths in the output (lualatex's "./main.tex:3: ...") resolve
  -- against the dir of the command's leading `cd`, not Neovim's cwd.
  local texroot = tmpdir()
  write_file(texroot .. "/main.tex", { "\\documentclass{article}" })
  vim.cmd("edit " .. texroot .. "/main.tex")
  vim.bo.errorformat = "%f:%l: %m"
  local nvim_cwd = vim.fn.getcwd()
  u:runMode("cd '" .. texroot .. "' && printf './main.tex:3: Undefined control sequence.\\n'; exit 12", "qf", "quickfix")
  local resolved = vim.wait(3000, function()
    return vim.fn.getqflist({ title = 1 }).title:find(texroot, 1, true) ~= nil
  end)
  check(resolved, "quickfix list is populated for cd-prefixed commands")
  local rel_items = vim.tbl_filter(function(i)
    return i.valid == 1
  end, vim.fn.getqflist())
  eq(#rel_items, 1, "relative path from the command's dir yields a valid entry")
  contains(vim.fn.fnamemodify(vim.fn.bufname(rel_items[1] and rel_items[1].bufnr or -1), ":p"), texroot, "entry resolves inside the command's dir")
  eq(vim.fn.getcwd(), nvim_cwd, "neovim's cwd is restored after parsing")
  vim.cmd("cclose")

  -- A failing command with no parseable errors warns instead of opening
  -- the quickfix window with noise (e.g. latexmk failing while up-to-date).
  vim.cmd("edit " .. dir .. "/qf_noise.py")
  vim.bo.errorformat = "%f:%l: %m"
  local warn_captured = {}
  local orig_warn_notify = vim.notify
  vim.notify = function(msg, level)
    warn_captured[#warn_captured + 1] = { msg = msg, level = level }
  end
  u:runMode("printf 'Latexmk: Nothing to do\\n'; exit 12", "qf", "quickfix")
  local warned = vim.wait(3000, function()
    return #warn_captured > 0
  end)
  vim.notify = orig_warn_notify
  check(warned and warn_captured[1].level == vim.log.levels.WARN, "unparseable failure warns instead of opening quickfix")
  contains(warn_captured[1] and warn_captured[1].msg, "exit 12", "the warning reports the exit code")
  eq(#vim.tbl_filter(function(w)
    return w.quickfix == 1
  end, vim.fn.getwininfo()), 0, "quickfix window stays closed on unparseable failure")

  -- A clean run notifies success and does not open the quickfix window.
  vim.cmd("edit " .. dir .. "/qf_ok.py")
  vim.bo.errorformat = "%f:%l: %m"
  local captured = {}
  local orig_notify = vim.notify
  vim.notify = function(msg, level)
    captured[#captured + 1] = { msg = msg, level = level }
  end
  u:runMode("printf 'all good\\n'", "qf", "quickfix")
  local notified = vim.wait(3000, function()
    return #captured > 0
  end)
  vim.notify = orig_notify
  check(notified and captured[1].level == vim.log.levels.INFO, "successful run notifies instead of opening quickfix")
  eq(#vim.tbl_filter(function(w)
    return w.quickfix == 1
  end, vim.fn.getwininfo()), 0, "quickfix window stays closed on success")
end

-- ---------------------------------------------------------------------------
-- FileType
-- ---------------------------------------------------------------------------
print("filetype")
do
  local dir = tmpdir()

  -- getCommand reads the current buffer's filetype.
  vim.cmd("edit " .. dir .. "/script.py")
  vim.bo.filetype = "python"
  local ft = FileType.new(Utils.new(Options.get()))
  contains(ft:getCommand(), "python -u", "getCommand uses the buffer filetype")

  vim.cmd("edit " .. dir .. "/unknown.zzz")
  vim.bo.filetype = "zzz"
  eq(FileType.new(Utils.new(Options.get())):getCommand(), "", "unmapped filetype yields an empty command")

  -- Native neovim files run through :luafile/:source instead of a terminal.
  local lua_file = write_file(dir .. "/native.lua", { "_G.__code_runner_native_ran = true" })
  vim.cmd("edit " .. lua_file)
  vim.bo.filetype = "lua"
  FileType.new(Utils.new(Options.get())):run()
  eq(_G.__code_runner_native_ran, true, "lua files are executed with :luafile")
  _G.__code_runner_native_ran = nil

  -- runFromFn expands variables against the current file.
  vim.cmd("edit " .. dir .. "/from_fn.txt")
  local u = Utils.new(Options.get())
  local ran
  u.runMode = function(_, command)
    ran = command
  end
  FileType.new(u):runFromFn({ "echo", "$fileName" })
  contains(ran, "'from_fn.txt'", "runFromFn substitutes variables from the current buffer")
end

-- ---------------------------------------------------------------------------
-- Project longest-prefix matching (Project)
-- ---------------------------------------------------------------------------
print("project matching")
do
  local root = tmpdir()
  local sub = root .. "/sub"
  vim.fn.mkdir(sub, "p")

  Options.set({
    project = {
      [root] = { name = "root_proj", command = "echo root" },
      [sub] = { name = "sub_proj", command = "echo sub", mode = "float" },
    },
  })

  -- Editing a file under the nested dir must select the most specific project.
  vim.cmd("edit " .. sub .. "/file.txt")
  local project = Project.new(Utils.new(Options.get()))
  project:setRootPath()

  check(project.context ~= nil, "a project context is found for a file inside a project")
  eq(project.context and project.context.name, "sub_proj", "longest prefix wins (nested over parent)")
  eq(project.context and project.context.mode, "float", "the project mode is kept in the context")
  contains(project:getCommand(), "cd " .. sub .. " && echo sub", "command is prefixed with cd <root>")
  eq(project:getCommand(), project:getCommand(), "getCommand is idempotent (no double cd prefix)")

  -- The resolved context is reused while staying inside the same root.
  local ctx = project.context
  vim.cmd("edit " .. sub .. "/other.txt")
  project:setRootPath()
  check(project.context == ctx, "context is cached while inside the same project root")
  eq(project.last_path, sub, "last_path tracks the current buffer dir")

  -- A file outside any configured project (and without markers) yields no context.
  vim.cmd("edit " .. tmpdir() .. "/outside.txt")
  local orphan = Project.new(Utils.new(Options.get()))
  orphan:setRootPath()
  eq(orphan.context, nil, "no context for a path outside every project")

  -- Project:run reports failure and notifies when there is no project.
  local notes = with_notify(function()
    eq(Project.new(Utils.new(Options.get())):run(), false, "run() returns false without a project")
  end)
  check(#notes > 0 and notes[1].level == vim.log.levels.WARN, "run() warns when no project matches")
end

-- ---------------------------------------------------------------------------
-- Root marker detection (pom.xml, .crproject.json, ...)
-- ---------------------------------------------------------------------------
print("root detection")
do
  local root = tmpdir()
  local sub = root .. "/src/main"
  vim.fn.mkdir(sub, "p")
  write_file(root .. "/pom.xml", { "<project/>" })

  -- A pom.xml in an ancestor dir is detected as a maven project.
  vim.cmd("edit " .. sub .. "/App.java")
  local detected = Project.new(Utils.new(Options.get()))
  contains(detected:getCommand(), "cd " .. root .. " && mvn", "pom.xml root marker yields mvn command")
  eq(detected.context and detected.context.name, "pom.xml", "detected project is named after the marker")

  -- The nearest ancestor with a marker wins over an outer one.
  local nested = root .. "/tools/gomod"
  vim.fn.mkdir(nested, "p")
  write_file(nested .. "/go.mod", { "module x" })
  vim.cmd("edit " .. nested .. "/main.go")
  local nearest = Project.new(Utils.new(Options.get()))
  contains(nearest:getCommand(), "cd " .. nested .. " && go run", "nearest ancestor marker wins")

  -- Two markers in the same dir: root_markers list order decides.
  local multi = tmpdir()
  write_file(multi .. "/Cargo.toml", { "[package]" })
  write_file(multi .. "/Makefile", { "all:" })
  vim.cmd("edit " .. multi .. "/main.rs")
  local ordered = Project.new(Utils.new(Options.get()))
  contains(ordered:getCommand(), "cargo run", "marker priority follows root_markers order")

  -- A local .crproject.json beats the marker in the same root.
  write_file(root .. "/.crproject.json", { '{ "name": "local", "command": "echo local", "mode": "float" }' })
  vim.cmd("edit " .. sub .. "/Other.java")
  local localcfg = Project.new(Utils.new(Options.get()))
  contains(localcfg:getCommand(), "cd " .. root .. " && echo local", ".crproject.json overrides root markers")
  eq(localcfg.context and localcfg.context.name, "local", "name comes from the local config file")
  eq(localcfg.context and localcfg.context.mode, "float", "mode comes from the local config file")

  -- A local config with file_name expands variables against that file.
  local with_file = tmpdir()
  write_file(with_file .. "/main.py", { "print(1)" })
  write_file(with_file .. "/.crproject.json", { '{ "name": "wf", "command": "run $fileName", "file_name": "main.py" }' })
  vim.cmd("edit " .. with_file .. "/notes.txt")
  contains(Project.new(Utils.new(Options.get())):getCommand(), "run 'main.py'", "file_name from local config feeds substitution")

  -- An invalid local config notifies an error and yields no context.
  local broken = tmpdir()
  write_file(broken .. "/.crproject.json", { '{ "name": "no command here" }' })
  vim.cmd("edit " .. broken .. "/x.txt")
  local invalid = Project.new(Utils.new(Options.get()))
  local notes = with_notify(function()
    invalid:setRootPath()
  end)
  eq(invalid.context, nil, "invalid local config yields no context")
  check(#notes > 0 and notes[1].level == vim.log.levels.ERROR, "invalid local config notifies an error")

  -- A manually configured project beats any detection.
  Options.set({ project = { [root] = { name = "manual", command = "echo manual" } } })
  vim.cmd("edit " .. sub .. "/Third.java")
  contains(Project.new(Utils.new(Options.get())):getCommand(), "echo manual", "configured project wins over detection")

  -- Custom markers replace the defaults.
  local custom = tmpdir()
  write_file(custom .. "/mymarker", { "" })
  write_file(custom .. "/pom.xml", { "<project/>" })
  local defaults = Options.get().root_markers
  Options.set({ root_markers = { { "mymarker", "echo custom" } } })
  vim.cmd("edit " .. custom .. "/a.txt")
  contains(Project.new(Utils.new(Options.get())):getCommand(), "echo custom", "custom markers are honored")
  Options.set({ root_markers = {} })
  vim.cmd("edit " .. custom .. "/b.txt")
  local disabled = Project.new(Utils.new(Options.get()))
  disabled:setRootPath()
  eq(disabled.context, nil, "empty root_markers disables marker detection")
  Options.set({ root_markers = defaults })

  -- No marker, no config: no context.
  vim.cmd("edit " .. tmpdir() .. "/lonely.txt")
  local orphan = Project.new(Utils.new(Options.get()))
  orphan:setRootPath()
  eq(orphan.context, nil, "no context without markers or config")
end

-- ---------------------------------------------------------------------------
-- Project watch (re-run on write)
-- ---------------------------------------------------------------------------
print("project watch")
do
  local root = tmpdir()
  write_file(root .. "/.crproject.json", { '{ "name": "watched", "command": "echo w", "watch": true }' })
  vim.cmd("silent edit " .. root .. "/main.txt")

  local u = Utils.new(Options.get())
  local runs = 0
  u.runMode = function()
    runs = runs + 1
  end

  eq(Project.new(u):run(nil, false), true, "watched project runs")
  eq(runs, 1, "first run executes the command")

  vim.cmd("silent write")
  eq(runs, 2, "a write under the root re-runs the command")

  vim.cmd("edit " .. tmpdir() .. "/outside.txt")
  vim.cmd("silent write")
  eq(runs, 2, "writes outside the root do not re-run")

  -- Running the project again toggles the watcher off without re-running.
  vim.cmd("silent edit " .. root .. "/main.txt")
  eq(Project.new(u):run(nil, false), true, "toggle-stop still reports success")
  eq(runs, 2, "toggle-stop does not execute the command")
  vim.cmd("silent write")
  eq(runs, 2, "after stopping, writes no longer re-run")
end

-- ---------------------------------------------------------------------------
-- Public API (commands.lua and setup)
-- ---------------------------------------------------------------------------
print("public api")
do
  local commands = require("code_runner.commands")

  local root = tmpdir()
  Options.set({ project = { [root] = { name = "api_proj", command = "echo api" } } })
  vim.cmd("edit " .. root .. "/api.txt")
  contains(commands.get_project_command(), "echo api", "get_project_command resolves the current project")

  vim.cmd("edit " .. tmpdir() .. "/api.py")
  vim.bo.filetype = "python"
  contains(commands.get_filetype_command(), "python -u", "get_filetype_command resolves the buffer filetype")

  local modes = commands.get_modes()
  eq(type(modes.term), "function", "get_modes exposes the mode table")

  require("code_runner").setup({})
  for _, cmd in ipairs({ "RunCode", "RunFile", "RunProject", "RunClose", "CRFiletype", "CRProjects" }) do
    eq(vim.fn.exists(":" .. cmd), 2, "setup creates the :" .. cmd .. " command")
  end
  for _, fn in ipairs({ "run_code", "run_from_fn", "run_filetype", "run_project", "run_close", "get_filetype_command", "get_project_command" }) do
    eq(type(require("code_runner")[fn]), "function", "setup exposes " .. fn .. "()")
  end
end

-- ---------------------------------------------------------------------------
print(string.format("\n%d passed, %d failed", results.pass, results.fail))
if results.fail > 0 then
  vim.cmd("cquit 1")
end
