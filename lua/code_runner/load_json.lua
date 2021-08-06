-- load the JSON library.
local o = require("code_runner.options")
local Json = require("code_runner.dkjson")

loadTable = function()
    local contents = ""
    local myTable = {}
    local file = io.open( o.get().json_path, "r" )

    if file then
        -- read all contents of file into a string
        local contents = file:read( "*a" )
        local myTable, pos, err = Json.decode( contents )
        io.close( file )
        return myTable
    end
    return nil
end

return loadTable
