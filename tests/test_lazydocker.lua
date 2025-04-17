local helpers = dofile('tests/helpers.lua')
local child = helpers.new_child_neovim()

local new_set = MiniTest.new_set
local skip = MiniTest.skip

local eq = helpers.expect.equality
local err = helpers.expect.error

local lua = child.lua
local get = child.lua_get
local api = child.api

local load_module = function(config)
  child.load_lzd(config)
end

local get_current_win_config = function()
  local win_id = get('vim.api.nvim_get_current_win()')
  return get(('vim.api.nvim_win_get_config(%d)'):format(win_id))
end

local mock_child_functions = function(mocks)
  local setup_code = {}

  table.insert(setup_code, 'local original_fns = {}')

  for name, mock_impl in pairs(mocks) do
    table.insert(
      setup_code,
      string.format(
        [=[
        if %s then
          original_fns['%s'] = %s
        else
          original_fns['%s'] = nil
        end
        ]=],
        name,
        name,
        name,
        name
      )
    )
    table.insert(setup_code, string.format('%s = %s', name, mock_impl))
  end

  table.insert(
    setup_code,
    [=[
    _G.__restore_mocks = function()
      for name, orig_fn in pairs(original_fns) do
        _G[name] = orig_fn -- Restore global functions if needed (like vim.fn.executable)
        -- Handle nested tables like vim.fn
        local parts = {}
        for part in string.gmatch(name, '[^%.]+') do table.insert(parts, part) end
        local T = _G
        for i = 1, #parts - 1 do T = T[parts[i]] end
        T[parts[#parts]] = orig_fn
      end
      _G.__restore_mocks = nil -- Clean up restore function
      original_fns = nil
    end
    ]=]
  )

  lua(table.concat(setup_code, '\n'))
end

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()

      child.o.laststatus = 0
      child.o.ruler = false
      child.set_size(15, 40)
    end,
    post_once = child.stop,
    n_retry = helpers.get_n_retry(1),
  },
})

T['setup()'] = new_set()

T['setup()']['validate global table'] = function()
  load_module()
  eq(get('type(LazyDocker)'), 'table')
  eq(get('type(LazyDocker.config)'), 'table')
end

T['setup()']['validate global table property types'] = function()
  local expect_config_type = function(field, value)
    field = ('type(LazyDocker.config.%s)'):format(field)
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

  eq(get('LazyDocker.config.height'), 0.618)
  eq(get('LazyDocker.config.width'), 0.618)
  eq(get('LazyDocker.config.border'), 'rounded')
  eq(get('LazyDocker.config.relative'), 'editor')
end

T['setup()']['check custom config'] = function()
  load_module({ width = 0.5, height = 0.8, border = 'single', relative = 'cursor' })

  eq(get('LazyDocker.config.height'), 0.8)
  eq(get('LazyDocker.config.width'), 0.5)
  eq(get('LazyDocker.config.border'), 'single')
  eq(get('LazyDocker.config.relative'), 'cursor')
end

T['setup()']['check invalid values'] = new_set({
  parametrize = {
    { 'a', 'LazyDocker.config: expected table, got string' },
    -- Width
    { { width = 'a' }, '.*width.*a number between 0 and 1.*got a' },
    { { width = 0 }, '.*width.*a number between 0 and 1.*got 0' },
    { { width = 1.5 }, '.*width.*a number between 0 and 1.*got 1.5' },
    { { width = -1 }, '.*width.*a number between 0 and 1.*got %-1' },
    { { width = true }, '.*width.*a number between 0 and 1.*got true' },
    -- Height
    { { height = 'a' }, '.*height.*a number between 0 and 1.*got a' },
    { { height = 0 }, '.*height.*a number between 0 and 1.*got 0' },
    { { height = 1.5 }, '.*height.*a number between 0 and 1.*got 1.5' },
    { { height = -1 }, '.*height.*a number between 0 and 1.*got %-1' },
    { { height = true }, '.*height.*a number between 0 and 1.*got true' },
    -- Border
    { { border = 123 }, '.*border.*expected a valid border definition.*got% 123' },
    { { border = -1 }, '.*border.*expected a valid border definition.*got% %-1' },
    { { border = 'invalid' }, '.*border.*expected a valid border definition.*got% invalid' },
    { { border = true }, '.*border.*expected a valid border definition.*got% true' },
    -- Relative
    { { relative = 123 }, '.*relative.*expected a valid relative definition.*got% 123' },
    { { relative = -1 }, '.*relative.*expected a valid relative definition.*got% %-1' },
    { { relative = 'invalid' }, '.*relative.*expected a valid relative definition.*got% invalid' },
    { { relative = true }, '.*relative.*expected a valid relative definition.*got% true' },
  },
})

