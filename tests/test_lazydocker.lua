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

lazydocker_setup['default config values'] = function()
  load_lzd()
  eq(get('LazyDocker.config.window.settings.height'), 0.618)
  eq(get('LazyDocker.config.window.settings.width'), 0.618)
  eq(get('LazyDocker.config.window.settings.border'), 'rounded')
  eq(get('LazyDocker.config.window.settings.relative'), 'editor')
end

lazydocker_setup['custom config'] = function()
  load_lzd({ window = { settings = { width = 0.5, height = 0.8, border = 'single', relative = 'cursor' } } })
  eq(get('LazyDocker.config.window.settings.height'), 0.8)
  eq(get('LazyDocker.config.window.settings.width'), 0.5)
  eq(get('LazyDocker.config.window.settings.border'), 'single')
  eq(get('LazyDocker.config.window.settings.relative'), 'cursor')
end

lazydocker_setup['incorrect config'] = function()
  local e = function(msg, config) err(load_lzd, msg, config) end
  e('.*LazyDocker%.window:.*a table, if provided.*got a', { window = 'a' })
  e('.*LazyDocker%.window%.settings:.*a table, if provided.*got a', { window = { settings = 'a' } })
  e('.*LazyDocker%.window%.settings:.*a table, if provided.*got a', { window = { settings = 'a' } })
  e('.*window.settings.width.*a number between 0 and 1.*got a', { window = { settings = { width = 'a' } } })
  e('.*window.settings.width.*a number between 0 and 1.*got 0', { window = { settings = { width = 0 } } })
  e('.*window.settings.width.*a number between 0 and 1.*got 1.5', { window = { settings = { width = 1.5 } } })
  e('.*window.settings.width.*a number between 0 and 1.*got %-1', { window = { settings = { width = -1 } } })
  e('.*window.settings.width.*a number between 0 and 1.*got true', { window = { settings = { width = true } } })
  e('.*window.settings.height.*a number between 0 and 1.*got a', { window = { settings = { height = 'a' } } })
  e('.*window.settings.height.*a number between 0 and 1.*got 0', { window = { settings = { height = 0 } } })
  e('.*window.settings.height.*a number between 0 and 1.*got 1.5', { window = { settings = { height = 1.5 } } })
  e('.*window.settings.height.*a number between 0 and 1.*got %-1', { window = { settings = { height = -1 } } })
  e('.*settings.height.*a number between 0 and 1.*got true', { window = { settings = { height = true } } })
  e('.*settings.border.*a valid border definition.*got% 123', { window = { settings = { border = 123 } } })
  e('.*window.settings.border.*a valid border definition.*got% %-1', { window = { settings = { border = -1 } } })
  e('.*border.*a valid border definition.*got% invalid', { window = { settings = { border = 'invalid' } } })
  e('.*settings.border.*a valid border definition.*got% true', { window = { settings = { border = true } } })
  e('.*settings.relative.*a valid relative definition.*got% 123', { window = { settings = { relative = 123 } } })
  e('.*settings.relative.*a valid relative definition.*got% %-1', { window = { settings = { relative = -1 } } })
  e('.*a valid relative definition.*got% invalid', { window = { settings = { relative = 'invalid' } } })
  e('.*relative.*a valid relative definition.*got% true', { window = { settings = { relative = true } } })
end

T['open()'] = new_set()
local lazydocker_open = T['open()']

lazydocker_open['incorrect engine'] = function()
  load_lzd()
  local invalid_engine = function() lua("LazyDocker.open({ engine = 'invalid' })") end
  err(invalid_engine, '.*LazyDocker.open().*opts.engine:.*either "docker" or "podman".*got invalid')
end

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

return T
