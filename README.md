# lazydocker.nvim

Simple and straightforward plugin that allows the user to open [lazydocker](https://github.com/jesseduffield/lazydocker) without quitting their current Neovim session.
For more details, check the [help file](https://github.com/crnvl96/lazydocker.nvim/blob/742dcab71cf9fbb0adcc57831fb9a0f46afa598f/doc/lazydocker.txt)

![image](https://github.com/crnvl96/lazydocker.nvim/assets/84354013/a077b68f-9655-4fd1-9b5a-911bb7212809)

# Contents

- [Inspiration](#inspiration)
- [Alternatives](#alternatives)
- [About this major release](#about-this-latest-major-release)
- [Installation](#installation)
  - [Requirements](#requirements)
  - [Configuration](#configuration)
- [Usage](#usage)

# Inspiration

- [kdheepak/lazygit.nvim](https://github.com/kdheepak/lazygit.nvim)

# Alternatives

- [akinsho/nvim-toggleterm](https://github.com/akinsho/nvim-toggleterm.lua#custom-terminals)
- [voldikss/vim-floaterm](https://github.com/voldikss/vim-floaterm)
- [folke/snacks.nvim](https://github.com/folke/snacks.nvim)

# About this major release

This version introduces several key improvements over the previous major release:

- **Code Clarity:** Great care has been taken with typing and commenting the functions. The codebase should be clear enough for easy understanding and tweaking.
- **Detailed Documentation:** Comprehensive documentation has been added, powered by [mini.doc](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-doc.md).
- **Robust Testing:** Tests have been taken very seriously. A complete suite has been added, including mocks for Neovim's built-in functions for more precise results, powered by [mini.test](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-test.md).
- **Dependency Removal:** The previous version depended on [nui.nvim](https://github.com/MunifTanjim/nui.nvim). This dependency has been removed, allowing for greater internal control and simplifying the plugin's architecture.

# Installation

## Requirements

- Neovim >= 0.10.0
- [Docker](https://docs.docker.com/)
- [lazydocker](https://github.com/jesseduffield/lazydocker) executable in your PATH

```lua
-- Mini.deps

MiniDeps.add('crnvl96/lazydocker.nvim')
require('lazydocker').setup()
```

```lua
-- Lazy
{
  'crnvl96/lazydocker.nvim',
    opts = {},
}
```

## Configuration

`lazydocker.nvim` comes with the following defaults. Call the `setup` function with your overrides.

```lua
-- Default configuration
require('lazydocker').setup({
  window = {
    settings = {
      width = 0.618, -- Percentage of screen width (0 to 1)
      height = 0.618, -- Percentage of screen height (0 to 1)
      border = 'rounded', -- See ':h nvim_open_win' border options
      relative = 'editor', -- See ':h nvim_open_win' relative options
    },
  },
})
```

# Usage

- It exposes the global table `LazyDocker`, for more convenient use
- Use the command `:lua LazyDocker.toggle()` or `:lua require('lazydocker').toggle()` to toggle the floating panel.
- Or set a keymap. It's recommended to map in both normal and terminal modes, as lazydocker runs inside a terminal buffer:

```lua
vim.keymap.set({ 'n', 't' }, '<leader>ld', '<Cmd>lua LazyDocker.toggle()<CR>')
```

- For a more detailed reference about this plugin features, run `:help lazydocker.nvim`
- For a quick reference regarding manipulating lazydocker features within its terminal, check the official [lazydocker keybindings](https://github.com/jesseduffield/lazydocker/blob/master/docs/keybindings/Keybindings_en.md).

# Acknowledgements

Special thanks to the creators and maintainers of these fantastic tools which served as inspiration or provided useful patterns:

- [mini.nvim](https://github.com/echasnovski/mini.nvim)
- [lazygit.nvim](https://github.com/kdheepak/lazygit.nvim)
- [lazydocker](https://github.com/jesseduffield/lazydocker)
