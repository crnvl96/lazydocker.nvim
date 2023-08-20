local class = require("lazydocker.common.class")
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event
local config = require("lazydocker.config")

local View = class({})

function View:init()
	self.popup = Popup(config.options.popup_window)
	self.is_open = false
end

function View:open()
	self.popup:mount()
	vim.api.nvim_buf_set_lines(self.popup, 0, 1, false, { "Hello, LazyDocker" })
end

return View
