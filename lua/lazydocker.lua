--- *lazydocker.nvim* lazydocker management within Neovim
--- *LazyDocker*
---
--- MIT License Copyright (c) 2024 Ádran Carnavale

local LazyDocker = {}
local H = {}

--- Module Setup
---
---@param config table|nil Module config table. See |LazyDocker.config|.
---
---@usage >lua
---   require('lazydocker').setup() -- Use default config.
---   -- OR
---   require('lazydocker').config({}) -- Provide your own config as a table.
--- <
---@return nil
function LazyDocker.setup(config)
  -- Create a global table to allow easy manipulation by the user
  _G.LazyDocker = LazyDocker

  config = H.setup_config(config)
  H.apply_config(config)
end

--- Module config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
LazyDocker.config = {
  -- Width of the floating panel, as a percentage (0 to 1) of screen width. Minimum 0.25.
  width = 0.618,
  -- Height of the floating panel, as a percentage (0 to 1) of screen height. Minimum 0.25.
  height = 0.618,
  -- Style of the floating window border. See ':h nvim_open_win'.
  border = 'rounded',
  -- Style of the floating window itself. See ':h nvim_open_win'.
  style = 'minimal',
}
--minidoc_afterlines_end

--- Module Functions
---
--- Opens a new floating window with lazydocker running.
---
--- By default, it will use the configuration set when the function `setup` was called, but
--- the same options used in |LazyDocker.config| can be also used here to override them
---
---@usage >lua
---    require('lazydocker').open() -- provide your config or leave empty to use the defined during `setup`
---    -- OR
---    LazyDocker.open() -- provide your config or leave empty to use the defined during `setup`
--- <
---@return nil
function LazyDocker.open()
  local buf = H.create_buf(false, true)

  local config = LazyDocker.config

  -- Calculate window dimensions based on percentages
  local win_height = math.floor(vim.o.lines * config.height)
  local win_width = math.floor(vim.o.columns * config.width)

  local center_row = math.floor((vim.o.lines - win_height) / 2)
  local center_col = math.floor((vim.o.columns - win_width) / 2)

  local opts = {
    style = config.style,
    relative = 'editor',
    width = win_width,
    height = win_height,
    row = center_row,
    col = center_col,
    border = config.border,
  }

  vim.api.nvim_open_win(buf, true, opts)
end

--
-- Utilities
--
H.error = function(msg)
  error('(lazydocker.nvim): ' .. msg)
end

H.notify = function(msg, level)
  vim.notify('(lazydocker.nvim): ' .. msg, vim.log.levels[level])
end

H.create_buf = function(listed, scratch)
  return vim.api.nvim_create_buf(listed, scratch)
end

H.is_percentage = function(a)
  if type(a) ~= 'number' then
    return false
  end

  if a <= 0 or a > 1 then
    return false
  end

  return true
end

H.is_valid_border = function(a)
  local borders = {
    ['none'] = true,
    ['single'] = true,
    ['double'] = true,
    ['rounded'] = true,
    ['solid'] = true,
    ['shadow'] = true,
  }

  return borders[a]
end

H.is_valid_style = function(a)
  return a == 'minimal'
end

H.default_config = vim.deepcopy(LazyDocker.config)

H.setup_config = function(config)
  -- Validate that, if a config table has been provided, it is valid
  vim.validate({
    ['LazyDocker.config'] = { config, 'table', true },
  })

  -- Create a copy of the default config here to guarantee imutability
  local default_config = vim.deepcopy(H.default_config)

  -- If no config has been provided, we use an empty table here
  config = config or {}

  -- Extend the default config with the provided values
  -- In case of conflict, the provided configuration opts take precedence
  config = vim.tbl_deep_extend('force', default_config, config)

  vim.validate({
    ['LazyDocker.config.width'] = { config.width, H.is_percentage, 'a number between 0 and 1' },
    ['LazyDocker.config.height'] = { config.height, H.is_percentage, 'a number between 0 and 1' },
    ['LazyDocker.config.border'] = { config.border, H.is_valid_border, 'a valid border definition' },
    ['LazyDocker.config.style'] = { config.style, H.is_valid_style, 'a valid style definition' },
  })

  return config
end

H.apply_config = function(config)
  -- Attach the plugin configutarion to the global table
  LazyDocker.config = config
end

return LazyDocker
