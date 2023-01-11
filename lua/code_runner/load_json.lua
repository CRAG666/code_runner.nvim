-- Load json and convert to table
---@param json_path string
---@return table | nil
function load_as_table(json_path)
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
      return
    end
  end
end

return load_as_table
