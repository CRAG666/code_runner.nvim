-- Minimal, dependency-free test suite for code_runner.nvim.
-- Run with:
--   nvim --headless -u NONE --cmd "set rtp+=$PWD" -l tests/code_runner_spec.lua
-- Exits with a non-zero status if any assertion fails.

vim.opt.runtimepath:append(vim.fn.getcwd())

local Options = require("code_runner.options")
local Utils = require("code_runner.utils")
local Project = require("code_runner.project")

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
  eq(u:replaceVars("end$end here", path), "end here", "$end expands to empty string")

  -- A command without any variable gets the file path appended.
  contains(u:replaceVars("cat", path), "cat '/home/foo/bar.py'", "no-var command gets the path appended")

  -- Unknown variables are left untouched.
  contains(u:replaceVars("echo $unknown", path), "$unknown", "unknown variables are preserved")
end

-- ---------------------------------------------------------------------------
-- Project longest-prefix matching (Project)
-- ---------------------------------------------------------------------------
print("project matching")
do
  local root = vim.fn.tempname()
  local sub = root .. "/sub"
  vim.fn.mkdir(sub, "p")

  Options.set({
    project = {
      [root] = { name = "root_proj", command = "echo root" },
      [sub] = { name = "sub_proj", command = "echo sub" },
    },
  })

  -- Editing a file under the nested dir must select the most specific project.
  vim.cmd("edit " .. sub .. "/file.txt")
  local project = Project.new(Utils.new(Options.get()))
  project:setRootPath()

  check(project.context ~= nil, "a project context is found for a file inside a project")
  eq(project.context and project.context.name, "sub_proj", "longest prefix wins (nested over parent)")
  contains(project:getCommand(), "cd " .. sub .. " && echo sub", "command is prefixed with cd <root>")

  -- A file outside any configured project yields no context.
  vim.cmd("edit " .. vim.fn.tempname() .. "/outside.txt")
  local orphan = Project.new(Utils.new(Options.get()))
  orphan:setRootPath()
  eq(orphan.context, nil, "no context for a path outside every project")
end

-- ---------------------------------------------------------------------------
print(string.format("\n%d passed, %d failed", results.pass, results.fail))
if results.fail > 0 then
  vim.cmd("cquit 1")
end
