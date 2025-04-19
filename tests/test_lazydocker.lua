local helpers = dofile('tests/helpers.lua')
local child = helpers.new_child_neovim()

local new_set = MiniTest.new_set

local eq = helpers.expect.equality
local err = helpers.expect.error
local mock_child_functions = helpers.mock_child_functions

local lua = child.lua
local get = child.lua_get

local load_module = function(config)
  child.load_lzd(config)
end

local T = new_set({
  hooks = {
    pre_case = child.setup,
    post_once = child.stop,
    n_retry = helpers.get_n_retry(1),
  },
})

T['setup()'] = new_set()

T['setup()']['validate global table'] = function()
  load_module()
  eq(get('type(LazyDocker)'), 'table')
  eq(get('type(LazyDocker.config)'), 'table')
  eq(get('type(LazyDocker.config.window)'), 'table')
  eq(get('type(LazyDocker.config.window.settings)'), 'table')
end

T['setup()']['validate global table property types'] = function()
  local expect_config_type = function(field, value)
    field = ('type(LazyDocker.config.window.settings.%s)'):format(field)
    eq(get(field), value)
  end

  load_module()
  expect_config_type('width', 'number')
  expect_config_type('height', 'number')
  expect_config_type('border', 'string')
  expect_config_type('relative', 'string')
end

T['setup()']['check default config'] = function()
  load_module()

  eq(get('LazyDocker.config.window.settings.height'), 0.618)
  eq(get('LazyDocker.config.window.settings.width'), 0.618)
  eq(get('LazyDocker.config.window.settings.border'), 'rounded')
  eq(get('LazyDocker.config.window.settings.relative'), 'editor')
end

T['setup()']['check custom config'] = function()
  load_module({ window = { settings = { width = 0.5, height = 0.8, border = 'single', relative = 'cursor' } } })

  eq(get('LazyDocker.config.window.settings.height'), 0.8)
  eq(get('LazyDocker.config.window.settings.width'), 0.5)
  eq(get('LazyDocker.config.window.settings.border'), 'single')
  eq(get('LazyDocker.config.window.settings.relative'), 'cursor')
end

T['setup()']['check invalid values'] = new_set()

T['setup()']['check invalid values']['rejects invalid window type'] = function()
  local config = { window = 'a' }
  local msg = '.*LazyDocker%.window:.*a table, if provided.*got a'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid window settings type'] = function()
  local config = { window = { settings = 'a' } }
  local msg = '.*LazyDocker%.window%.settings:.*a table, if provided.*got a'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid width type (string)'] = function()
  local config = { window = { settings = { width = 'a' } } }
  local msg = '.*window.settings.width.*a number between 0 and 1.*got a'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid width value (zero)'] = function()
  local config = { window = { settings = { width = 0 } } }
  local msg = '.*window.settings.width.*a number between 0 and 1.*got 0'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid width value (too large)'] = function()
  local config = { window = { settings = { width = 1.5 } } }
  local msg = '.*window.settings.width.*a number between 0 and 1.*got 1.5'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid width value (negative)'] = function()
  local config = { window = { settings = { width = -1 } } }
  local msg = '.*window.settings.width.*a number between 0 and 1.*got %-1'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid width type (boolean)'] = function()
  local config = { window = { settings = { width = true } } }
  local msg = '.*window.settings.width.*a number between 0 and 1.*got true'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid height type (string)'] = function()
  local config = { window = { settings = { height = 'a' } } }
  local msg = '.*window.settings.height.*a number between 0 and 1.*got a'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid height value (zero)'] = function()
  local config = { window = { settings = { height = 0 } } }
  local msg = '.*window.settings.height.*a number between 0 and 1.*got 0'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid height value (too large)'] = function()
  local config = { window = { settings = { height = 1.5 } } }
  local msg = '.*window.settings.height.*a number between 0 and 1.*got 1.5'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid height value (negative)'] = function()
  local config = { window = { settings = { height = -1 } } }
  local msg = '.*window.settings.height.*a number between 0 and 1.*got %-1'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid height type (boolean)'] = function()
  local config = { window = { settings = { height = true } } }
  local msg = '.*window.settings.height.*a number between 0 and 1.*got true'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid border type (number)'] = function()
  local config = { window = { settings = { border = 123 } } }
  local msg = '.*window.settings.border.*expected a valid border definition.*got% 123'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid border type (negative number)'] = function()
  local config = { window = { settings = { border = -1 } } }
  local msg = '.*window.settings.border.*expected a valid border definition.*got% %-1'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid border value (string)'] = function()
  local config = { window = { settings = { border = 'invalid' } } }
  local msg = '.*window.settings.border.*expected a valid border definition.*got% invalid'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid border type (boolean)'] = function()
  local config = { window = { settings = { border = true } } }
  local msg = '.*window.settings.border.*expected a valid border definition.*got% true'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid relative type (number)'] = function()
  local config = { window = { settings = { relative = 123 } } }
  local msg = '.*window.settings.relative.*expected a valid relative definition.*got% 123'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid relative type (negative number)'] = function()
  local config = { window = { settings = { relative = -1 } } }
  local msg = '.*window.settings.relative.*expected a valid relative definition.*got% %-1'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid relative value (string)'] = function()
  local config = { window = { settings = { relative = 'invalid' } } }
  local msg = '.*window.settings.relative.*expected a valid relative definition.*got% invalid'
  err(load_module, msg, config)
