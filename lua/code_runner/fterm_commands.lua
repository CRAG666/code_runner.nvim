local o = require("code_runner.options")

local function get_command()
  filepath = vim.fn.expand("%")
  command ="python ~/.local/share/nvim/site/pack/packer/start/code_runner.nvim/python/code_runner.py "
  return command .. filepath .. " && read -n 1"
end


local function create_code_runner(term)
  run_code_command = term:new():setup({
    cmd = get_command(),
    dimensions = {
    height = o.get().fterm.height,
    width = o.get().fterm.width
    }
  })
  return run_code_command
end


local frun_code = function()
  hasfterm, fterm = pcall(require,"FTerm.terminal")
  if hasfterm then
    run_code = create_code_runner(fterm)
    run_code:toggle()
  else
    print(vim.inspect("add FTerm for use"))
  end
end

return frun_code
