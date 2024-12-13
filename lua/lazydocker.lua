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
    -- Create a global table to allow easy manipulation by the user
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
H.error = function(msg)
    error("(lazydocker.nvim): " .. msg)
end

H.notify = function(msg, level)
    vim.notify("(lazydocker.nvim): " .. msg, vim.log.levels[level])
end

H.default_config = vim.deepcopy(LazyDocker.config)

H.setup_config = function(config)
    local ok

    -- Validate that, if a config table has been provided, it is valid
    ok = pcall(vim.validate, "config", config, "table", true)

    if not ok then
        H.error("a valid config table must be provided as argument of `setup`. Please check `:h LazyDocker.config`")
    end

    -- Create a copy of the default config here to guarantee imutability
    local default_config = vim.deepcopy(H.default_config)

    -- If no config has been provided, we use an empty table here
    config = config or {}

    -- Extend the default config with the provided values
    -- In case of conflict, the provided configuration opts take precedence
    config = vim.tbl_deep_extend("force", default_config, config)

    -- Validate the final config
    local width = config.width
    local height = config.height

    ok = pcall(vim.validate, "width", width, function(a)
        return type(a) == "number" and a > 0 and math.floor(a) == a
    end)

    if not ok then
        H.error("`config.width` must be a positive integer number. Please check `:h LazyDocker.config`")
    end

    ok = pcall(vim.validate, "height", height, function(a)
        return type(a) == "number" and a > 0 and math.floor(a) == a
    end)

    if not ok then
        H.error("`config.height` must be a positive integer number. Please check `:h LazyDocker.config`")
    end

    return config
end

H.apply_config = function(config)
    -- Attach the plugin configutarion to the global table
    LazyDocker.config = config
end

return LazyDocker
