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

---@private
---@class vim.api.WinOpts: table<string, any> Options for nvim_open_win
---
---@class Helpers

local LazyDocker = {}
local H = {}

---@private
---@type number|nil Global variable to store the Job ID of the running lazydocker process.
_G.__LazyDocker_Process_JobID = nil

---@private
---@type number|nil Stores the window handle of the active lazydocker instance.
_G.__LazyDocker_Window_Handle = nil

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

--- Open a new floating window with lazydocker running.
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
  opts = opts or { engine = 'docker' }
  local engine = opts.engine or 'docker'

  vim.validate({
    ['LazyDocker.open() opts.engine'] = {
      engine,
      function(v) return v == 'docker' or v == 'podman' end,
      'either "docker" or "podman"',
    },
  })

  -- Prevent opening multiple instances, focus existing one
  if _G.__LazyDocker_Window_Handle and vim.api.nvim_win_is_valid(_G.__LazyDocker_Window_Handle) then
    vim.api.nvim_set_current_win(_G.__LazyDocker_Window_Handle)
    return
  end

  if not H.check_prerequisites(engine) then return end

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
  if not LazyDocker.close() then LazyDocker.open(opts) end
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

--- hellpers

---@private
--- Checks if a value is a number between 0 and 1 (exclusive of 0, inclusive of 1).
---@param a any The value to check.
---@return boolean
function H._is_percentage(a)
  if type(a) ~= 'number' then return false end

  if a <= 0 or a > 1 then return false end

  return true
end

---@private
--- Checks if a value is nil or a table.
---@param val any The value to check.
---@return boolean
function H._is_optional_table(val) return val == nil or type(val) == 'table' end

---@private
--- Checks if a string is a valid border style.
---@param a any The value to check.
---@return boolean
function H._is_valid_border(a)
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

---@private
--- Checks if a string is a valid relative position.
---@param a any The value to check.
---@return boolean
function H._is_valid_relative(a)
  local relatives = {
    ['cursor'] = true,
    ['editor'] = true,
    ['laststatus'] = true,
    ['mouse'] = true,
    ['tabline'] = true,
    ['win'] = true,
  }
  return relatives[a]
end

---@private
--- Checks if the lazydocker executable is available in PATH.
---@return boolean
function H._is_lazydocker_executable_available() return vim.fn.executable('lazydocker') == 1 end

---@private
--- Checks if the docker executable is available in PATH.
---@return boolean
function H._is_docker_executable_available() return vim.fn.executable('docker') == 1 end

---@private
--- Checks if the podman executable is available in PATH.
---@return boolean
function H._is_podman_executable_available() return vim.fn.executable('podman') == 1 end

---@private
--- Merges user configuration with default configuration and validates it.
---@param base_config LazyDocker.Config The default configuration table.
---@param user_config? LazyDocker.Config The user-provided configuration table.
---@return LazyDocker.Config The merged and validated configuration table.
function H.setup_config(base_config, user_config)
  vim.validate({
    ['LazyDocker.config'] = { user_config, 'table', true },
  })

  local config = vim.deepcopy(base_config)
  user_config = user_config or {}

  if user_config.window then
    vim.validate({
      ['LazyDocker.window'] = { user_config.window, H._is_optional_table, 'a table, if provided' },
    })

    if user_config.window.settings then
      vim.validate({
        ['LazyDocker.window.settings'] = { user_config.window.settings, H._is_optional_table, 'a table, if provided' },
      })

      config.window.settings = vim.tbl_deep_extend('force', config.window.settings, user_config.window.settings)
    end
  end

  local settings = config.window.settings

  vim.validate({
    ['LazyDocker.config.window.settings.width'] = { settings.width, H._is_percentage, 'a number between 0 and 1' },
    ['LazyDocker.config.window.settings.height'] = { settings.height, H._is_percentage, 'a number between 0 and 1' },
    ['LazyDocker.config.window.settings.border'] = { settings.border, H._is_valid_border, 'a valid border definition' },
    ['LazyDocker.config.window.settings.relative'] = {
      settings.relative,
      H._is_valid_relative,
      'a valid relative definition',
    },
  })

  return config
end

---@private
--- Checks if both engine and lazydocker executables are available.
---@param engine string The container engine to check for ('docker' or 'podman').
---@return boolean True if both are available, false otherwise.
function H.check_prerequisites(engine)
  if engine == 'docker' then
    if not H._is_docker_executable_available() then
      vim.notify('LazyDocker: "docker" command not found. Please install Docker.', vim.log.levels.ERROR)
      return false
    end
  elseif engine == 'podman' then
    if not H._is_podman_executable_available() then
      vim.notify('LazyDocker: "podman" command not found. Please install Podman.', vim.log.levels.ERROR)
      return false
    end
  end

  if not H._is_lazydocker_executable_available() then
    vim.notify('LazyDocker: "lazydocker" command not found. Please install Lazydocker.', vim.log.levels.ERROR)
    return false
  end

  return true
