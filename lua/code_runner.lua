local o = require("code_runner.options").get()
local commands = require("code_runner.commands")
local M = {}

-- Load json config and convert to table
local loadTable = require("code_runner.load_json")

M.setup = function(user_options)
  o.set(user_options)
  vim.cmd([[lua require('code_runner').load_json_files()]])
  vim.api.nvim_exec(
    [[
  command! CRFiletype lua require('code_runner').open_filetype_suported()
  command! CRProjects lua require('code_runner').open_project_manager()
  command! RunCode lua require('code_runner').run_code()
  command! RunFile lua require('code_runner').run_filetype()
  command! RunProject lua require('code_runner').run_project()
  ]],
    false
  )
  if o.filetype.map == o.project_context.map then
    vim.api.nvim_set_keymap("n", o.filetype.map, ":RunCode<CR>", { noremap = true })
  else
    vim.api.nvim_set_keymap("n", o.filetype.map, ":RunFile<CR>", { noremap = true })
    vim.api.nvim_set_keymap("n", o.project_context.map, ":RunProject<CR>", { noremap = true })
  end
end

M.load_json_files = function()
  vim.g.fileCommands = loadTable(o.filetype.json_path)
  vim.g.projectManager = loadTable(o.project_context.json_path)

  -- Message if json file not exist
  if not vim.g.fileCommands then
    local orunners = o.runners
    if orunners and #orunners > 0 then
     vim.g.fileCommands = vim.tbl_extend("force", vim.g.fileCommands, orunners)
    else
      print("File not exist or format invalid, please execute :CRFiletype")
    end
  end

  local oprojects = o.projects
  if not vim.g.projectManager and oprojects and #oprojects > 0 then
    vim.g.projectManager = vim.deepcopy(oprojects)
  end
end

M.run_code = commands.run
M.run_filetype = commands.run_filetype
M.run_project = commands.run_project

local function open_json(json_path)
  local command = "tabnew " .. json_path
  vim.cmd(command)
end

M.open_filetype_suported = function()
  open_json(o.filetype.json_path)
end

M.open_project_manager = function()
  open_json(o.project_context.json_path)
end

return M
