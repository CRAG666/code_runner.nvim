local o = require("code_runner.options")
local loadTable = require("code_runner.load_json")
local fileCommands = loadTable()
local prefix = string.format("%s %dsplit term://", o.get().term.position, o.get().term.size)
local suffix = "<CR>"

local function shellcmd(lang, command)
	vim.cmd ("autocmd FileType " .. lang .. " nnoremap <buffer> " .. o.get().map .. " :" .. prefix .. "" .. command .. suffix)
end

local function vimcmd(lang, config)
	vim.cmd ("autocmd FileType " .. lang .. " nnoremap <buffer> " .. o.get().map .. " :" .. config .. "<CR>")
end

function run()
	for lang, command in pairs(fileCommands) do
		shellcmd(lang, command)
	end
	-- vimcmd("markdown", defaults.commands.markdown)
	vimcmd("vim", "source %")
	vimcmd("lua", "luafile %")
end
return run
