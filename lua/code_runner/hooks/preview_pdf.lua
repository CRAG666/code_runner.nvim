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
---@field args string Terminal window position
---@field preview_cmd string Window size
---@field overwrite_output string? Path where the file with the same name is saved

---@param command_config CommandConfig
---@param to string
---@param open boolean?
local function convertToPdf(command_config, to)
  local on_exit = function(obj)
    if obj.code > 0 then
      notify.error("Error in compiling!!", "CodeRunner Hook")
      utils.preview_close()
    else
      notify.info("Finish compiling!!", "CodeRunner Hook")
      utils.preview_open(to, command_config.preview_cmd)
    end
  end

  vim.system(vim.list_extend(command_config.command, command_config.args), {}, vim.schedule_wrap(on_exit))
end

local active_talbe = {}

---@param command_config CommandConfig Table of options
local run = function(command_config)
  bufnr = vim.api.nvim_get_current_buf()
  if vim.tbl_isempty(active_talbe) or vim.tbl_get(active_tamble, bufnr) then
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
    id = au.create_on_write(fn, fileName)
    active_talbe[bufnr] = id
  else
    au.stop(active_talbe[bufnr])
  end
end

return {
  run = run,
}
