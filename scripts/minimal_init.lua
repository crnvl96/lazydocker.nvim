-- https://github.com/echasnovski/mini.nvim/blob/main/TESTING.md

-- Clone mini.nvim only if it doesn't exist
local mini_path = 'deps/mini.nvim'
if vim.fn.isdirectory(mini_path) == 0 then
  vim.fn.mkdir('deps', 'p')
  vim.fn.system('git clone --filter=blob:none https://github.com/echasnovski/mini.nvim ' .. mini_path)
end

-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.cmd([[let &rtp.=','.getcwd()]])

-- Set up 'mini.test' only when calling headless Neovim (like with `make test`)
if #vim.api.nvim_list_uis() == 0 then
  -- Add 'mini.nvim' to 'runtimepath' to be able to use 'mini.test'
  -- Assumed that 'mini.nvim' is stored in 'deps/mini.nvim'
  vim.cmd('set rtp+=' .. mini_path)

  -- Ensure persistent color scheme (matters after new default in Neovim 0.10)
  vim.o.background = 'dark'
  require('mini.hues').setup({ background = '#11262d', foreground = '#c0c8cc' })

  -- - Make screenshot tests more robust across Neovim versions
  if vim.fn.has('nvim-0.11') == 1 then
    vim.api.nvim_set_hl(0, 'PmenuMatch', { link = 'Pmenu' })
    vim.api.nvim_set_hl(0, 'PmenuMatchSel', { link = 'PmenuSel' })
  end

  -- Set up 'mini'
  require('mini.misc').setup()

  require('mini.test').setup({
    collect = { emulate_busted = false },
    execute = { stop_on_error = true },
  })

  require('mini.doc').setup({
    hooks = {
      write_pre = function(lines)
        -- Remove first two lines with `======` and `------` delimiters to comply
        -- with `:h local-additions` template
        table.remove(lines, 1)
        table.remove(lines, 1)
        return lines
      end,
    },
  })
end
