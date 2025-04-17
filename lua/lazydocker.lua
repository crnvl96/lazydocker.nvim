--- *lazydocker.nvim* lazydocker management within Neovim
--- *LazyDocker*
---
--- MIT License Copyright (c) 2024 Ádran Carnavale

local helpers = require('helpers')
local LazyDocker = {}

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
  _G.LazyDocker = LazyDocker
  LazyDocker.config = helpers.setup_config(LazyDocker.config, config)
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
--- the same options used in |LazyDocker.config| can be also used here to override them.
--- Also, is worth noting that if you have |'wiborder'| configured, the plugin will prioritize that value over the one provided in the config function.
---
---@usage >lua
---    require('lazydocker').open() -- provide your config or leave empty to use the defined during `setup`
---    -- OR
---    LazyDocker.open() -- provide your config or leave empty to use the defined during `setup`
--- <
---@return nil
function LazyDocker.open()
  local buf = vim.api.nvim_create_buf(false, true)
  local config = LazyDocker.config

  local win_height = math.floor(vim.o.lines * config.height)
  local win_width = math.floor(vim.o.columns * config.width)

  vim.api.nvim_open_win(buf, true, {
    style = config.style,
    relative = 'editor',
    width = win_width,
    height = win_height,
    row = math.floor((vim.o.lines - win_height) / 2),
    col = math.floor((vim.o.columns - win_width) / 2),
    border = (vim.fn.exists('+winborder') == 1 and vim.o.winborder ~= '') and vim.o.winborder or 'single',
  })
end

return LazyDocker
