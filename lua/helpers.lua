local M = {}
local H = {}

H.is_percentage = function(a)
  if type(a) ~= 'number' then
    return false
  end

  if a <= 0 or a > 1 then
    return false
  end

  return true
end

H.is_valid_border = function(a)
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

H.is_valid_style = function(a)
  return a == 'minimal'
end

M.setup_config = function(base_config, config)
  vim.validate({
    ['LazyDocker.config'] = { config, 'table', true },
  })

  config = vim.tbl_deep_extend('force', vim.deepcopy(base_config), config or {})

  vim.validate({
    ['LazyDocker.config.width'] = { config.width, H.is_percentage, 'a number between 0 and 1' },
    ['LazyDocker.config.height'] = { config.height, H.is_percentage, 'a number between 0 and 1' },
    ['LazyDocker.config.border'] = { config.border, H.is_valid_border, 'a valid border definition' },
    ['LazyDocker.config.style'] = { config.style, H.is_valid_style, 'a valid style definition' },
  })

  return config
end

return M
