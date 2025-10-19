local au = require("code_runner.hooks.autocmd")
local notify = require("code_runner.hooks.notify")
local utils = require("code_runner.hooks.utils")

local function replaceElement(table, replacement_table)
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
  -- 5. Improved error handling
  local on_exit = function(obj)
    if obj.code > 0 then
      -- Show stderr on error
      notify.info("Errors during Compiling: " .. obj.stderr, command_config.command)
    else
      notify.info("Finished Compiling", command_config.command)
      utils.preview_open(to, command_config.preview_cmd)
    end
  end

  vim.system(
    vim.list_extend({ command_config.command }, command_config.args),
    { text = true },
    vim.schedule_wrap(on_exit)
  )
end

local active_table = {}

-- 4. Use augroup for VimLeave autocmd to avoid duplication
local augroup = vim.api.nvim_create_augroup("CodeRunnerPreviewPDF", { clear = true })

---@param command_config CommandConfig Table of options
local run = function(command_config)
  -- 1. Use local variables
  local bufnr = vim.api.nvim_get_current_buf()

  -- 6. Simplified active buffer check
  if not active_table[bufnr] then
    local fileName = vim.fn.expand("%:p")
    if fileName == nil or fileName == "" then
      notify.info("Cannot run on an empty buffer", command_config.command)
      return
    end

    local tmpFile = os.tmpname() .. ".pdf"
    if command_config.overwrite_output then
      tmpFile = command_config.overwrite_output .. "/" .. vim.fn.fnamemodify(fileName, ":t:r") .. ".pdf"
    end

    replaceElement(command_config.args, {
      ["$fileName"] = fileName,
      ["$tmpFile"] = tmpFile,
    })

    -- 1. Use local function
    local fn = function()
      convertToPdf(command_config, tmpFile)
    end

    notify.info("Start HotReload", command_config.command)
    convertToPdf(command_config, tmpFile)

    -- 1. Use local variable
    local id = au.create_on_write(fn, fileName)
    active_table[bufnr] = id

    -- 4. Use augroup
    vim.api.nvim_create_autocmd("VimLeave", {
      group = augroup,
      callback = function()
        utils.preview_close()
      end,
    })
  else
    -- 3. Use dynamic command name in notification
    notify.info("Stop HotReload", command_config.command)
    au.stop(active_table[bufnr])
    -- 2. Clear the entry from the active table
    active_table[bufnr] = nil
  end
end

return {
  run = run,
}
