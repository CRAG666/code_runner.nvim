local au = require("code_runner.hooks.autocmd")
local notify = require("code_runner.hooks.notify")
local utils = require("code_runner.hooks.utils")

---@class CommandConfig
---@field command string Executable used to build the pdf
---@field args table Arguments. $fileName, $fileNameWithoutExt, $dir and $tmpFile are expanded inside each element.
---@field preview_cmd string Command used to open the resulting pdf
---@field overwrite_output string? Directory where <file>.pdf is written instead of a temp file

---@param command_config CommandConfig
---@param args table Already-expanded arguments.
---@param to string Path of the resulting pdf.
local function convertToPdf(command_config, args, to)
  local on_exit = function(obj)
    if obj.code ~= 0 then
      notify.error("Errors during compiling: " .. (obj.stderr or ""), command_config.command)
    else
      notify.info("Finished compiling", command_config.command)
      utils.preview_open(to, command_config.preview_cmd)
    end
  end

  vim.system(vim.list_extend({ command_config.command }, args), { text = true }, vim.schedule_wrap(on_exit))
end

-- Active hot reloads: bufnr -> autocmd id.
local active_table = {}

local augroup = vim.api.nvim_create_augroup("CodeRunnerPreviewPDF", { clear = true })

---@param command_config CommandConfig Table of options
local run = function(command_config)
  local bufnr = vim.api.nvim_get_current_buf()

  -- Toggle: calling run again on the same buffer stops its hot reload.
  if active_table[bufnr] then
    notify.info("Stop HotReload", command_config.command)
    au.stop(active_table[bufnr])
    active_table[bufnr] = nil
    return
  end

  local fileName = vim.fn.expand("%:p")
  if fileName == "" then
    notify.info("Cannot run on an empty buffer", command_config.command)
    return
  end

  local tmpFile
  if command_config.overwrite_output then
    tmpFile = command_config.overwrite_output .. "/" .. vim.fn.fnamemodify(fileName, ":t:r") .. ".pdf"
  else
    tmpFile = vim.fn.tempname() .. ".pdf"
  end

  -- Expand variables inside each argument, into a copy: the user's config
  -- table stays pristine so it can be reused across runs and buffers.
  local vars = {
    fileName = fileName,
    fileNameWithoutExt = vim.fn.fnamemodify(fileName, ":t:r"),
    dir = vim.fn.fnamemodify(fileName, ":p:h"),
    tmpFile = tmpFile,
  }
  local args = {}
  for i, arg in ipairs(command_config.args) do
    args[i] = (arg:gsub("%$(%w+)", function(var)
      return vars[var] or ("$" .. var)
    end))
  end

  notify.info("Start HotReload", command_config.command)
  convertToPdf(command_config, args, tmpFile)

  active_table[bufnr] = au.create_on_write(function()
    convertToPdf(command_config, args, tmpFile)
  end, fileName)

  vim.api.nvim_create_autocmd("VimLeave", {
    group = augroup,
    callback = function()
      utils.preview_close()
    end,
  })
end

return {
  run = run,
}
