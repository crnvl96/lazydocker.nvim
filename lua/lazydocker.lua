--- *lazydocker.nvim*
---
--- MIT License Copyright (c) 2024 Ádran Carnavale

local Lazydocker = {}
local H = {}

--- Module config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
Lazydocker.config = {
	-- Width of the floating panel
	width = nil,
	-- Height of the floating panel
	height = nil,
}
--minidoc_afterlines_end

--- Module Setup
---
---@param config table|nil Module config table. See |Lazydocker.default_config|.
---
---@usage >lua
---   require('lazydocker').setup() -- Use default config.
---   -- OR
---   require('lazydocker').config({}) -- Provide your own config as a table.
--- <
---@return nil
function Lazydocker.setup(config)
	_G.Lazydocker = Lazydocker
	H.validate_config(config)

	-- Set the plugin config as the merge result.
	Lazydocker.config = config
end

-- Utilities
--

function H.validate_config(config)
	vim.validate({
		config = { config, "table", true },
	})

	config = vim.tbl_deep_extend("force", vim.deepcopy(H.get_default_config()), config or {})

	vim.validate({
		width = { config.width, "number", true },
		height = { config.height, "number", true },
	})
end

function H.get_max_allowed_size()
	local has_tabline = vim.o.showtabline == 2 or (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1)
	local has_statusline = vim.o.laststatus > 0

	return {
		height = vim.o.lines - vim.o.cmdheight - (has_tabline and 1 or 0) - (has_statusline and 1 or 0),
		width = vim.o.columns,
	}
end

function H.get_default_config()
	local max_size = H.get_max_allowed_size()
	local max_width, max_height = max_size.width, max_size.height

	return {
		width = math.floor(0.618 * max_width),
		height = math.floor(0.618 * max_height),
	}
end

return Lazydocker
