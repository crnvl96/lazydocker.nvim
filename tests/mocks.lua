local Mocks = {}

-- Mock management functions for applying and restoring multiple mocks
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

-- Factory function for creating executable command mocks
-- Purpose: Simulates vim.fn.executable() behavior with custom conditions
local function create_executable_mock(child, condition_fn)
  local lua = child.lua
  return {
    apply = function()
      lua([[
      _G.original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        return ]] .. condition_fn .. [[
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

-- Mock: Simulates docker command not being available (returns 0 for docker, 1 for others)
-- Used in: Tests for docker executable absence error handling
Mocks.vim_fn_executable_no_docker = function(child) return create_executable_mock(child, "cmd == 'docker' and 0 or 1") end

-- Mock: Simulates podman command not being available (returns 0 for podman, 1 for others)
-- Used in: Tests for podman executable absence error handling
Mocks.vim_fn_executable_no_podman = function(child) return create_executable_mock(child, "cmd == 'podman' and 0 or 1") end

-- Mock: Simulates lazydocker command not being available (returns 0 for lazydocker, 1 for others)
-- Used in: Tests for lazydocker executable absence error handling
Mocks.vim_fn_executable_no_lazydocker = function(child)
  return create_executable_mock(child, "cmd == 'lazydocker' and 0 or 1")
end

-- Mock: Simulates all commands being available (always returns 1)
-- Used in: Tests for successful command execution scenarios
Mocks.vim_fn_executable = function(child) return create_executable_mock(child, '1') end

-- Mock: Captures jobstart calls and logs parameters for verification
-- Purpose: Records command, environment, and callback details of jobstart calls
-- Used in: Tests for verifying lazydocker process startup with correct parameters
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

-- Mock: Captures vim.notify calls for error message verification
-- Purpose: Records notification messages and their severity levels
-- Used in: Tests for verifying proper error notifications when commands are missing
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

-- Mock: Stubs nvim_set_current_win to prevent actual window focus changes
-- Purpose: Prevents side effects during testing while allowing API calls to proceed
-- Used in: Tests for window management where focus changes are not relevant
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

-- Mock: Simulates window validation always returning true
-- Purpose: Allows tests to assume windows are valid for testing close operations
-- Used in: Tests for window closure functionality where window validity is assumed
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

-- Mock: Stubs nvim_open_win to return a fixed window handle
-- Purpose: Prevents actual window creation while providing consistent window IDs
-- Used in: Tests for window management where window creation is not the focus
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

-- Mock: Captures nvim_win_close calls and logs invocation details
-- Purpose: Records when window close is called and with what arguments
-- Used in: Tests for verifying window closure behavior and argument validation
Mocks.vim_api_nvim_win_close = function(child)
  local lua = child.lua
  return {
    apply = function()
      lua([[
      _G.original_win_close = vim.api.nvim_win_close
      vim.api.nvim_win_close = function(...)
        _G.mock_logs = _G.mock_logs or {}
        _G.mock_logs.win_close_called = true
        _G.mock_logs.win_close_args = {...}
      end
      ]])
    end,
    restore = function()
      lua([[
      vim.api.nvim_win_close = _G.original_win_close
      _G.original_win_close = nil
      ]])
    end,
  }
end

return Mocks
