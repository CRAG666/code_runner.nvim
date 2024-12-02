local utils = require("code_runner.hooks.utils")
local notify = require("code_runner.hooks.notify")

local on_exit = function(obj)
  -- Si hay errores (código > 0)
  if obj.code > 0 then
    -- Notificar el error
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
          filename = file, -- Archivo donde ocurre el error
          lnum = tonumber(lnum), -- Número de línea
          col = 1, -- Columna predeterminada (no proporcionada en el error)
          text = message, -- Mensaje del error
        })
      end
    end

    -- Enviar las líneas al quickfix list
    if #error_lines > 0 then
      vim.schedule(function()
        vim.fn.setqflist({}, "r", { title = "Tectonic Errors", items = error_lines })
        vim.cmd("copen")
      end)
    end
  else
    -- Si no hay errores, limpiar el quickfix list
    vim.schedule(function()
      vim.fn.setqflist({}, "r", { title = "Tectonic Errors", items = {} })
    end)

    -- Notificar que la compilación terminó
    notify.info("Finish compiling!!", "Tectonic")
  end
end

local tectonic_open = false

local M = {}

function M.build(cmd, args)
  args = args or {}
  if tectonic_open == false then
    local root_path = vim.lsp.buf.list_workspace_folders()[1]
    local compile = { "tectonic", "-X", "build" }
    for _, arg in ipairs(args) do
      table.insert(compile, arg)
    end
    local pdf_path = root_path .. "/build/default/default.pdf"
    vim.system(compile, { text = true }, on_exit)
    utils.preview_open(pdf_path, cmd)
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = root_path .. "/src/*.tex",
      callback = function()
        notify.info("Compiling ...", "Tectonic")
        utils.preview_open(pdf_path, cmd)
        vim.system(compile, { text = true }, on_exit)
      end,
    })

    vim.api.nvim_create_autocmd("VimLeave", {
      callback = function()
        utils.preview_close(pdf_path, cmd)
      end,
    })
    tectonic_open = true
  end
end

return M
