-- load the JSON library.
local Json = require("json")

loadTable = function(filename)
    local path = system.pathForFile( filename, system.DocumentsDirectory)
    local contents = ""
    local myTable = {}
    local file = io.open( path, "r" )

    if file then
        -- read all contents of file into a string
        local contents = file:read( "*a" )
        myTable = Json.decode(contents);
        io.close( file )
        return myTable
    end
    return nil
end

return loadTable
