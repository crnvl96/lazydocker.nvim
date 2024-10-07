-- Definitions.
--
-- Lazydocker module definition.
local Lazydocker = {}

-- Config module definition
local Config = {}

-- Generate default config
Config.default_config = {
	width = 0.5,
	height = 0.5,
}

-- Setup function definition
---@param config table|nil Module config table. See |Lazydocker.config|.
---@usage >lua
---   require('lazydocker').setup() -- Use default config.
---   -- OR
---   require('lazydocker').config({}) -- Provide your own config as a table.
--- <
function Lazydocker.setup(config)
	_G.Lazydocker = Lazydocker

	vim.validate({
		config = {
			config, -- arg value.
			"table", -- type value.
			true, -- true means that the arg is optional (can be nil).
		},
	})

	-- Create a new instance of our default config table before extending it.
	config = vim.tbl_deep_extend("force", vim.deepcopy(Config.default_config), config or {})

	Lazydocker.config = config
end

---@alias __lazydocker_return boolean Whether the operation has completed successfully.

-- Toggle Docker floating window
---@return __lazydocker_return
function Lazydocker.toggle()
	print(Lazydocker.config.width)
	print(Lazydocker.config.height)

	print("Toggle!!!")

	return true
end

return Lazydocker