T['setup()']['check invalid values']['rejects'] = function(config, msg)
  err(load_module, msg, config)
end

T['open()'] = new_set()

T['open()']['check border attribution behavior'] = new_set({
  hooks = {
    pre_case = function()
      local has_winborder = get([[pcall(function() return vim.o.winborder end)]])
      if not has_winborder then
        skip('Neovim version does not support vim.o.winborder')
        return
      end
    end,
  },
  parametrize = {
    -- { vim.o.winborder, config.border, expected_border_in_win_config }
    { '', 'single', { '┌', '─', '┐', '│', '┘', '─', '└', '│' } },
    { 'double', 'single', { '╔', '═', '╗', '║', '╝', '═', '╚', '║' } },
  },
})

T['open()']['check border attribution behavior']['applies correct border'] = function(
  winborder_val,
  config_border,
  expect
)
  api.nvim_set_option_value('winborder', winborder_val, {})
  load_module({ border = config_border })
  lua('LazyDocker.open()')
  local win_config = get_current_win_config()
  eq(win_config.border, expect)
end

T['open()']['check relative attribution behavior'] = new_set({
  parametrize = {
    { 'editor' },
    { 'tabline' },
    { 'win' },
  },
})

T['open()']['check relative attribution behavior']['applies correct relative'] = function(relative_val)
  load_module({ relative = relative_val })

  if relative_val == 'cursor' then
    child.set_cursor(0, 0, api.nvim_get_current_win())
  end

  lua('LazyDocker.open()')
  eq(get_current_win_config().relative, relative_val)
end

T['open()']['lazydocker spawn behavior'] = new_set({
  hooks = {
    post_case = function()
      lua('if _G.__restore_mocks then _G.__restore_mocks() end')
      lua('_G.mock_logs = nil')
    end,
  },
})

T['open()']['lazydocker spawn behavior']['shows error if docker is missing'] = function()
  mock_child_functions({
    ['vim.notify'] = [[
      function(...)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.notify = _G.mock_logs.notify or {}
        table.insert(_G.mock_logs.notify, vim.deepcopy({...}))
      end
    ]],
    ['vim.fn.executable'] = [[
      function(cmd)
        if cmd == 'docker' then return 0 end
        return 1 -- Assume lazydocker exists for this test
      end
    ]],
  })

  load_module()
  lua('LazyDocker.open()')

  local notify_log = get('_G.mock_logs and _G.mock_logs.notify')

  eq(notify_log[1][1], 'LazyDocker: "docker" command not found. Please install Docker.')
  eq(notify_log[1][2], get('vim.log.levels.ERROR'))
end

T['open()']['lazydocker spawn behavior']['shows error if lazydocker is missing'] = function()
  mock_child_functions({
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
        return 1 -- Assume docker exists
      end
    ]],
  })

  load_module()
  lua('LazyDocker.open()')

  local notify_log = get('_G.mock_logs and _G.mock_logs.notify')

  eq(notify_log[1][1], 'LazyDocker: "lazydocker" command not found. Please install lazydocker.')
  eq(notify_log[1][2], get('vim.log.levels.ERROR'))
end

