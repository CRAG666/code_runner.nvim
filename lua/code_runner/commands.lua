local o = require("code_runner.options")
local json = require("commands")
local fileCommands = json.decode('code_runner.json')
local prefix = string.format("%s %dsplit term://", o.get().term.position, o.get().term.size)
local suffix = "<CR>"

local function shellcmd(lang, command)
	vim.cmd ("autocmd FileType " .. lang .. " nnoremap <buffer> " .. o.get().map .. " :" .. prefix .. "" .. command .. suffix)
end

local function vimcmd(lang, config)
	vim.cmd ("autocmd FileType " .. lang .. " nnoremap <buffer> " .. defaults.config.execute .. " :" .. config .. "<CR>")
end

function run()
	for lang, command in pairs(fileCommands) do
		shellcmd(lang, command)
	end
	-- vimcmd("markdown", defaults.commands.markdown)
	-- vimcmd("vim", defaults.commands.vim)
end
return run
