local options = {
      term = {
        position = "belowright",
        size = 8,
      },
      filetype = {
        map = "<leader>r",
        json_path = vim.fn.stdpath("data") .. '/site/pack/packer/start/code_runner.nvim/lua/code_runner/code_runner.json',
      },
      project_context = {
        map = "<leader>r",
        json_path = vim.fn.stdpath("data") .. '/site/pack/packer/start/code_runner.nvim/lua/code_runner/project_manager.json'
      }
}

local M = {}
M.set = function(user_options)
  for key, value in pairs(options) do
    local status, current_key = pcall("vim.tbl_extend", "force", value, user_options[key])
    if not status then
      options[key] = current_key
    end
  end
  print(vim.inspect(options))
end

M.get = function() return options end

return M
