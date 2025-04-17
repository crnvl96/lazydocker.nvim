local M = {}

local function _is_percentage(a)
  if type(a) ~= 'number' then
    return false
  end

  if a <= 0 or a > 1 then
    return false
  end

  return true
end

local function _is_valid_border(a)
  local borders = {
    ['none'] = true,
    ['single'] = true,
    ['double'] = true,
    ['rounded'] = true,
    ['solid'] = true,
    ['shadow'] = true,
  }

  return borders[a]
end

local function _is_valid_relative(a)
  local relatives = {
    ['cursor'] = true,
    ['editor'] = true,
    ['laststatus'] = true,
    ['mouse'] = true,
    ['tabline'] = true,
    ['win'] = true,
  }
  return relatives[a]
end

local function _is_lazydocker_available()
  return vim.fn.executable('lazydocker') == 1
end

local function _is_docker_available()
  return vim.fn.executable('docker') == 1
end

function M.setup_config(base_config, config)
  vim.validate({
    ['LazyDocker.config'] = { config, 'table', true },
  })

  config = vim.tbl_deep_extend('force', vim.deepcopy(base_config), config or {})

  vim.validate({
    ['LazyDocker.config.width'] = { config.width, _is_percentage, 'a number between 0 and 1' },
    ['LazyDocker.config.height'] = { config.height, _is_percentage, 'a number between 0 and 1' },
    ['LazyDocker.config.border'] = { config.border, _is_valid_border, 'a valid border definition' },
    ['LazyDocker.config.relative'] = { config.relative, _is_valid_relative, 'a valid relative definition' },
  })

  return config
end

function M.check_prerequisites()
  if not _is_docker_available() then
    vim.notify('LazyDocker: "docker" command not found. Please install Docker.', vim.log.levels.ERROR)
    return false
  end

  if not _is_lazydocker_available() then
    vim.notify('LazyDocker: "lazydocker" command not found. Please install lazydocker.', vim.log.levels.ERROR)
    return false
  end

  return true
end

function M.stop_hanging_job()
  if LazyDocker.job_id and vim.fn.jobwait({ LazyDocker.job_id }, 0)[1] == -1 then
    vim.fn.jobstop(LazyDocker.job_id)
    LazyDocker.job_id = nil
  end
end

function M.create_win_and_buffer(win_opts)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  return buf, win
end

function M.get_win_custom_config(config)
  local win_height = math.max(10, math.floor(vim.o.lines * config.height)) -- Ensure minimum height
  local win_width = math.max(40, math.floor(vim.o.columns * config.width)) -- Ensure minimum width

  local border_style = config.border
  if vim.fn.exists('+winborder') == 1 then
    local global_winborder = vim.o.winborder
    if global_winborder ~= '' and global_winborder ~= nil then
      border_style = global_winborder
    end
  end

  return {
    relative = config.relative,
    width = win_width,
    height = win_height,
    row = math.floor((vim.o.lines - win_height) / 2),
    col = math.floor((vim.o.columns - win_width) / 2),
    border = border_style,
  }
end

function M.register_job_cleanup_autocmds(buf, win)
  local group = vim.api.nvim_create_augroup('LazyDockerTermCleanup', { clear = true })

  local cleanup_callback = function()
    M.stop_hanging_job()
    pcall(vim.api.nvim_del_augroup_by_id, group)
  end

  vim.api.nvim_create_autocmd({ 'BufWipeout' }, {
    buffer = buf,
    group = group,
    once = true,
    callback = cleanup_callback,
  })

  vim.api.nvim_create_autocmd({ 'WinClosed' }, {
    pattern = tostring(win),
    group = group,
    once = true,
    callback = cleanup_callback,
  })
end

function M.start_lazydocker_job(win)
  local job_id = vim.fn.termopen('lazydocker', {
    on_exit = function()
      LazyDocker.job_id = nil
      if vim.api.nvim_win_is_valid(win) then
        vim.schedule(function()
          vim.api.nvim_win_close(win, true)
        end)
      end
    end,
  })
  LazyDocker.job_id = job_id
end

return M
