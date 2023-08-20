local class = require("lazydocker.common.class")
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event
local config = require("lazydocker.config")

local View = class({})

function View:init()
	self.is_open = false
end

function View:open()
	self.popup = Popup(config.options.popup_window)
	self.popup:mount()

	self.popup:on(event.BufLeave, function()
		self.popup.unmount()
	end)

	self.popup:map("n", "<esc", function()
		self.popup:off("BufLeave")
		self.popup:unmount()
	end, { silent = true, noremap = true })

	self.popup:map("n", "q", function()
		self.popup:off("BufLeave")
		self.popup:unmount()
	end, { silent = true, noremap = true })

	vim.api.nvim_buf_set_lines(self.popup, 0, 1, false, { "Hello, LazyDocker" })
end

function View:close()
	self.popup:off("BufLeave")
	self.popup:unmount()
end

function View:toggle()
	if self.is_open == false then
		self.is_open = true
		self:open()
	else
		self.is_open = false
		self:close()
	end
end

return View
