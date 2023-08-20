local config = require("lazydocker.config")
local module = require("lazydocker.module")

local M = {}

M.setup = function(options)
	config.setup(options)
end

--
-- public methods for the plugin
--

M.toggle = function()
	return module.toggle()
end

return M