end

---@private
--- Stops the lazydocker job if it's still running (hanging).
---@return nil
function H.stop_hanging_lazydocker_job_if_active()
  if __LazyDocker_Process_JobID and vim.fn.jobwait({ __LazyDocker_Process_JobID }, 0)[1] == -1 then
    vim.fn.jobstop(__LazyDocker_Process_JobID)
    __LazyDocker_Process_JobID = nil
  end
end

---@private
--- Creates the floating window and buffer for lazydocker.
---@param win_opts vim.api.WinOpts Neovim window options.
---@return number buf The buffer handle.
---@return number win The window handle.
function H.create_lazydocker_win_and_buffer(win_opts)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  return buf, win
end

---@private
--- Calculates the final window configuration based on user settings and screen dimensions.
---@param win_settings LazyDocker.WindowSettings User-defined window settings.
---@return vim.api.WinOpts Calculated window options for nvim_open_win.
function H.get_lazydocker_win_custom_config(win_settings)
  -- Checks if the user has an active tabline
  local has_tabline = vim.o.showtabline == 2 or (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1)
  -- Checks if the user has an active statusline
  local has_statusline = vim.o.laststatus > 0
  -- Set border style
  local border_style = win_settings.border

  -- Set max allowed height
  local max_height = vim.o.lines - vim.o.cmdheight - (has_tabline and 1 or 0) - (has_statusline and 1 or 0)
  -- Set max allowed width
  local max_width = vim.o.columns
  --  Most border styles add two characters to the total height and width (one for each side)
  local border_offset = (border_style and border_style ~= 'none') and 2 or 0

  -- Ensure minimum height
  local win_height = math.max(10, math.floor(max_height * win_settings.height))
  -- Ensure minimum width
  local win_width = math.max(40, math.floor(max_width * win_settings.width))
  -- Ensure proper row attribution
  local win_row = math.floor(0.5 * (max_height + (has_tabline and 1 or 0) - win_height - border_offset))
  -- Ensure proper col attribution
  local win_col = math.floor(0.5 * (max_width - win_width - border_offset))

  if vim.fn.has('nvim-0.11') and vim.fn.exists('+winborder') == 1 then
    local global_winborder = vim.o.winborder
    if global_winborder ~= '' and global_winborder ~= nil then border_style = global_winborder end
  end

  return {
    relative = win_settings.relative,
    width = win_width,
    height = win_height,
    row = win_row,
    col = win_col,
    border = border_style,
  }
end

---@private
--- Sets up autocmds to clean up the lazydocker job when the buffer or window is closed.
---@param buf number The buffer handle.
---@param win number The window handle.
---@return nil
function H.start_lazydocker_job_cleanup_autocmds(buf, win)
  local group = vim.api.nvim_create_augroup('LazyDockerTermCleanup', { clear = true })

  local cleanup_callback = function()
    H.stop_hanging_lazydocker_job_if_active()
    if _G.__LazyDocker_Window_Handle == win then _G.__LazyDocker_Window_Handle = nil end
    pcall(vim.api.nvim_del_augroup_by_id, group)
  end

  vim.api.nvim_create_autocmd({ 'BufWipeout' }, {
    buffer = buf,
    group = group,
    once = true,
    callback = cleanup_callback,
  })

  vim.api.nvim_create_autocmd({ 'WinClosed' }, {
    pattern = tostring(win),
    group = group,
    once = true,
    callback = cleanup_callback,
  })
end

---@private
--- Starts the lazydocker process in a terminal attached to the window.
---@param win number The window handle where the terminal will be opened.
---@param engine string The container engine to use ('docker' or 'podman').
---@return nil
function H.start_lazydocker_job(win, engine)
  local term_opts = {
    term = true,
    on_exit = function()
      __LazyDocker_Process_JobID = nil
      if _G.__LazyDocker_Window_Handle == win then _G.__LazyDocker_Window_Handle = nil end
      if vim.api.nvim_win_is_valid(win) then
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win) then pcall(vim.api.nvim_win_close, win, true) end
        end)
      end
    end,
  }

  if engine == 'podman' then term_opts.env = { DOCKER_HOST = 'unix:///run/user/1000/podman/podman.sock' } end

  local job_id = vim.fn.jobstart('lazydocker', term_opts)
  __LazyDocker_Process_JobID = job_id
end

return LazyDocker