end

T['setup()']['check invalid values']['rejects invalid relative type (boolean)'] = function()
  local config = { window = { settings = { relative = true } } }
  local msg = '.*window.settings.relative.*expected a valid relative definition.*got% true'
  err(load_module, msg, config)
end

T['open()'] = new_set()

T['open()']['lazydocker spawn behavior'] = new_set({
  hooks = {
    post_case = function()
      lua('if _G.__restore_mocks then _G.__restore_mocks() end')
      lua('_G.mock_logs = nil')
    end,
  },
})

T['open()']['lazydocker spawn behavior']['shows error if docker is missing'] = function()
  mock_child_functions(child, {
    ['vim.notify'] = [=[
    function(...)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.notify = _G.mock_logs.notify or {}
      table.insert(_G.mock_logs.notify, vim.deepcopy({...}))
    end
    ]=],
    ['vim.fn.executable'] = [=[
    function(cmd)
      if cmd == 'docker' then return 0 end
      return 1 
    end
    ]=],
  })

  load_module()
  lua('LazyDocker.open()')

  local notify_log = get('_G.mock_logs.notify')
  eq(notify_log[1][1], 'LazyDocker: "docker" command not found. Please install Docker.')
  eq(notify_log[1][2], get('vim.log.levels.ERROR'))
end

T['open()']['lazydocker spawn behavior']['shows error if lazydocker is missing'] = function()
  mock_child_functions(child, {
    ['vim.notify'] = [[
    function(...)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.notify = _G.mock_logs.notify or {}
      table.insert(_G.mock_logs.notify, vim.deepcopy({...}))
    end
    ]],
    ['vim.fn.executable'] = [[
    function(cmd)
      if cmd == 'lazydocker' then return 0 end
      return 1
    end
    ]],
  })

  load_module()
  lua('LazyDocker.open()')

  local notify_log = get('_G.mock_logs.notify')

  eq(notify_log[1][1], 'LazyDocker: "lazydocker" command not found. Please install lazydocker.')
  eq(notify_log[1][2], get('vim.log.levels.ERROR'))
end

