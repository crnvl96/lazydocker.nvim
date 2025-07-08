-- https://github.com/echasnovski/mini.nvim/blob/main/TESTING.md

local Helpers = {}

Helpers.expect = vim.deepcopy(MiniTest.expect)

Helpers.new_child_neovim = function()
  local child = MiniTest.new_child_neovim()

  child.capture = function(...)
    print(child.cmd_capture(...))
  end

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

  child.load_lzd = function(config)
    child.lua([[require('lazydocker').setup(...)]], { config })
  end

  child.unload_lzd = function()
    -- Unload Lua module
    child.lua([[package.loaded['lazydocker'] = nil]])
    -- Remove global table
    child.lua('_G[LazyDocker] = nil')
    -- Remove autocmd group
    if child.fn.exists('#LazyDocker') == 1 then
      child.api.nvim_del_augroup_by_name('LazyDocker')
    end
  end

  return child
end

Helpers.mock_child_functions = function(child, mocks)
  local lua = child.lua
  local setup_code = {}

  table.insert(setup_code, 'local original_fns = {}')

  for name, mock_impl_fn_code in pairs(mocks) do
    local quoted_name = vim.inspect(name)

    table.insert(
      setup_code,
      string.format(
        [=[
        do -- Use a do block for local scope
          local name_str = %s -- Use the quoted name
          local parts = {}
          for part in string.gmatch(name_str, '[^%%.]+') do
            table.insert(parts, part)
          end

          local current_obj = _G
          local obj_name = nil
          local original_fn = nil
          local found = true

          for i = 1, #parts do
            obj_name = parts[i]
            if i == #parts then
              -- Check existence before accessing
              if current_obj and type(current_obj) == 'table' and current_obj[obj_name] then
                original_fn = current_obj[obj_name]
              else
                original_fn = nil -- Mark original as nil if not found
                found = false
              end
              -- Use quoted name as the key
              original_fns[%s] = original_fn
              -- Only assign if the path was valid up to the parent
              if found and current_obj and type(current_obj) == 'table' then
                 -- Inject the mock function code directly
                current_obj[obj_name] = %s
              end
            else
              -- Check existence and type before traversing
              if not current_obj or type(current_obj) ~= 'table' or not current_obj[obj_name] then
                original_fns[%s] = nil -- Store nil if path is broken
                found = false
                break -- Stop traversal
              end
              current_obj = current_obj[obj_name]
            end
          end
        end
        ]=],
        quoted_name, -- For gmatch
        quoted_name, -- For original_fns key
        mock_impl_fn_code, -- The string containing mock function code
        quoted_name -- For original_fns key in else branch
      )
    )
  end

  table.insert(
    setup_code,
    [=[
  _G.__restore_mocks = function()
    for name_str, orig_fn in pairs(original_fns) do
      local parts = {}
      -- No double escape needed here, it's raw Lua code now
      for part in string.gmatch(name_str, '[^%.]+') do
        table.insert(parts, part)
      end

      local current_obj = _G
      local obj_name = nil
      local possible = true

      for i = 1, #parts do
        obj_name = parts[i]
        if i == #parts then
          -- Restore only if traversal was possible
          if possible and current_obj and type(current_obj) == 'table' then
            current_obj[obj_name] = orig_fn
          end
        else
          -- Check existence before traversing during restore
          if not current_obj or type(current_obj) ~= 'table' or current_obj[obj_name] == nil then
            possible = false
            break -- Can't traverse further
          end
          current_obj = current_obj[obj_name]
        end
      end
    end

    -- Cleanup globals
    _G.__restore_mocks = nil
    original_fns = nil -- Make it explicitly nil
  end
  ]=]
  )

  lua(table.concat(setup_code, '\n'))
end

Helpers.is_ci = function()
  return os.getenv('CI') ~= nil
end

Helpers.is_windows = function()
  return vim.fn.has('win32') == 1
end

Helpers.is_macos = function()
  return vim.fn.has('mac') == 1
end

Helpers.is_linux = function()
  return vim.fn.has('linux') == 1
end

Helpers.get_n_retry = function(n)
  local coef = 1
  if Helpers.is_ci() then
    if Helpers.is_linux() then
      coef = 2
    end
    if Helpers.is_windows() then
      coef = 3
    end
    if Helpers.is_macos() then
      coef = 4
    end
  end
  return coef * n
end

return Helpers
