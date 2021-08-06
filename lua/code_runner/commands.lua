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

local function subvarcomm(command)
	local vars_json = {["$file"] = "%", ["$fileName"] = "%:t", ["$fileNameWithoutExt"] = "%:r", ["$dir"] = "%:p:h"}
	for var, var_vim in pairs(vars_json) do
		command = command:gsub(var, var_vim)
	end
end

function run()
	for lang, command in pairs(fileCommands) do
		command_vim = subvarcomm(command)
		shellcmd(lang, command_vim)
	end
	-- vimcmd("markdown", defaults.commands.markdown)
	vimcmd("vim", "source %")
	vimcmd("lua", "luafile %")
end
return run
