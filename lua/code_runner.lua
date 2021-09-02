local o = require("code_runner.options")
local commands = require("code_runner.commands")
local M = {}
-- Load json config and convert to table
local loadTable = require("code_runner.load_json")
M.setup = function(user_options)
  o.set(user_options)
  vim.cmd [[lua require('code_runner').load_json_files()]]
  vim.api.nvim_exec([[
  command! SRunCode lua require('code_runner').open_filetype_suported()
  command! CRprojects lua require('code_runner').open_project_manager()
  command! RunCode lua require('code_runner').run_code()
  command! RunFile lua require('code_runner').run_filetype()
  command! RunProject lua require('code_runner').run_project()
  ]], false)
  if o.get().filetype.map == o.get().project_context.map then
    vim.api.nvim_set_keymap('n', o.get().filetype.map, ":RunCode<CR>", {noremap = true})
  else
    vim.api.nvim_set_keymap('n', o.get().filetype.map, ":RunFile<CR>", {noremap = true})
    vim.api.nvim_set_keymap('n', o.get().project_context.map, ":RunProject<CR>", {noremap = true})
  end
end

M.load_json_files = function()
  vim.g.fileCommands = loadTable(o.get().filetype.json_path)
  vim.g.projectManager = loadTable(o.get().project_context.json_path)
  -- Message if json file not exist
  if not vim.g.fileCommands then
    print(vim.inspect("File not exist or format invalid, please execute :SRunCode"))
  end

  if not vim.g.projectManager then
    print(vim.inspect("Nothing Projects"))
  end
end

M.run_code = function() commands.run() end
M.run_filetype = function() commands.run_filetype() end
M.run_project = function() commands.run_project() end

local function open_json(json_path)
  local command ="tabnew " .. json_path
  vim.cmd(command)
end

M.open_filetype_suported = function()
  open_json(o.get().filetype.json_path)
end

M.open_project_manager = function()
  open_json(o.get().project_context.json_path)
end

return M
