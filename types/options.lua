---@meta

--- Don't edit or require this file
error("Requiring a meta file")

-- Definition Options
---@class CodeRunnerOptions
---@field mode CodeRunnerDisplayMode
---@field hot_reload boolean
---@field focus boolean
---@field startinsert boolean
---@field filetype table
---@field prefix string
---@field term table
---@field float CodeRunnerOptionsFloatTable

-- TODO: WIP improve typing
---@class CodeRunnerOptionsFloatTable
---@field close_key string keymap to close (default: <ESC>)
---@field height number
---@field width number
---@field x number
---@field y number
---@field border ("none"|"single"|"double"|"rounded"|"solid"|"shadow") | string[]  string[]: length must be 8 e.g {"╔", "═" ,"╗", "║", "╝", "═", "╚", "║"}
---@field blend number
---@field border_hl string
---@field float_hl string

---@type CodeRunnerDisplayMode

---@alias CodeRunnerDisplayMode
---|'"term"'
---|'"float"'
---|'"tab"'
---|'"better_term"'
---|'"toggleterm"'

-- User Options
---@class CodeRunnerUserOptions : CodeRunnerOptions
---@field mode? CodeRunnerDisplayMode
---@field hot_reload? boolean enabled/disabled (only works with 'term' or term like display modes)
---@field focus? boolean Focus on runner window/viewport (only works on 'term' and 'tab' display mode)
---@field startinsert? boolean startinsert (see ':h inserting-ex') if focus is false has no effect unless display mode is 'float'
---@field filetype? table
---@field prefix? string
---@field term? table
---@field float? CodeRunnerUserOptionsFloatTable

---@class CodeRunnerUserOptionsFloatTable
---@field close_key? string keymap to close (default: <ESC>)
---@field height? number
---@field width? number
---@field x? number
---@field y? number
---@field border? ("none"|"single"|"double"|"rounded"|"solid"|"shadow") | string[]  string[]: length must be 8 e.g {"╔", "═" ,"╗", "║", "╝", "═", "╚", "║"}
---@field blend? number
---@field border_hl? string
---@field float_hl? string
