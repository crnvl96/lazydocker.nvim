-- main module file
local config = require("chatgpt.config")
local module = require("lazydocker.module")

local M = {}

M.setup = function(options)
	config.setup(options)
end

--
-- public methods for the plugin
--

M.toggle = function()
	module.toggle()
end

return M