T['open()']['lazydocker spawn behavior']['spawns lazydocker and sets up correctly'] = function()
  mock_child_functions(child, {
    ['vim.fn.executable'] = 'function(cmd) return 1 end',
    ['vim.fn.termopen'] = [[
    function(cmd, opts)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.termopen = { cmd = cmd, on_exit = opts.on_exit }
      return 99
    end
    ]],
    ['vim.api.nvim_create_augroup'] = [[
    function(name, opts)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.augroup = { name = name, opts = opts }
      return 55
    end
    ]],
    ['vim.api.nvim_create_autocmd'] = [[
    function(events, opts)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.autocmd = _G.mock_logs.autocmd or {}
      table.insert(_G.mock_logs.autocmd, {
        events = events,
        buffer = opts.buffer,
        pattern = opts.pattern,
        group = opts.group,
        once = opts.once,
        has_callback = type(opts.callback) == 'function',
      })
      _G.mock_logs.callbacks = _G.mock_logs.callbacks or {}
      _G.mock_logs.callbacks[opts.buffer or opts.pattern] = opts.callback
    end
    ]],
    ['vim.api.nvim_get_current_buf'] = 'function() return 10 end',
    ['vim.api.nvim_get_current_win'] = 'function() return 20 end',
    ['vim.api.nvim_create_buf'] = 'function() return 10 end',
    ['vim.api.nvim_open_win'] = 'function() return 20 end',
  })

  load_module()
  lua('LazyDocker.open()')

  local termopen_cmd = get('_G.mock_logs and _G.mock_logs.termopen.cmd')
  local termopen_on_exit_type = get('_G.mock_logs and type(_G.mock_logs.termopen.on_exit)')
  local augroup_log = get('_G.mock_logs and _G.mock_logs.augroup')
  local autocmd_log = get('_G.mock_logs and _G.mock_logs.autocmd')
  local current_buf = 10
  local current_win = 20

  eq(termopen_cmd, 'lazydocker')
  eq(termopen_on_exit_type, 'function')
  eq(get('__LazyDocker_Process_JobID'), 99)

  eq(augroup_log.name, 'LazyDockerTermCleanup')
  eq(augroup_log.opts.clear, true)

  eq(autocmd_log[1].events, { 'BufWipeout' })
  eq(autocmd_log[1].buffer, current_buf)
  eq(autocmd_log[1].group, 55)
  eq(autocmd_log[1].once, true)
  eq(autocmd_log[1].has_callback, true)

  eq(autocmd_log[2].events, { 'WinClosed' })
  eq(autocmd_log[2].pattern, tostring(current_win))
  eq(autocmd_log[2].group, 55)
  eq(autocmd_log[2].once, true)
  eq(autocmd_log[2].has_callback, true)
end

T['open()']['lazydocker spawn behavior']['handles process exit'] = function()
  local opened_win_id = 20
  mock_child_functions(child, {
    ['vim.fn.executable'] = 'function(cmd) return 1 end',
    ['vim.fn.termopen'] = [[
    function(cmd, opts)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.termopen_on_exit = opts.on_exit
      return 99
    end
    ]],
    ['vim.api.nvim_win_close'] = [[
    function(win, force)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.win_close = { win = win, force = force }
    end
    ]],
    ['vim.api.nvim_win_is_valid'] = 'function(win) return win == 20 end',
    ['vim.api.nvim_create_autocmd'] = 'function() end',
    ['vim.api.nvim_create_augroup'] = 'function() return 55 end',
    ['vim.api.nvim_create_buf'] = 'function() return 10 end',
    ['vim.api.nvim_open_win'] = 'function() return 20 end',
    ['vim.schedule'] = 'function(cb) cb() end',
  })

  load_module()
  lua('LazyDocker.open()')
  eq(get('__LazyDocker_Process_JobID'), 99)

  lua('_G.mock_logs.termopen_on_exit()')

  local win_close_log = get('_G.mock_logs and _G.mock_logs.win_close')

  eq(get('__LazyDocker_Process_JobID'), vim.NIL)
  eq(win_close_log.win, opened_win_id)
  eq(win_close_log.force, true)
end

T['open()']['lazydocker spawn behavior']['handles window close'] = function()
  local opened_win_id = 20
  mock_child_functions(child, {
    ['vim.fn.executable'] = 'function(cmd) return 1 end',
    ['vim.fn.termopen'] = 'function() return 99 end',
    ['vim.fn.jobwait'] = [[
    function(jobs, timeout)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.jobwait = { jobs=jobs, timeout=timeout }
      if jobs[1] == 99 then return {-1} end
      return {0}
    end
    ]],
    ['vim.fn.jobstop'] = [[
    function(job)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.jobstop = job
    end
    ]],
    ['vim.api.nvim_create_augroup'] = 'function() return 55 end',
    ['vim.api.nvim_create_autocmd'] = [[
    function(events, opts)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.callbacks = _G.mock_logs.callbacks or {}
      if opts.pattern then
        _G.mock_logs.callbacks[opts.pattern] = opts.callback
      end
    end
    ]],
    ['vim.api.nvim_del_augroup_by_id'] = [[
    function(group_id)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.del_augroup = group_id
    end
    ]],
    ['vim.api.nvim_create_buf'] = 'function() return 10 end',
    ['vim.api.nvim_open_win'] = 'function() return 20 end',
  })

  load_module()
  lua('LazyDocker.open()')
  eq(get('__LazyDocker_Process_JobID'), 99)

  lua(('_G.mock_logs.callbacks["%s"]()'):format(tostring(opened_win_id)))

  eq(get('_G.mock_logs.jobwait.jobs'), { 99 })
  eq(get('_G.mock_logs.jobstop'), 99)
  eq(get('__LazyDocker_Process_JobID'), vim.NIL)
  eq(get('_G.mock_logs.del_augroup'), 55)
