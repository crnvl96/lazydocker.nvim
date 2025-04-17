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

  local expect_config_type = function(field, value)
    field = ('type(LazyDocker.config.%s)'):format(field)
    eq(get(field), value)
  end

  expect_config_type('width', 'number')
  expect_config_type('height', 'number')
  expect_config_type('border', 'string')
  expect_config_type('style', 'string')
end

T['setup()']['check default config'] = function()
  load_module()

  eq(get('LazyDocker.config.height'), 0.618)
  eq(get('LazyDocker.config.width'), 0.618)
  eq(get('LazyDocker.config.border'), 'rounded')
  eq(get('LazyDocker.config.style'), 'minimal')
end

T['setup()']['check custom config'] = function()
  load_module({ width = 0.5, height = 0.8, border = 'single' })

  eq(get('LazyDocker.config.height'), 0.8)
  eq(get('LazyDocker.config.width'), 0.5)
  eq(get('LazyDocker.config.border'), 'single')
  eq(get('LazyDocker.config.style'), 'minimal')
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
    -- Style
    { { style = 123 }, '.*style.*expected a valid style definition.*got% 123' },
    { { style = -1 }, '.*style.*expected a valid style definition.*got% %-1' },
    { { style = 'invalid_style' }, '.*style.*expected a valid style definition.*got% invalid_style' },
    { { style = true }, '.*style.*expected a valid style definition.*got% true' },
  },
})

T['setup()']['check invalid values']['rejects'] = function(config, msg)
  err(load_module, msg, config)
end

T['open()'] = new_set({
  hooks = {
    pre_case = function()
      local has_winborder = get([[pcall(function() return vim.o.winborder end)]])
      if not has_winborder then
        skip('Neovim version does not support vim.o.winborder')
        return
      end
    end,
  },
})

T['open()']['uses config.border when vim.o.winborder is default'] = function()
  api.nvim_set_option_value('winborder', '', {})
  load_module({ border = 'single' })
  lua('LazyDocker.open()')
  eq(get_current_win_config().border, { '┌', '─', '┐', '│', '┘', '─', '└', '│' })
end

T['open()']['uses vim.o.winborder when set, overriding config.border'] = function()
  api.nvim_set_option_value('winborder', 'double', {})
  load_module({ border = 'single' })
  lua('LazyDocker.open()')
  eq(get_current_win_config().border, { '╔', '═', '╗', '║', '╝', '═', '╚', '║' })
end

return T
