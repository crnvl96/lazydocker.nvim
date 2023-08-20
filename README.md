# lazydocker.nvim

# Installation

```lua
-- Packer
use({
  "crnvl96/lazydocker.nvim",
    config = function()
      require("lazydocker").setup()
    end,
    requires = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
    }
})

-- Lazy
{
  "crnvl96/lazydocker.nvim",
    event = "VeryLazy",
    opts = {},
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
    }
}
```
