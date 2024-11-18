--- *lazydocker.nvim* lazydocker management within Neovim
--- *LazyDocker*
---
--- MIT License Copyright (c) 2024 Ádran Carnavale

local LazyDocker = {}
local H = {}

--- Module Setup
---
---@param config table|nil Module config table. See |LazyDocker.config|.
---
---@usage >lua
---   require('lazydocker').setup() -- Use default config.
---   -- OR
---   require('lazydocker').config({}) -- Provide your own config as a table.
--- <
---@return nil
function LazyDocker.setup(config)
    _G.LazyDocker = LazyDocker

    config = H.setup_config(config)
    H.apply_config(config)
end

--- Module config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
LazyDocker.config = {
    -- Width of the floating panel
    width = math.floor(0.618 * vim.o.columns),
    -- Height of the floating panel
    height = math.floor(0.618 * vim.o.lines),
}
--minidoc_afterlines_end

--
-- Utilities
--

H.default_config = vim.deepcopy(LazyDocker.config)

H.setup_config = function(config)
    vim.validate({ config = { config, "table", true } })
    config = vim.tbl_deep_extend("force", vim.deepcopy(H.default_config), config or {})
    vim.validate({ delay = { config.width, "number" }, height = { config.height, "number" } })
    return config
end

H.apply_config = function(config)
    LazyDocker.config = config
end

return LazyDocker
