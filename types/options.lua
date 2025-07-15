---@meta

--- Don't edit or require this file
error("Requiring a meta file")

-- Code Runner Options (Library)
---@class CodeRunnerOptions
---@field mode CodeRunnerDisplayMode
---@field hot_reload boolean
---@field focus boolean
---@field startinsert boolean
---@field filetype table
---@field prefix string
---@field term CodeRunnerOptionsTermTable
---@field float CodeRunnerOptionsFloatTable

---@type CodeRunnerDisplayMode
---@alias CodeRunnerDisplayMode
---|'"term"'
---|'"float"'
---|'"tab"'
---|'"better_term"'
---|'"toggleterm"'

--  configuration for term display mode
---@class CodeRunnerOptionsTermTable
---@field position ("vert"|"bot")
---@field size number

---@class CodeRunnerOptionsFloatTable
---@field close_key string keymap to close (default: <ESC>)
---@field height number number from `0 - 1` e.g 0.8 for measurements
---@field width number number from `0 - 1` e.g 0.8 for measurements
---@field x number
---@field y number
---@field border ("none"|"single"|"double"|"rounded"|"solid"|"shadow") | string[]  string[]: length must be 8 e.g {"╔", "═" ,"╗", "║", "╝", "═", "╚", "║"}
---@field blend number
---@field border_hl string
---@field float_hl string


-- User Options (Client)
---@class CodeRunnerUserOptions : CodeRunnerOptions
---@field mode? CodeRunnerDisplayMode
---@field hot_reload? boolean enabled/disabled (only works with 'term' or term like display modes)
---@field focus? boolean Focus on runner window/viewport (only works on 'term' and 'tab' display mode)
---@field insert_prefix? string
---@field startinsert? boolean startinsert (see ':h inserting-ex') if focus is false has no effect unless display mode is 'float'
---@field filetype? table ft entries, is unknown run :=vim.bo.ft
---@field prefix? string
---@field term? CodeRunnerUserOptionsTermTable
---@field float? CodeRunnerUserOptionsFloatTable

--  configuration for term display mode
---@class CodeRunnerUserOptionsTermTable
---@field position? ("vert"|"bot")
---@field size? number

--  configuration for float display mode
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
