local au = require("code_runner.hooks.autocmd")
local notify = require("code_runner.hooks.notify")
local utils = require("code_runner.hooks.utils")

function replaceElement(table, replacement_table)
  for i, value in ipairs(table) do
    if replacement_table[value] then
      table[i] = replacement_table[value]
    end
  end
end

---@class CommandConfig
---@field command string Prefix used to identify the terminals created
---@field args table Terminal window position
---@field preview_cmd string Window size
---@field overwrite_output string? Path where the file with the same name is saved

---@param command_config CommandConfig
---@param to string
local function convertToPdf(command_config, to)
  local on_exit = function(obj)
    if obj.code > 0 then
      notify.info("Errors during Compiling but not tracked", "Tectonic")
    else
      notify.info("Finished Compiling", command_config.command)
      utils.preview_open(to, command_config.preview_cmd)
    end
  end

  vim.system(vim.list_extend({ command_config.command }, command_config.args), {}, vim.schedule_wrap(on_exit))
end

local active_table = {}

---@param command_config CommandConfig Table of options
local run = function(command_config)
  bufnr = vim.api.nvim_get_current_buf()
  if vim.tbl_isempty(active_table) or vim.tbl_get(active_tamble, bufnr) then
    local fileName = vim.fn.expand("%:p")
    if fileName == nil then
      return
    end

    local tmpFile = os.tmpname() .. ".pdf"
    if command_config.overwrite_output ~= nil then
      tmpFile = command_config.overwrite_output .. "/" .. vim.fn.fnamemodify(fileName, ":t:r") .. ".pdf"
    end

    replaceElement(command_config.args, {
      ["$fileName"] = fileName,
      ["$tmpFile"] = tmpFile,
    })

    local fn = function()
      convertToPdf(command_config, tmpFile)
    end
    notify.info("Start HotReload", command_config.command)
    convertToPdf(command_config, tmpFile)
    id = au.create_on_write(fn, fileName)
    active_table[bufnr] = id
    vim.api.nvim_create_autocmd("VimLeave", {
      callback = function()
        utils.preview_close()
      end,
    })
  else
    notify.info("Stop HotReload", "Tectonic")
    au.stop(active_table[bufnr])
  end
end

return {
  run = run,
}
