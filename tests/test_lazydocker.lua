local helpers = dofile('tests/helpers.lua')
local child = helpers.new_child_neovim()
local new_set = MiniTest.new_set

local eq = helpers.expect.equality
local err = helpers.expect.error

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

return T
