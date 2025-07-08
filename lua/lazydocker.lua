--- *lazydocker.nvim* lazydocker management within Neovim
---
--- MIT License Copyright (c) 2024 Adran Carnavale

--- Summary
---
--- * |LazyDocker.types|
--- * |LazyDocker.setup|
--- * |LazyDocker.config|
--- * |LazyDocker.open|
--- * |LazyDocker.close|
--- * |LazyDocker.toggle|
--- * |LazyDocker.recipes|

local H = require('helpers')

---@class LazyDocker
---@field config LazyDocker.Config Module config table. See |LazyDocker.config|.
---@field setup fun(config?: LazyDocker.Config) Module Setup. See |LazyDocker.setup()|.
---@field open fun(opts?: LazyDocker.OpenOpts) Opens a new floating window with lazydocker running. See |LazyDocker.open()|.
---@field close fun():boolean Closes the lazydocker window if open. See |LazyDocker.close()|.
---@field toggle fun(opts?: LazyDocker.OpenOpts) Toggles the lazydocker window open/closed. See |LazyDocker.toggle()|.
---
---@class LazyDocker.Config
---@field window LazyDocker.WindowConfig
---
---@class LazyDocker.WindowConfig
---@field settings LazyDocker.WindowSettings
---
---@class LazyDocker.WindowSettings
---@field width number Width of the floating panel, as a percentage (0 to 1) of screen width.
---@field height number Height of the floating panel, as a percentage (0 to 1) of screen height.
---@field border string Style of the floating window border. See ':h nvim_open_win'.
---@field relative string Sets the window layout relative to. See ':h nvim_open_win'.
---
---@alias LazyDocker.Engine 'docker' | 'podman'
---
---@class LazyDocker.OpenOpts
---@field engine LazyDocker.Engine The container engine to use.
---@tag LazyDocker.types

local LazyDocker = {}

---@param config table|nil Module config table. See |LazyDocker.config|.
---
---@usage >lua
---   require('lazydocker').setup() -- Use default config.
---   -- OR
---   require('lazydocker').setup({ window = { settings = { width = 0.8 } } }) -- Provide your own config.
--- <
---@return nil
function LazyDocker.setup(config)
  _G.LazyDocker = LazyDocker
  LazyDocker.config = H.setup_config(LazyDocker.config, config)
end

--- Default values (Check |LazyDocker.types| for details):
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---@type LazyDocker.Config
LazyDocker.config = {
  window = {
    settings = {
      width = 0.618,
      height = 0.618,
      border = 'rounded',
      relative = 'editor',
    },
  },
}
--minidoc_afterlines_end

--- Opens a new floating window with lazydocker running.
---
---@param opts? LazyDocker.OpenOpts Optional parameters.
---@usage >lua
---    require('lazydocker').open({ engine = 'docker' })
---    -- OR
---    require('lazydocker').open({ engine = 'podman' })
---    -- OR (deprecated)
---    require('lazydocker').open()
---    -- OR
---    :lua require('lazydocker').open({ engine = 'docker' })
--- <
---@return nil
function LazyDocker.open(opts)
  if opts == nil then
    vim.notify(
      'LazyDocker.open() without arguments is deprecated and will be removed in a future release. Use LazyDocker.open({ engine = "docker" }) instead.',
      vim.log.levels.WARN,
      { title = 'LazyDocker Deprecation' }
    )
  end

  opts = opts or { engine = 'docker' }
  local engine = opts.engine or 'docker'

  vim.validate({
    ['LazyDocker.open() opts.engine'] = {
      engine,
      function(v)
        return v == 'docker' or v == 'podman'
      end,
      'either "docker" or "podman"',
    },
  })

  -- Prevent opening multiple instances, focus existing one
  if _G.__LazyDocker_Window_Handle and vim.api.nvim_win_is_valid(_G.__LazyDocker_Window_Handle) then
    vim.api.nvim_set_current_win(_G.__LazyDocker_Window_Handle)
    return
  end

  if not H.check_prerequisites(engine) then
    return
  end

  H.stop_hanging_lazydocker_job_if_active()

  local win_opts = H.get_lazydocker_win_custom_config(LazyDocker.config.window.settings)
  local buf, win = H.create_lazydocker_win_and_buffer(win_opts)
  _G.__LazyDocker_Window_Handle = win

  H.start_lazydocker_job(win, engine)
  H.start_lazydocker_job_cleanup_autocmds(buf, win)

  vim.cmd('startinsert')
end

--- Closes the lazydocker window if it's currently open.
---
---@usage >lua
---    require('lazydocker').close()
---    -- OR
---    :lua LazyDocker.close()
--- <
---@return boolean closed True if a valid window was found and closed, false otherwise.
function LazyDocker.close()
  local win_handle = _G.__LazyDocker_Window_Handle

  if win_handle and vim.api.nvim_win_is_valid(win_handle) then
    pcall(vim.api.nvim_win_close, win_handle, true)
    _G.__LazyDocker_Window_Handle = nil
    return true
  end

  return false
end

--- Toggles the lazydocker window open or closed.
---
--- - If the window is open (or believed to be open based on the internal handle), it calls |LazyDocker.close()|.
--- - If closing fails (meaning it wasn't open), it calls |LazyDocker.open()|.
---
--- This function is intended to be mapped by the user. See |LazyDocker.recipes|.
---
---@param opts? LazyDocker.OpenOpts Optional parameters, passed to |LazyDocker.open()|.
---@usage Map this function to a keybind in your Neovim config.
--- >lua
---    require('lazydocker').toggle({ engine = 'docker' })
---    -- OR
---    :lua require('lazydocker').toggle({ engine = 'podman' })
--- <
---@return nil
function LazyDocker.toggle(opts)
  -- Attempt to close first. If close() returns false, it means
  -- the window wasn't open (or the handle was invalid), so open it.
  if not LazyDocker.close() then
    LazyDocker.open(opts)
  end
end

--- Common configuration examples ~
---
--- # Toggle behavior ~
---
--- Since this plugin does not set any keymaps by default, you can map the
--- |LazyDocker.toggle()| function yourself.
---
--- >lua
---   -- It need to be setup on both `normal` and `terminal` modes because `lazydocker` is run inside a terminal buffer
---   -- Toggle with Docker
---   vim.keymap.set({ 'n', 't' }, '<leader>ld', "<Cmd>lua require('lazydocker').toggle({ engine = 'docker' })<CR>", { desc = 'LazyDocker (docker)' })
---   -- Toggle with Podman
---   vim.keymap.set({ 'n', 't' }, '<leader>lp', "<Cmd>lua require('lazydocker').toggle({ engine = 'podman' })<CR>", { desc = 'LazyDocker (podman)' })
--- <
---
--- Replace `<leader>ld` and `<leader>lp` with your preferred key combinations.
---@tag LazyDocker.recipes

return LazyDocker
