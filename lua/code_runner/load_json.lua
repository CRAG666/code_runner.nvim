-- @param json_path absolute path to json
-- @return json as table or nil
function LoadTable(json_path)
  local contents = ""
  local file = io.open(json_path, "r")

  if file then
    -- read all contents of file into a string
    contents = file:read("*a")
    local status, result = pcall(vim.fn.json_decode, contents)
    io.close(file)
    if status then
      return result
    else
      return nil
    end
  end
  return nil
end

return LoadTable
