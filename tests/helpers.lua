-- https://github.com/echasnovski/mini.nvim/blob/main/TESTING.md

local Helpers = {}

Helpers.expect = vim.deepcopy(MiniTest.expect)

Helpers.new_child_neovim = function()
  local child = MiniTest.new_child_neovim()

  -- Poke child's event loop to make it up to date
  child.poke_eventloop = function() child.api.nvim_eval('1') end

  child.capture = function(...) print(child.cmd_capture(...)) end

  child.setup = function()
    child.restart({ '-u', 'scripts/minimal_init.lua' })
    -- Change initial buffer to be readonly. This not only increases execution
    -- speed, but more closely resembles manually opened Neovim.
    child.bo.readonly = false
    child.o.laststatus = 0
    child.o.ruler = false
    child.o.lines = 15
    child.o.columns = 40
  end

  child.load_lzd = function(config) child.lua([[require('lazydocker').setup(...)]], { config }) end

  child.unload_lzd = function()
    -- Unload Lua module
    child.lua([[package.loaded['lazydocker'] = nil]])
    -- Remove global table
    child.lua('_G[LazyDocker] = nil')
    -- Remove autocmd group
    if child.fn.exists('#LazyDocker') == 1 then child.api.nvim_del_augroup_by_name('LazyDocker') end
  end

  return child
end

Helpers.sleep = function(ms, child)
  vim.loop.sleep(math.max(ms, 1))

  if child ~= nil then child.poke_eventloop() end
end

Helpers.is_ci = function() return os.getenv('CI') ~= nil end
Helpers.is_windows = function() return vim.fn.has('win32') == 1 end
Helpers.is_macos = function() return vim.fn.has('mac') == 1 end
Helpers.is_linux = function() return vim.fn.has('linux') == 1 end

Helpers.get_n_retry = function(n)
  local coef = 1
  if Helpers.is_ci() then
    if Helpers.is_linux() then coef = 2 end
    if Helpers.is_windows() then coef = 3 end
    if Helpers.is_macos() then coef = 4 end
  end
  return coef * n
end

return Helpers