end

T['open()']['lazydocker spawn behavior']['handles buffer wipeout'] = function()
  local opened_buf_id = 10
  mock_child_functions(child, {
    ['vim.fn.executable'] = 'function(cmd) return 1 end',
    ['vim.fn.termopen'] = 'function() return 99 end',
    ['vim.fn.jobwait'] = [[
    function(jobs, timeout)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.jobwait = { jobs=jobs, timeout=timeout }
      if jobs[1] == 99 then return {-1} end
      return {0}
    end
    ]],
    ['vim.fn.jobstop'] = [[
    function(job)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.jobstop = job
    end
    ]],
    ['vim.api.nvim_create_augroup'] = 'function() return 55 end',
    ['vim.api.nvim_create_autocmd'] = [[
    function(events, opts)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.callbacks = _G.mock_logs.callbacks or {}
      if opts.buffer then
        _G.mock_logs.callbacks[opts.buffer] = opts.callback
      end
    end
    ]],
    ['vim.api.nvim_del_augroup_by_id'] = [[
    function(group_id)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.del_augroup = group_id
    end
    ]],
    ['vim.api.nvim_create_buf'] = 'function() return 10 end',
    ['vim.api.nvim_open_win'] = 'function() return 20 end',
  })

  load_module()
  lua('LazyDocker.open()')
  eq(get('__LazyDocker_Process_JobID'), 99)

  lua(('_G.mock_logs.callbacks[%d]()'):format(opened_buf_id))

  eq(get('_G.mock_logs.jobwait.jobs'), { 99 })
  eq(get('_G.mock_logs.jobstop'), 99)
  eq(get('__LazyDocker_Process_JobID'), vim.NIL)
  eq(get('_G.mock_logs.del_augroup'), 55)
end

T['open()']['lazydocker spawn behavior']['stops previous job if running'] = function()
  mock_child_functions(child, {
    ['vim.fn.executable'] = 'function(cmd) return 1 end',
    ['vim.fn.jobwait'] = [[
    function(jobs, timeout)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.jobwait = _G.mock_logs.jobwait or {}
      table.insert(_G.mock_logs.jobwait, { jobs=jobs, timeout=timeout })
      if jobs[1] == 100 then return {-1} end
      return {0}
    end
    ]],
    ['vim.fn.jobstop'] = [[
    function(job)
      _G.mock_logs = _G.mock_logs or {}
      _G.mock_logs.jobstop = _G.mock_logs.jobstop or {}
      table.insert(_G.mock_logs.jobstop, job)
    end
    ]],
    ['vim.fn.termopen'] = 'function() return 101 end',
    ['vim.api.nvim_create_autocmd'] = 'function() end',
    ['vim.api.nvim_create_augroup'] = 'function() return 55 end',
    ['vim.api.nvim_create_buf'] = 'function() return 10 end',
    ['vim.api.nvim_open_win'] = 'function() return 20 end',
  })

  load_module()

  lua('__LazyDocker_Process_JobID = 100')

  lua('LazyDocker.open()')

  local jobwait_log = get('_G.mock_logs.jobwait')
  local jobstop_log = get('_G.mock_logs.jobstop')

  eq(jobwait_log[1].jobs, { 100 })
  eq(jobstop_log[1], 100)
  eq(get('__LazyDocker_Process_JobID'), 101)
end

T['open()']['lazydocker spawn behavior']['focuses existing window if already open'] = function()
  local existing_win_id = 100
  mock_child_functions(child, {
    ['vim.api.nvim_win_is_valid'] = 'function(win) return win == 100 end',
    ['vim.api.nvim_set_current_win'] = [[
      function(win)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.set_current_win = win
      end
    ]],
    ['vim.fn.termopen'] = [[ -- Should not be called
      function(...)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.termopen_called = true
      end
    ]],
  })

  load_module()
  lua('_G.__LazyDocker_Window_Handle = 100')

  lua('LazyDocker.open()')

  eq(get('_G.mock_logs.set_current_win'), existing_win_id)
  eq(get('_G.mock_logs.termopen_called'), vim.NIL)
end

