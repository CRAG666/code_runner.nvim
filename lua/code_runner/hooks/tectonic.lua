local utils = require("code_runner.hooks.utils")
local notify = require("code_runner.hooks.notify")
local autocmd = require("code_runner.hooks.autocmd")
local pdf_path = ""
local cmd = ""

local on_exit = function(obj)
  -- Si hay errores (código > 0)
  if obj.code > 0 then
    notify.error("Error in compiling!!", "Tectonic")
    -- Dividir el stderr en líneas
    local lines = vim.split(obj.stderr, "\n", { trimempty = true })

    -- Filtrar y procesar las líneas que contienen "error:"
    local error_lines = {}
    for _, line in ipairs(lines) do
      -- Buscar el archivo, la línea y el mensaje
      local file, lnum, message = string.match(line, "error:%s+(%S+):(%d+):%s+(.*)")
      if file and lnum and message then
        table.insert(error_lines, {
          filename = file,
          lnum = tonumber(lnum),
          col = 1,
          text = message,
        })
      end
    end

    -- Enviar las líneas al quickfix list
    if #error_lines > 0 then
      vim.fn.setqflist({}, "r", { title = "Tectonic Errors", items = error_lines })
      utils.preview_close()
      vim.cmd("copen")
    end
  else
    -- Si no hay errores, limpiar el quickfix list
    vim.fn.setqflist({}, "r", { title = "Tectonic Errors", items = {} })
    notify.info("Finish compiling!!", "Tectonic")
    utils.preview_open(pdf_path, cmd)
  end
end

local tectonic_open = false

local M = {}

function M.build(preview_cmd, tectonic_args)
  cmd = preview_cmd
  tectonic_args = tectonic_args or {}
  notify.info("Start HotReload", "Tectonic")
  if tectonic_open == false then
    local root_path = vim.lsp.buf.list_workspace_folders()[1]
    local compile = { "tectonic", "-X", "build" }
    for _, arg in ipairs(tectonic_args) do
      table.insert(compile, arg)
    end
    pdf_path = root_path .. "/build/default/default.pdf"
    id = autocmd.create_on_write(function()
      notify.info("Compiling ...", "Tectonic")
      vim.system(compile, {}, vim.schedule_wrap(on_exit))
    end, root_path .. "/src/*.tex")

    vim.api.nvim_create_autocmd("VimLeave", {
      callback = function()
        utils.preview_close()
      end,
    })
    tectonic_open = true
    vim.cmd("silent! w")
  else
    notify.info("Stop HotReload", "Tectonic")
    autocmd.stop(id)
    tectonic_open = false
  end
end

return M
