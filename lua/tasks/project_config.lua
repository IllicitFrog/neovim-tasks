local config = require('tasks.config')
local Path = require('plenary.path')

--- Formats a JSON string with indentation.
---@param json_str string
---@param indent integer
---@return string
local function format_json(json_str, indent)
  indent = indent or 2
  local function newline(level) return '\n' .. string.rep(' ', indent * level) end

  local i, len = 1, #json_str
  local level = 0
  local out, in_string, prev_char = {}, false, ''
  while i <= len do
    local char = json_str:sub(i, i)
    if char == '"' and prev_char ~= '\\' then
      in_string = not in_string
      table.insert(out, char)
    elseif not in_string then
      if char == '{' or char == '[' then
        table.insert(out, char)
        level = level + 1
        table.insert(out, newline(level))
      elseif char == '}' or char == ']' then
        level = level - 1
        table.insert(out, newline(level))
        table.insert(out, char)
      elseif char == ',' then
        table.insert(out, char)
        table.insert(out, newline(level))
      elseif char == ':' then
        table.insert(out, ': ')
      elseif char:match('%s') then
        -- ignore whitespace
      else
        table.insert(out, char)
      end
    else
      table.insert(out, char)
    end
    prev_char = char
    i = i + 1
  end
  return table.concat(out)
end

--- Contains all fields from configuration.
---@class ProjectConfig
local ProjectConfig = {}
ProjectConfig.__index = ProjectConfig

--- Reads project configuration JSON into a table.
---@return ProjectConfig
function ProjectConfig.new()
  local project_config
  local params_file = Path:new(config.params_file)
  if params_file:is_file() then
    project_config = vim.json.decode(params_file:read())
  else
    project_config = {}
  end
  project_config = vim.tbl_extend('keep', project_config, config.default_params)
  return setmetatable(project_config, ProjectConfig)
end

--- Writes all values as JSON to disk.
function ProjectConfig:write()
  local params_file = Path:new(config.params_file)
  local tmp_dap_open_command = self.dap_open_command
  self.dap_open_command = nil
  local json = vim.json.encode(self)
  params_file:write(format_json(json), 'w')
  self.dap_open_command = tmp_dap_open_command
end

return ProjectConfig