T['open()']['lazydocker spawn behavior']['respects minimum width'] = function()
  mock_child_functions(child, {
    ['vim.fn.executable'] = 'function() return 1 end',
    ['vim.fn.termopen'] = 'function() return 99 end',
    ['vim.api.nvim_create_autocmd'] = 'function() end',
    ['vim.api.nvim_create_augroup'] = 'function() return 55 end',
    ['vim.api.nvim_create_buf'] = 'function() return 10 end',
    ['vim.api.nvim_open_win'] = [[
      function(buf, enter, opts)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.open_win_opts = vim.deepcopy(opts)
        return 20
      end
    ]],
  })

  child.o.columns = 50
  load_module({ window = { settings = { width = 0.1 } } })

  lua('LazyDocker.open()')

  local open_win_opts = get('_G.mock_logs and _G.mock_logs.open_win_opts')
  eq(open_win_opts.width, 40)
end

T['open()']['lazydocker spawn behavior']['respects minimum height'] = function()
  mock_child_functions(child, {
    ['vim.fn.executable'] = 'function() return 1 end',
    ['vim.fn.termopen'] = 'function() return 99 end',
    ['vim.api.nvim_create_autocmd'] = 'function() end',
    ['vim.api.nvim_create_augroup'] = 'function() return 55 end',
    ['vim.api.nvim_create_buf'] = 'function() return 10 end',
    ['vim.api.nvim_open_win'] = [[
      function(buf, enter, opts)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.open_win_opts = vim.deepcopy(opts)
        return 20
      end
    ]],
  })

  child.o.lines = 15
  load_module({ window = { settings = { height = 0.1 } } })

  lua('LazyDocker.open()')

  local open_win_opts = get('_G.mock_logs and _G.mock_logs.open_win_opts')
  eq(open_win_opts.height, 10)
end

T['open()']['lazydocker spawn behavior']['uses global winborder if set'] = function()
  mock_child_functions(child, {
    ['vim.fn.exists'] = 'function(opt) return opt == "+winborder" and 1 or 0 end',
    ['vim.fn.executable'] = 'function() return 1 end',
    ['vim.fn.termopen'] = 'function() return 99 end',
    ['vim.api.nvim_create_autocmd'] = 'function() end',
    ['vim.api.nvim_create_augroup'] = 'function() return 55 end',
    ['vim.api.nvim_create_buf'] = 'function() return 10 end',
    ['vim.api.nvim_open_win'] = [[
      function(buf, enter, opts)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.open_win_opts = vim.deepcopy(opts)
        return 20
      end
    ]],
  })

  child.o.winborder = 'double'
  load_module()

  lua('LazyDocker.open()')

  local open_win_opts = get('_G.mock_logs and _G.mock_logs.open_win_opts')
  eq(open_win_opts.border, 'double')
end

T['open()']['lazydocker spawn behavior']['uses plugin border if global winborder is empty'] = function()
  mock_child_functions(child, {
    ['vim.fn.exists'] = 'function(opt) return opt == "+winborder" and 1 or 0 end',
    ['vim.fn.executable'] = 'function() return 1 end',
    ['vim.fn.termopen'] = 'function() return 99 end',
    ['vim.api.nvim_create_autocmd'] = 'function() end',
    ['vim.api.nvim_create_augroup'] = 'function() return 55 end',
    ['vim.api.nvim_create_buf'] = 'function() return 10 end',
    ['vim.api.nvim_open_win'] = [[
      function(buf, enter, opts)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.open_win_opts = vim.deepcopy(opts)
        return 20
      end
    ]],
  })

  child.o.winborder = ''
  load_module()

  lua('LazyDocker.open()')

  local open_win_opts = get('_G.mock_logs and _G.mock_logs.open_win_opts')
  eq(open_win_opts.border, 'rounded')
end

T['open()']['lazydocker spawn behavior']['uses plugin border if winborder option does not exist'] = function()
  mock_child_functions(child, {
    ['vim.fn.exists'] = 'function(opt) return opt == "+winborder" and 0 or 0 end',
    ['vim.fn.executable'] = 'function() return 1 end',
    ['vim.fn.termopen'] = 'function() return 99 end',
    ['vim.api.nvim_create_autocmd'] = 'function() end',
    ['vim.api.nvim_create_augroup'] = 'function() return 55 end',
    ['vim.api.nvim_create_buf'] = 'function() return 10 end',
    ['vim.api.nvim_open_win'] = [[
      function(buf, enter, opts)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.open_win_opts = vim.deepcopy(opts)
        return 20
      end
    ]],
  })

  load_module()

  lua('LazyDocker.open()')

  local open_win_opts = get('_G.mock_logs and _G.mock_logs.open_win_opts')
  eq(open_win_opts.border, 'rounded')
