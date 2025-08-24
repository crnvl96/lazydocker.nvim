local mocks = dofile('tests/mocks.lua')
local helpers = dofile('tests/helpers.lua')

local child = helpers.new_child_neovim()

local new_set = MiniTest.new_set

local eq = helpers.expect.equality
local neq = helpers.expect.no_equality
local err = helpers.expect.error

local lua = child.lua
local get = child.lua_get

local load_lzd = child.load_lzd

local T = new_set({
  hooks = {
    pre_case = child.setup,
    post_case = child.unload_lzd,
    post_once = child.stop,
    n_retry = helpers.get_n_retry(1),
  },
})

T['setup()'] = new_set()
local lazydocker_setup = T['setup()']

-- Test: Verifies that the default configuration structure has correct types
-- Ensures LazyDocker module and its config hierarchy have proper Lua types
lazydocker_setup['default config types'] = function()
  load_lzd()
  eq(get('type(LazyDocker)'), 'table')
  eq(get('type(LazyDocker.config)'), 'table')
  eq(get('type(LazyDocker.config.window)'), 'table')
  eq(get('type(LazyDocker.config.window.settings)'), 'table')
  eq(get('type(LazyDocker.config.window.settings.width)'), 'number')
  eq(get('type(LazyDocker.config.window.settings.height)'), 'number')
  eq(get('type(LazyDocker.config.window.settings.border)'), 'string')
  eq(get('type(LazyDocker.config.window.settings.relative)'), 'string')
end

-- Test: Verifies the specific default values for window configuration
-- Ensures the golden ratio defaults and proper border/relative settings are applied
lazydocker_setup['default config values'] = function()
  load_lzd()
  eq(get('LazyDocker.config.window.settings.height'), 0.618)
  eq(get('LazyDocker.config.window.settings.width'), 0.618)
  eq(get('LazyDocker.config.window.settings.border'), 'rounded')
  eq(get('LazyDocker.config.window.settings.relative'), 'editor')
end

-- Test: Verifies that custom configuration values are properly merged with defaults
-- Ensures user-provided settings override default values correctly
lazydocker_setup['custom config'] = function()
  load_lzd({ window = { settings = { width = 0.5, height = 0.8, border = 'single', relative = 'cursor' } } })
  eq(get('LazyDocker.config.window.settings.height'), 0.8)
  eq(get('LazyDocker.config.window.settings.width'), 0.5)
  eq(get('LazyDocker.config.window.settings.border'), 'single')
  eq(get('LazyDocker.config.window.settings.relative'), 'cursor')
end

-- Test: Comprehensive validation testing for incorrect configuration values
-- Ensures proper error messages are thrown for various invalid input types and values
lazydocker_setup['incorrect config'] = function()
  local e = function(msg, config) err(load_lzd, msg, config) end
  -- Test invalid window config types
  e('.*LazyDocker%.window:.*a table, if provided.*got a', { window = 'a' })
  e('.*LazyDocker%.window%.settings:.*a table, if provided.*got a', { window = { settings = 'a' } })
  e('.*LazyDocker%.window%.settings:.*a table, if provided.*got a', { window = { settings = 'a' } })

  -- Test invalid width values (non-numbers, out of range, wrong types)
  e('.*window.settings.width.*a number between 0 and 1.*got a', { window = { settings = { width = 'a' } } })
  e('.*window.settings.width.*a number between 0 and 1.*got 0', { window = { settings = { width = 0 } } })
  e('.*window.settings.width.*a number between 0 and 1.*got 1.5', { window = { settings = { width = 1.5 } } })
  e('.*window.settings.width.*a number between 0 and 1.*got %-1', { window = { settings = { width = -1 } } })
  e('.*window.settings.width.*a number between 0 and 1.*got true', { window = { settings = { width = true } } })

  -- Test invalid height values (non-numbers, out of range, wrong types)
  e('.*window.settings.height.*a number between 0 and 1.*got a', { window = { settings = { height = 'a' } } })
  e('.*window.settings.height.*a number between 0 and 1.*got 0', { window = { settings = { height = 0 } } })
  e('.*window.settings.height.*a number between 0 and 1.*got 1.5', { window = { settings = { height = 1.5 } } })
  e('.*window.settings.height.*a number between 0 and 1.*got %-1', { window = { settings = { height = -1 } } })
  e('.*settings.height.*a number between 0 and 1.*got true', { window = { settings = { height = true } } })

  -- Test invalid border values (numbers, invalid strings, wrong types)
  e('.*settings.border.*a valid border definition.*got% 123', { window = { settings = { border = 123 } } })
  e('.*window.settings.border.*a valid border definition.*got% %-1', { window = { settings = { border = -1 } } })
  e('.*border.*a valid border definition.*got% invalid', { window = { settings = { border = 'invalid' } } })
  e('.*settings.border.*a valid border definition.*got% true', { window = { settings = { border = true } } })

  -- Test invalid relative values (numbers, invalid strings, wrong types)
  e('.*settings.relative.*a valid relative definition.*got% 123', { window = { settings = { relative = 123 } } })
  e('.*settings.relative.*a valid relative definition.*got% %-1', { window = { settings = { relative = -1 } } })
  e('.*a valid relative definition.*got% invalid', { window = { settings = { relative = 'invalid' } } })
  e('.*relative.*a valid relative definition.*got% true', { window = { settings = { relative = true } } })
