# lazydocker.nvim

## Inspiration

 - [kdheepak/lazygit.nvim](kdheepak/lazygit.nvim)

## Alternatives

- [akinsho/nvim-toggleterm](https://github.com/akinsho/nvim-toggleterm.lua#custom-terminals)
- [voldikss/vim-floaterm](https://github.com/voldikss/vim-floaterm)

## Installation

#### Requirements
- [Docker](https://docs.docker.com/)
- [lazydocker](https://github.com/jesseduffield/lazydocker)

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
    opts = {},  -- automatically calls `require("lazydocker").setup()`
    dependencies = {
      "MunifTanjim/nui.nvim",
    }
}
```

## Usage

- Use the command `LazyDocker` to toggle the floating panel

Or set a keymap

```lua
vim.keymap.set("n", "<leader>k", "<cmd>LazyDocker<CR>", { desc = "Toggle LazyDocker", noremap = true, silent = true })
```
