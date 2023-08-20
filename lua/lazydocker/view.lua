local class = require("lazydocker.common.class")
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event
local config = require("lazydocker.config")

local View = class({})

function View:init()
	self.popup = Popup(config.options.popup_window)
	self.is_open = false
end

function View:set_listeners()
	local function set_keymap(key)
		return self.popup:map("n", key, function()
			self.popup:off("BufLeave")
			self.popup:unmount()
		end, { silent = true, noremap = true })
	end

	self.popup:on(event.BufLeave, function()
		self.popup.unmount()
	end)

	set_keymap("<esc>")
	set_keymap("q")
end

function View:render()
	vim.api.nvim_buf_set_lines(self.popup, 0, 1, false, { "Hello, LazyDocker" })
end

function View:open()
	self.popup:mount()
	self.set_listeners(self)
	self:render()
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
