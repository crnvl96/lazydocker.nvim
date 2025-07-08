local Mocks = {}

Mocks.apply = function(mocks)
  for _, m in ipairs(mocks) do
    m.apply()
  end
end

Mocks.restore = function(mocks)
  for _, m in ipairs(mocks) do
    m.restore()
  end
end

Mocks.vim_fn_executable_no_docker = function(child)
  local lua = child.lua
  return {
    apply = function()
      lua([[
      _G.original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        if cmd == 'docker' then
          return 0
        else
          return 1
        end
      end
    ]])
    end,
    restore = function()
      lua([[
      vim.fn.executable = _G.original_executable
      _G.original_executable = nil
    ]])
    end,
  }
end

Mocks.vim_fn_executable_no_podman = function(child)
  local lua = child.lua
  return {
    apply = function()
      lua([[
      _G.original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        if cmd == 'podman' then
          return 0
        else
          return 1
        end
      end
    ]])
    end,
    restore = function()
      lua([[
      vim.fn.executable = _G.original_executable
      _G.original_executable = nil
    ]])
    end,
  }
end

Mocks.vim_fn_executable_no_lazydocker = function(child)
  local lua = child.lua
  return {
    apply = function()
      lua([[
      _G.original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        if cmd == 'lazydocker' then
          return 0
        else
          return 1
        end
      end
    ]])
    end,
    restore = function()
      lua([[
      vim.fn.executable = _G.original_executable
      _G.original_executable = nil
    ]])
    end,
  }
end

Mocks.vim_fn_executable = function(child)
  local lua = child.lua
  return {
    apply = function()
      lua([[
      _G.original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        return 1
      end
    ]])
    end,
    restore = function()
      lua([[
      vim.fn.executable = _G.original_executable
      _G.original_executable = nil
    ]])
    end,
  }
end

Mocks.vim_fn_jobstart = function(child)
  local lua = child.lua
  return {
    apply = function()
      lua([[
      _G.original_jobstart = vim.fn.jobstart
      vim.fn.jobstart = function(cmd,opts)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.jobstart = _G.mock_logs.jobstart or {cmd=cmd,on_exit=opts.on_exit,env=opts.env,term=opts.term}
        return 99
      end
    ]])
    end,
    restore = function()
      lua([[
      vim.fn.jobstart = _G.original_jobstart
      _G.original_jobstart = nil
    ]])
    end,
  }
end

Mocks.vim_fn_notify = function(child)
  local lua = child.lua
  return {
    apply = function()
      lua([[
      _G.notify_messages = {}
      _G.original_notify = vim.notify
      vim.notify = function(msg, level)
        table.insert(_G.notify_messages, { msg = msg, level = level })
      end
    ]])
    end,
    restore = function()
      lua([[
      vim.notify = _G.original_notify
      _G.notify_messages = nil
      _G.original_notify = nil
    ]])
    end,
  }
end

Mocks.vim_api_nvim_set_current_win = function(child)
  local lua = child.lua
  return {
    apply = function()
      lua([[
      _G.original_set_current_win = vim.api.nvim_set_current_win
      vim.api.nvim_set_current_win = function() end
    ]])
    end,
    restore = function()
      lua([[
      vim.api.nvim_set_current_win = _G.original_set_current_win
      _G.original_set_current_win = nil
    ]])
    end,
  }
end

Mocks.vim_api_nvim_create_buf = function(child)
  local lua = child.lua
  return {
    apply = function()
      lua([[
      _G.original_create_buf = vim.api.nvim_create_buf
      vim.api.nvim_create_buf = function() return 10 end
    ]])
    end,
    restore = function()
      lua([[
      vim.api.nvim_create_buf = _G.original_create_buf
      _G.original_create_buf = nil
    ]])
    end,
  }
end

Mocks.vim_api_nvim_win_is_valid = function(child)
  local lua = child.lua
  return {
    apply = function()
      lua([[
      _G.original_win_is_valid = vim.api.nvim_win_is_valid
      vim.api.nvim_win_is_valid = function() return true end
    ]])
    end,
    restore = function()
      lua([[
      vim.api.nvim_win_is_valid = _G.original_win_is_valid
      _G.original_win_is_valid = nil
    ]])
    end,
  }
end

Mocks.vim_api_nvim_create_autocmd = function(child)
  local lua = child.lua
  return {
    apply = function()
      lua([[
      _G.original_create_autocmd = vim.api.nvim_create_autocmd
      vim.api.nvim_create_autocmd = function() end
    ]])
    end,
    restore = function()
      lua([[
      vim.api.nvim_create_autocmd = _G.original_create_autocmd
      _G.original_create_autocmd = nil
    ]])
    end,
  }
end

Mocks.vim_api_nvim_create_augroup = function(child)
  local lua = child.lua
  return {
    apply = function()
      lua([[
      _G.original_create_augroup = vim.api.nvim_create_augroup
      vim.api.nvim_create_augroup = function() return 30 end
    ]])
    end,
    restore = function()
      lua([[
      vim.api.nvim_create_augroup = _G.original_create_augroup
      _G.original_create_augroup = nil
    ]])
    end,
  }
end

Mocks.vim_api_nvim_open_win = function(child)
  local lua = child.lua
  return {
    apply = function()
      lua([[
      _G.original_open_win = vim.api.nvim_open_win
      vim.api.nvim_open_win = function() return 20 end
    ]])
    end,
    restore = function()
      lua([[
      vim.api.nvim_open_win = _G.original_open_win
      _G.original_open_win = nil
    ]])
    end,
  }
end

return Mocks
