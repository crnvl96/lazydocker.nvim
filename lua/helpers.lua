---@class vim.api.WinOpts: table<string, any> Options for nvim_open_win

---@class Helpers
local M = {}

---@type number|nil Global variable to store the Job ID of the running lazydocker process.
_G.__LazyDocker_Process_JobID = nil

---@type number|nil Stores the window handle of the active lazydocker instance.
_G.__LazyDocker_Window_Handle = nil

--- Checks if a value is a number between 0 and 1 (exclusive of 0, inclusive of 1).
---@param a any The value to check.
---@return boolean
local function _is_percentage(a)
  if type(a) ~= 'number' then
    return false
  end

  if a <= 0 or a > 1 then
    return false
  end

  return true
end

--- Checks if a value is nil or a table.
---@param val any The value to check.
---@return boolean
local function _is_optional_table(val)
  return val == nil or type(val) == 'table'
end

--- Checks if a string is a valid border style.
---@param a any The value to check.
---@return boolean
local function _is_valid_border(a)
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

--- Checks if a string is a valid relative position.
---@param a any The value to check.
---@return boolean
local function _is_valid_relative(a)
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

--- Checks if the lazydocker executable is available in PATH.
---@return boolean
local function _is_lazydocker_executable_available()
  return vim.fn.executable('lazydocker') == 1
end

--- Checks if the docker executable is available in PATH.
---@return boolean
local function _is_docker_executable_available()
  return vim.fn.executable('docker') == 1
end

--- Merges user configuration with default configuration and validates it.
---@param base_config LazyDocker.Config The default configuration table.
---@param user_config? LazyDocker.Config The user-provided configuration table.
---@return LazyDocker.Config The merged and validated configuration table.
function M.setup_config(base_config, user_config)
  vim.validate({
    ['LazyDocker.config'] = { user_config, 'table', true },
  })

  local config = vim.deepcopy(base_config)
  user_config = user_config or {}

  if user_config.window then
    vim.validate({
      ['LazyDocker.window'] = { user_config.window, _is_optional_table, 'a table, if provided' },
    })

    if user_config.window.settings then
      vim.validate({
        ['LazyDocker.window.settings'] = { user_config.window.settings, _is_optional_table, 'a table, if provided' },
      })

      config.window.settings = vim.tbl_deep_extend('force', config.window.settings, user_config.window.settings)
    end
  end

  local settings = config.window.settings

  vim.validate({
    ['LazyDocker.config.window.settings.width'] = { settings.width, _is_percentage, 'a number between 0 and 1' },
    ['LazyDocker.config.window.settings.height'] = { settings.height, _is_percentage, 'a number between 0 and 1' },
    ['LazyDocker.config.window.settings.border'] = { settings.border, _is_valid_border, 'a valid border definition' },
    ['LazyDocker.config.window.settings.relative'] = {
      settings.relative,
      _is_valid_relative,
      'a valid relative definition',
    },
  })

  return config
end

--- Checks if both docker and lazydocker executables are available.
---@return boolean True if both are available, false otherwise.
function M.check_prerequisites()
  if not _is_docker_executable_available() then
    vim.notify('LazyDocker: "docker" command not found. Please install Docker.', vim.log.levels.ERROR)
    return false
  end

  if not _is_lazydocker_executable_available() then
    vim.notify('LazyDocker: "lazydocker" command not found. Please install lazydocker.', vim.log.levels.ERROR)
    return false
  end

  return true
end

--- Stops the lazydocker job if it's still running (hanging).
---@return nil
function M.stop_hanging_lazydocker_job_if_active()
  if __LazyDocker_Process_JobID and vim.fn.jobwait({ __LazyDocker_Process_JobID }, 0)[1] == -1 then
    vim.fn.jobstop(__LazyDocker_Process_JobID)
    __LazyDocker_Process_JobID = nil
  end
end

--- Creates the floating window and buffer for lazydocker.
---@param win_opts vim.api.WinOpts Neovim window options.
---@return number buf The buffer handle.
---@return number win The window handle.
function M.create_lazydocker_win_and_buffer(win_opts)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  return buf, win
end

--- Calculates the final window configuration based on user settings and screen dimensions.
---@param win_settings LazyDocker.WindowSettings User-defined window settings.
---@return vim.api.WinOpts Calculated window options for nvim_open_win.
function M.get_lazydocker_win_custom_config(win_settings)
  -- Ensure minimum height
  local win_height = math.max(10, math.floor(vim.o.lines * win_settings.height))
  -- Ensure minimum width
  local win_width = math.max(40, math.floor(vim.o.columns * win_settings.width))

  local border_style = win_settings.border
  if vim.fn.exists('+winborder') == 1 then
    local global_winborder = vim.o.winborder
    if global_winborder ~= '' and global_winborder ~= nil then
      border_style = global_winborder
    end
  end

  return {
    relative = win_settings.relative,
    width = win_width,
    height = win_height,
    row = math.floor((vim.o.lines - win_height) / 2),
    col = math.floor((vim.o.columns - win_width) / 2),
    border = border_style,
  }
end

--- Sets up autocmds to clean up the lazydocker job when the buffer or window is closed.
---@param buf number The buffer handle.
---@param win number The window handle.
---@return nil
function M.start_lazydocker_job_cleanup_autocmds(buf, win)
  local group = vim.api.nvim_create_augroup('LazyDockerTermCleanup', { clear = true })

  local cleanup_callback = function()
    M.stop_hanging_lazydocker_job_if_active()
    if _G.__LazyDocker_Window_Handle == win then
      _G.__LazyDocker_Window_Handle = nil
    end
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

--- Starts the lazydocker process in a terminal attached to the window.
---@param win number The window handle where the terminal will be opened.
---@return nil
function M.start_lazydocker_job(win)
  local job_id = vim.fn.termopen('lazydocker', {
    on_exit = function()
      __LazyDocker_Process_JobID = nil
      if _G.__LazyDocker_Window_Handle == win then
        _G.__LazyDocker_Window_Handle = nil
      end
      if vim.api.nvim_win_is_valid(win) then
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win) then
            pcall(vim.api.nvim_win_close, win, true)
          end
        end)
      end
    end,
  })
  __LazyDocker_Process_JobID = job_id
end

return M
