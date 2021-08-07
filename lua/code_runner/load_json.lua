local o = require("code_runner.options")

loadTable = function()
    local contents = ""
    local file = io.open( o.get().json_path, "r" )

    if file then
        -- read all contents of file into a string
        local contents = file:read( "*a" )
        local status, result = pcall(vim.fn.json_decode, contents)
        io.close( file )
        if status then
            return result
        else
            return nil
        end
    end
    return nil
end

return loadTable
