# lazydocker.nvim

# Inspiration

 - [kdheepak/lazygit.nvim](kdheepak/lazygit.nvim)

# Alternatives

- [akinsho/nvim-toggleterm](https://github.com/akinsho/nvim-toggleterm.lua#custom-terminals)
- [voldikss/vim-floaterm](https://github.com/voldikss/vim-floaterm) as an alternative to this package.

# Installation

At the moment, the plugin does not support the insertion of any options or customizations. This feature is in the roadmap, which you can check [here](#Roadmap)

```lua
-- Packer
use({
  "crnvl96/lazydocker.nvim",
    config = function()
      require("lazydocker").setup()
    end,
    requires = {
      "MunifTanjim/nui.nvim",
    }
})

-- Lazy
{
  "crnvl96/lazydocker.nvim",
    event = "VeryLazy",
    -- automatically calls `require("lazydocker").setup()`
    opts = {},
    dependencies = {
      "MunifTanjim/nui.nvim",
    }
}
```

# Usage

- Use the command `LazyDocker` to toggle the floating panel

Or set a keymap

```lua
vim.keymap.set("n", "<leader>k", "<cmd>LazyDocker<CR>", { noremap = true, silent = true })
```

# Roadmap

- Add support for plugin options
