# lazydocker.nvim

![image](https://github.com/crnvl96/lazydocker.nvim/assets/84354013/a077b68f-9655-4fd1-9b5a-911bb7212809)

Simple and straightforward plugin that allows the user to open [lazydocker](https://github.com/jesseduffield/lazydocker) without quitting their current Neovim section

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

## Configuration

`lazydocker.nvim` comer with the following defaults

```lua
{
  popup_window = {
    enter = true,
    focusable = true,
      zindex = 40,
      position = "50%",
      relative = "win",
      size = {
        width = "90%",
        height = "90%",
      },
      buf_options = {
        modifiable = true,
        readonly = false,
      },
      win_options = {
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
        winblend = 0,
      },
      border = {
        highlight = "FloatBorder",
        style = "rounded",
        text = {
          top = " Lazydocker ",
        },
      },
    }
}
```

## Usage

- Use the command `LazyDocker` to toggle the floating panel

Or set a keymap

```lua
vim.keymap.set("n", "<leader>k", "<cmd>LazyDocker<CR>", { desc = "Toggle LazyDocker", noremap = true, silent = true })
```