end

T['close()'] = new_set({
  hooks = {
    pre_case = function()
      lua('_G.mock_logs = nil')
      load_module()
    end,
    post_case = function()
      lua('if _G.__restore_mocks then _G.__restore_mocks() end')
      lua('_G.mock_logs = nil')
      lua('_G.__LazyDocker_Window_Handle = nil')
    end,
  },
})

T['close()']['closes the window if open and valid'] = function()
  local valid_win_id = 100
  mock_child_functions(child, {
    ['vim.api.nvim_win_is_valid'] = ('function(win) return win == %d end'):format(valid_win_id),
    ['vim.api.nvim_win_close'] = [[
      function(win, force)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.win_close = { win = win, force = force }
      end
    ]],
  })

  lua(('_G.__LazyDocker_Window_Handle = %d'):format(valid_win_id))
  local result = lua('return LazyDocker.close()')

  local win_close_log = get('_G.mock_logs.win_close')
  eq(win_close_log.win, valid_win_id)
  eq(win_close_log.force, true)
  eq(get('_G.__LazyDocker_Window_Handle'), vim.NIL)
  eq(result, true)
end

T['close()']['returns false if window handle is nil'] = function()
  lua([[
  _G.mock_logs = _G.mock_logs or {}
  _G.mock_logs.win_close_called = false
  ]])

  mock_child_functions(child, {
    ['vim.api.nvim_win_close'] = [[
      function(win, force)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.win_close_called = true
      end
    ]],
  })

  lua('_G.__LazyDocker_Window_Handle = nil')
  local result = lua('return LazyDocker.close()')

  eq(get('_G.mock_logs.win_close_called'), false)
  eq(get('_G.__LazyDocker_Window_Handle'), vim.NIL)
  eq(result, false)
end

T['close()']['returns false if window handle is invalid'] = function()
  local invalid_win_id = 101

  lua([[
  _G.mock_logs = _G.mock_logs or {}
  _G.mock_logs.win_close_called = false
  ]])

  mock_child_functions(child, {
    ['vim.api.nvim_win_is_valid'] = ('function(win) return win ~= %d end'):format(invalid_win_id),
    ['vim.api.nvim_win_close'] = [[ -- Should not be called
      function(win, force)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.win_close_called = true
      end
    ]],
  })

  lua(('_G.__LazyDocker_Window_Handle = %d'):format(invalid_win_id))
  local result = lua('return LazyDocker.close()')

  eq(get('_G.mock_logs.win_close_called'), false)
  eq(get('_G.__LazyDocker_Window_Handle'), invalid_win_id)
  eq(result, false)
end

T['toggle()'] = new_set({
  hooks = {
    pre_case = function()
      lua('_G.mock_logs = nil')
      load_module()
    end,
    post_case = function()
      lua('if _G.__restore_mocks then _G.__restore_mocks() end')
      lua('_G.mock_logs = nil')
    end,
  },
})

T['toggle()']['calls open() if close() returns false'] = function()
  mock_child_functions(child, {
    ['LazyDocker.close'] = [[
      function()
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.close_called = (_G.mock_logs.close_called or 0) + 1
        return false -- Simulate window was not open or failed to close
      end
    ]],
    ['LazyDocker.open'] = [[
      function()
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.open_called = (_G.mock_logs.open_called or 0) + 1
      end
    ]],
  })

  lua('LazyDocker.toggle()')

  eq(get('_G.mock_logs.close_called'), 1)
  eq(get('_G.mock_logs.open_called'), 1)
end

T['toggle()']['calls close() only if close() returns true'] = function()
  mock_child_functions(child, {
    ['LazyDocker.close'] = [[
      function()
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.close_called = (_G.mock_logs.close_called or 0) + 1
        return true -- Simulate window was open and closed successfully
      end
    ]],
    ['LazyDocker.open'] = [[
      function()
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.open_called = (_G.mock_logs.open_called or 0) + 1
      end
    ]],
  })

  lua('LazyDocker.toggle()')

  eq(get('_G.mock_logs.close_called'), 1)
  eq(get('_G.mock_logs.open_called'), vim.NIL)
end

return T