end

T['open()'] = new_set()
local lazydocker_open = T['open()']

-- Test: Validates engine parameter validation in open() function
-- Ensures only 'docker' or 'podman' are accepted as valid engine values
lazydocker_open['incorrect engine'] = function()
  load_lzd()
  local invalid_engine = function() lua("LazyDocker.open({ engine = 'invalid' })") end
  err(invalid_engine, '.*LazyDocker.open().*opts.engine:.*either "docker" or "podman".*got invalid')
end

-- Test: Verifies error handling when docker executable is not available
-- Ensures proper error notification is shown when docker command is missing
-- Mock Usage: vim_fn_executable_no_docker + vim_fn_notify to capture error notifications
lazydocker_open['absence of docker executable'] = function()
  local Mocks = { mocks.vim_fn_executable_no_docker(child), mocks.vim_fn_notify(child) }
  mocks.apply(Mocks)
  load_lzd()
  lua("LazyDocker.open({ engine = 'docker' })")
  eq(#get('_G.notify_messages'), 1, 'Expected one notification message')
  eq(get('_G.notify_messages')[1].msg, 'LazyDocker: "docker" command not found. Please install Docker.')
  eq(get('_G.notify_messages')[1].level, vim.log.levels.ERROR)
  mocks.restore(Mocks)
end

-- Test: Verifies error handling when podman executable is not available
-- Ensures proper error notification is shown when podman command is missing
-- Mock Usage: vim_fn_executable_no_podman + vim_fn_notify to capture error notifications
lazydocker_open['absence of podman executable'] = function()
  local Mocks = { mocks.vim_fn_executable_no_podman(child), mocks.vim_fn_notify(child) }
  mocks.apply(Mocks)
  load_lzd()
  lua("LazyDocker.open({ engine = 'podman' })")
  eq(#get('_G.notify_messages'), 1, 'Expected one notification message')
  eq(get('_G.notify_messages')[1].msg, 'LazyDocker: "podman" command not found. Please install Podman.')
  eq(get('_G.notify_messages')[1].level, vim.log.levels.ERROR)
  mocks.restore(Mocks)
end

-- Test: Verifies error handling when lazydocker executable is not available
-- Ensures proper error notification is shown when lazydocker command is missing
-- Mock Usage: vim_fn_executable_no_lazydocker + vim_fn_notify to capture error notifications
lazydocker_open['absence of lazydocker executable'] = function()
  local Mocks = { mocks.vim_fn_executable_no_lazydocker(child), mocks.vim_fn_notify(child) }
  mocks.apply(Mocks)
  load_lzd()
  lua("LazyDocker.open({ engine = 'docker' })")
  eq(#get('_G.notify_messages'), 1, 'Expected one notification message')
  eq(get('_G.notify_messages')[1].msg, 'LazyDocker: "lazydocker" command not found. Please install Lazydocker.')
  eq(get('_G.notify_messages')[1].level, vim.log.levels.ERROR)
  mocks.restore(Mocks)
end

-- Test: Verifies proper job startup for docker engine
-- Ensures lazydocker process is started with correct command and no special environment for docker
-- Mock Usage: vim_fn_executable + vim_fn_jobstart to capture process startup details
lazydocker_open['docker engine'] = function()
  local Mocks = { mocks.vim_fn_executable(child), mocks.vim_fn_jobstart(child) }
  mocks.apply(Mocks)
  load_lzd()
  lua("LazyDocker.open({ engine = 'docker' })")
  eq(get('_G.mock_logs.jobstart.cmd'), 'lazydocker')
  eq(get('type(_G.mock_logs.jobstart.on_exit)'), 'function')
  eq(get('_G.mock_logs.jobstart.env'), vim.NIL)
  mocks.restore(Mocks)
end

-- Test: Additional validation for invalid engine parameter with different error message pattern
-- Ensures robust error handling for various invalid engine values
lazydocker_open['open with invalid engine error handling'] = function()
  load_lzd()

  -- Test that invalid engine shows proper error message
  local invalid_engine = function() lua("LazyDocker.open({ engine = 'invalid-engine' })") end
  err(invalid_engine, '.*LazyDocker.open().*opts.engine:.*either "docker" or "podman".*got invalid.*engine')
end

-- Test: Verifies proper job startup for podman engine with special environment
-- Ensures lazydocker process is started with correct command and DOCKER_HOST environment for podman
-- Mock Usage: vim_fn_executable + vim_fn_jobstart to capture process startup with environment vars
lazydocker_open['podman engine'] = function()
  local Mocks = { mocks.vim_fn_executable(child), mocks.vim_fn_jobstart(child) }
  mocks.apply(Mocks)
  load_lzd()
  lua("LazyDocker.open({ engine = 'podman' })")
  eq(get('_G.mock_logs.jobstart.cmd'), 'lazydocker')
  eq(get('type(_G.mock_logs.jobstart.on_exit)'), 'function')
  eq(get('_G.mock_logs.jobstart.env'), { DOCKER_HOST = 'unix:///run/user/1000/podman/podman.sock' })
  mocks.restore(Mocks)
end

-- Test: Verifies protection against opening multiple lazydocker instances
-- Ensures that if a window handle exists and is valid, it focuses existing window instead of creating new one
-- Mock Usage: Multiple window management mocks to prevent actual window operations
lazydocker_open['protection against multiple instances'] = function()
  local Mocks = {
    mocks.vim_fn_executable(child),
    mocks.vim_api_nvim_open_win(child),
    mocks.vim_api_nvim_win_is_valid(child),
    mocks.vim_api_nvim_set_current_win(child),
  }

  mocks.apply(Mocks)
  load_lzd()
  lua([[_G.__LazyDocker_Window_Handle = 11]])
  lua("LazyDocker.open({ engine = 'docker' })")
  eq(get('_G.__LazyDocker_Window_Handle'), 11)
  mocks.restore(Mocks)
end

T['close()'] = new_set()
local lazydocker_close = T['close()']

-- Test: Verifies successful window closure when a valid window handle exists
-- Ensures close() returns true and clears the window handle when window is valid
-- Mock Usage: Window validation and close operation mocks to test closure behavior
lazydocker_close['valid window'] = function()
  local Mocks = {
    mocks.vim_api_nvim_win_is_valid(child),
    mocks.vim_api_nvim_win_close(child),
  }
  mocks.apply(Mocks)
  load_lzd()
  lua([[_G.__LazyDocker_Window_Handle = 11]])
  eq(lua('return LazyDocker.close()'), true)
  eq(get('_G.__LazyDocker_Window_Handle'), vim.NIL)
  mocks.restore(Mocks)
end

-- Test: Verifies behavior when attempting to close an invalid window
-- Ensures close() returns false and preserves window handle when window is invalid
-- Mock Usage: Window validation mock with manual override to simulate invalid window
lazydocker_close['invalid window'] = function()
  local Mocks = {
    mocks.vim_api_nvim_win_is_valid(child),
  }
  mocks.apply(Mocks)
  load_lzd()
  lua([[_G.__LazyDocker_Window_Handle = 11]])
  lua([[vim.api.nvim_win_is_valid = function() return false end]])
  eq(lua('return LazyDocker.close()'), false)
  eq(get('_G.__LazyDocker_Window_Handle'), 11)
  mocks.restore(Mocks)
end

-- Test: Verifies behavior when no window handle exists (nil case)
-- Ensures close() returns false when there's no window to close
lazydocker_close['nil window'] = function()
  load_lzd()
  lua([[_G.__LazyDocker_Window_Handle = nil]])
  eq(lua('return LazyDocker.close()'), false)
end

T['toggle()'] = new_set()
local lazydocker_toggle = T['toggle()']

-- Test: Verifies toggle functionality when lazydocker is currently closed
-- Ensures toggle() calls open() and starts a job when no window handle exists
-- Mock Usage: Command execution and job startup mocks to verify toggle opens correctly
lazydocker_toggle['opens when closed'] = function()
  local Mocks = {
    mocks.vim_fn_executable(child),
    mocks.vim_fn_jobstart(child),
    mocks.vim_api_nvim_win_is_valid(child),
  }
  mocks.apply(Mocks)
  load_lzd()
  lua([[_G.__LazyDocker_Window_Handle = nil]])
  lua("LazyDocker.toggle({ engine = 'docker' })")
  neq(get('type(_G.mock_logs)'), 'nil')
  neq(get('_G.mock_logs.jobstart.cmd'), vim.NIL)
  mocks.restore(Mocks)
end

-- Test: Verifies toggle functionality when lazydocker is currently open
-- Ensures toggle() calls close() and clears window handle when window exists and is valid
-- Mock Usage: Window validation and close operation mocks to verify toggle closes correctly
lazydocker_toggle['closes when open'] = function()
  local Mocks = {
    mocks.vim_api_nvim_win_is_valid(child),
    mocks.vim_api_nvim_win_close(child),
  }
  mocks.apply(Mocks)
  load_lzd()
  lua([[_G.__LazyDocker_Window_Handle = 11]])
  lua("LazyDocker.toggle({ engine = 'docker' })")
  eq(get('_G.__LazyDocker_Window_Handle'), vim.NIL)
  mocks.restore(Mocks)
end

-- Test: Verifies toggle functionality works with different engine options
-- Ensures both docker and podman engines can be used with toggle() and properly start jobs
lazydocker_toggle['toggle with different engine options'] = function()
  local Mocks = {
    mocks.vim_fn_executable(child),
    mocks.vim_fn_jobstart(child),
    mocks.vim_api_nvim_win_is_valid(child),
  }
  mocks.apply(Mocks)
  load_lzd()
  lua([[_G.__LazyDocker_Window_Handle = nil]])

  -- Test toggle with docker engine
  lua("LazyDocker.toggle({ engine = 'docker' })")
  neq(get('_G.mock_logs.jobstart.cmd'), vim.NIL, 'Docker engine should start job')

  -- Reset mocks and test with podman engine
  mocks.restore(Mocks)
  mocks.apply(Mocks)
  lua([[
    _G.__LazyDocker_Window_Handle = nil
    _G.mock_logs = {}
  ]])
  lua("LazyDocker.toggle({ engine = 'podman' })")
  neq(get('_G.mock_logs.jobstart.cmd'), vim.NIL, 'Podman engine should start job')

  mocks.restore(Mocks)
end

T['window configuration'] = new_set()
local window_config = T['window configuration']

-- Test: Verifies that window configuration is accessible and has correct structure
-- Ensures the public API exposes window settings with proper types and default values
window_config['get_lazydocker_win_custom_config'] = function()
  load_lzd()
  -- Test that the window configuration is properly applied through the public API
  local result = lua([[return require('lazydocker').config.window.settings]])
  eq(type(result), 'table')
  eq(result.relative, 'editor')
  eq(result.border, 'rounded')
  eq(type(result.width), 'number')
  eq(type(result.height), 'number')
end

return T
