local Job = require("plenary.job")
local commands = {}

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
local function convertToPdf(command_config, to, open)
  open = open or false
  Job:new({
    command = command_config.command,
    args = command_config.args,
    on_exit = vim.schedule_wrap(function(_, return_val)
      if return_val == 1 then
        vim.notify("Could not comvert to PDF", vim.log.levels.ERROR)
        return
      end

      if open then
        os.execute(command_config.preview_cmd .. " " .. to)
      end
    end),
  }):start()
end

local stop = function()
  local bufnr = vim.api.nvim_get_current_buf()
  if commands[bufnr] ~= nil then
    vim.api.nvim_del_autocmd(commands[bufnr])
  end
end

---@param command_config CommandConfig Table of options
local run = function(command_config)
  local bufnr = vim.api.nvim_get_current_buf()

  vim.api.nvim_create_user_command("PreviewPDFStop" .. bufnr, stop, {})

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

  local group = vim.api.nvim_create_augroup("PreviewPDF", { clear = true })
  local id = vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      convertToPdf(command_config, tmpFile)
    end,
  })

  commands[bufnr] = id

  convertToPdf(command_config, tmpFile, true)
end

return {
  run = run,
}
