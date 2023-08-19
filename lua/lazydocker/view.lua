local class = require("lazydocker.common.class")
local Popup = require("nui.popup")
local config = require("lazydocker.config")

local View = class({})

function View:init()
	self.active = true
end

function View:open()
	-- TODO: fill Popup() params here
	self.docker_panel = Popup(config.options.popup_window)

	self.stop = false
	self.should_stop = function()
		if self.stop then
			self.stop = false
			return true
		else
			return false
		end
	end
end

return View
