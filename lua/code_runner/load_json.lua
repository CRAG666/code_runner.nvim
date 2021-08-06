-- load the JSON library.
local Json = require("code_runner.dkjson")
loadTable = function(filename)
    local path = system.pathForFile( filename, system.DocumentsDirectory)
    local contents = ""
    local myTable = {}
    local file = io.open( path, "r" )

    if file then
        -- read all contents of file into a string
        local contents = file:read( "*a" )
        local myTable, pos, err = Json.decode('code_runner.json')
        io.close( file )
        return myTable
    end
    return nil
end

return loadTable
