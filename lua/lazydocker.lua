--- *lazydocker.nvim* lazydocker management within Neovim
--- *LazyDocker*
---
--- MIT License Copyright (c) 2024 Ádran Carnavale

local helpers = require('helpers')
local LazyDocker = {}

ProcessJobID = nil

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
  -- Sets the window layout relative to. See ':h nvim_open_win'.
  relative = 'editor',
}
--minidoc_afterlines_end

--- Module Functions
---
--- Opens a new floating window with lazydocker running.
---
--- creates a floating terminal window and starts `lazydocker`.
---
---@usage >lua
---    require('lazydocker').open()
---    -- OR
---    lua LazyDocker.open()
--- <
---@return nil
function LazyDocker.open()
  if not helpers.check_prerequisites() then
    return
  end

  helpers.stop_hanging_job()

  local win_opts = helpers.get_win_custom_config(LazyDocker.config)
  local buf, win = helpers.create_win_and_buffer(win_opts)

  helpers.start_lazydocker_job(win)
  helpers.register_job_cleanup_autocmds(buf, win)

  vim.cmd('startinsert')
end

return LazyDocker
