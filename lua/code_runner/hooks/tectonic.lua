local utils = require("code_runner.hooks.utils")
local notify = require("code_runner.hooks.notify")
local autocmd = require("code_runner.hooks.autocmd")
local pdf_path = ""
local cmd = ""

local on_exit = function(obj)
  if obj.code == 0 then
    vim.cmd("cclose")
    vim.fn.setqflist({}, "r", { title = "Tectonic Errors", items = {} })
    notify.info("Finished Compiling", "Tectonic")
    utils.preview_open(pdf_path, cmd)
    return
  end
  local lines = vim.split(obj.stderr, "\n", { trimempty = true })
  local error_lines = {}
  local error_pattern = "error:%s+(%S+):(%d+):%s+(.*)"
  local warning_pattern = "warning: (.+)"

  local i = #lines
  while i > 0 do
    if lines[i]:match(warning_pattern) then
      break
    end
    local file, lnum, message = string.match(lines[i], error_pattern)
    if file and lnum and message then
      table.insert(error_lines, {
        filename = file,
        lnum = tonumber(lnum),
        col = 1,
        text = message,
        type = "E",
      })
    end
    i = i - 1
  end
  if #error_lines > 0 then
    notify.info("Errors during Compiling", "Tectonic")
    vim.fn.setqflist({}, "r", { title = "Tectonic Errors", items = error_lines })
    vim.cmd("copen")
  end
  notify.info("Errors during Compiling but not tracked", "Tectonic")
end

local M = {}

function M.build(preview_cmd, tectonic_args, root_patterns)
  root_patterns = root_patterns or { "Tectonic.toml" }
  cmd = preview_cmd
  tectonic_args = tectonic_args or {}
  if vim.g.tectonic_open == nil then
    notify.info("Start HotReload", "Tectonic")
    local root_path = vim.fs.root(0, root_patterns)
    local compile = { "tectonic", "-X", "build" }
    for _, arg in ipairs(tectonic_args) do
      table.insert(compile, arg)
    end
    pdf_path = root_path .. "/build/default/default.pdf"
    notify.info(root_path, "Tectonic")
    id = autocmd.create_on_write(function()
      notify.info("Compiling ...", "Tectonic")
      vim.system(compile, {}, vim.schedule_wrap(on_exit))
    end, "*.tex")

    vim.api.nvim_create_autocmd("VimLeave", {
      callback = function()
        utils.preview_close()
      end,
    })
    vim.g.tectonic_open = true
    vim.cmd("silent! w")
  else
    notify.info("Stop HotReload", "Tectonic")
    autocmd.stop(id)
    vim.g.tectonic_open = nil
  end
end

return M