T['open()']['lazydocker spawn behavior']['spawns lazydocker and sets up correctly'] = function()
  mock_child_functions({
    ['vim.fn.executable'] = 'function(cmd) return 1 end',
    ['vim.fn.termopen'] = [[
      function(cmd, opts)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.termopen = { cmd = cmd, on_exit = opts.on_exit }
        return 99 -- Return mock job_id
      end
    ]],
    ['vim.api.nvim_create_augroup'] = [[
      function(name, opts)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.augroup = { name = name, opts = opts }
        return 55 -- Return mock group ID
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
  })

  load_module()
  lua('LazyDocker.open()')

  local termopen_cmd = get('_G.mock_logs and _G.mock_logs.termopen.cmd')
  local termopen_on_exit_type = get('_G.mock_logs and type(_G.mock_logs.termopen.on_exit)')
  local augroup_log = get('_G.mock_logs and _G.mock_logs.augroup')
  local autocmd_log = get('_G.mock_logs and _G.mock_logs.autocmd')
  local current_buf = get('vim.api.nvim_get_current_buf()')
  local current_win = get('vim.api.nvim_get_current_win()')

  eq(termopen_cmd, 'lazydocker')
  eq(termopen_on_exit_type, 'function')
  eq(get('LazyDocker.job_id'), 99)

  eq(augroup_log.name, 'LazyDockerTermCleanup')
  eq(augroup_log.opts.clear, true)

  eq(#autocmd_log, 2)

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
  mock_child_functions({
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
    ['vim.api.nvim_create_autocmd'] = 'function() end',
    ['vim.api.nvim_create_augroup'] = 'function() return 55 end',
  })

  load_module()
  lua('LazyDocker.open()')
  local opened_win = get('vim.api.nvim_get_current_win()')
  eq(get('LazyDocker.job_id'), 99)

  lua('_G.mock_logs.termopen_on_exit()')

  local win_close_log = get('_G.mock_logs and _G.mock_logs.win_close')

  eq(get('LazyDocker.job_id'), vim.NIL)
  eq(win_close_log.win, opened_win)
  eq(win_close_log.force, true)
end

T['open()']['lazydocker spawn behavior']['handles window close'] = function()
  mock_child_functions({
    ['vim.fn.executable'] = 'function(cmd) return 1 end',
    ['vim.fn.termopen'] = 'function() return 99 end',
    ['vim.fn.jobwait'] = [[
        function(jobs, timeout)
            _G.mock_logs = _G.mock_logs or {}
            _G.mock_logs.jobwait = { jobs=jobs, timeout=timeout }
            if jobs[1] == 99 then return {-1} end -- Simulate job is running
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
             if opts.pattern then -- Store WinClosed callback
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
  })

  load_module()
  lua('LazyDocker.open()')
  local opened_win = get('vim.api.nvim_get_current_win()')
  eq(get('LazyDocker.job_id'), 99)

  lua(('_G.mock_logs.callbacks["%s"]()'):format(tostring(opened_win)))

  eq(get('_G.mock_logs.jobwait.jobs'), { 99 })
  eq(get('_G.mock_logs.jobstop'), 99)
  eq(get('LazyDocker.job_id'), vim.NIL)
  eq(get('_G.mock_logs.del_augroup'), 55)
end

T['open()']['lazydocker spawn behavior']['handles buffer wipeout'] = function()
  mock_child_functions({
    ['vim.fn.executable'] = 'function(cmd) return 1 end',
    ['vim.fn.termopen'] = 'function() return 99 end',
    ['vim.fn.jobwait'] = [[
        function(jobs, timeout)
            _G.mock_logs = _G.mock_logs or {}
            _G.mock_logs.jobwait = { jobs=jobs, timeout=timeout }
            if jobs[1] == 99 then return {-1} end -- Simulate job is running
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
             if opts.buffer then -- Store BufWipeout callback
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
  })

  load_module()
  lua('LazyDocker.open()')
  local opened_buf = get('vim.api.nvim_get_current_buf()')
  eq(get('LazyDocker.job_id'), 99)

  lua(('_G.mock_logs.callbacks[%d]()'):format(opened_buf))

  eq(get('_G.mock_logs.jobwait.jobs'), { 99 })
  eq(get('_G.mock_logs.jobstop'), 99)
  eq(get('LazyDocker.job_id'), vim.NIL)
  eq(get('_G.mock_logs.del_augroup'), 55)
end

T['open()']['lazydocker spawn behavior']['stops previous job if running'] = function()
  mock_child_functions({
    ['vim.fn.executable'] = 'function(cmd) return 1 end',
    ['vim.fn.jobwait'] = [[
        function(jobs, timeout)
            _G.mock_logs = _G.mock_logs or {}
            _G.mock_logs.jobwait = _G.mock_logs.jobwait or {}
            table.insert(_G.mock_logs.jobwait, { jobs=jobs, timeout=timeout })
            if jobs[1] == 100 then return {-1} end -- Simulate job 100 is running
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
    ['vim.fn.termopen'] = 'function() return 101 end', -- New job ID
    ['vim.api.nvim_create_autocmd'] = 'function() end',
    ['vim.api.nvim_create_augroup'] = 'function() return 55 end',
  })

  load_module()
  -- Set existing job id
  lua('LazyDocker.job_id = 100')

  lua('LazyDocker.open()')

  local jobwait_log = get('_G.mock_logs.jobwait')
  local jobstop_log = get('_G.mock_logs.jobstop')

  eq(jobwait_log[1].jobs, { 100 }) -- Check if the old job was waited for
  eq(jobstop_log[1], 100) -- Check if the old job was stopped
  eq(get('LazyDocker.job_id'), 101) -- Check if the new job id is set
end

return T
