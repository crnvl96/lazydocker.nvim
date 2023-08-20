local class = require("lazydocker.common.class")
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event
local config = require("lazydocker.config")

local View = class({})

function View:init()
	self.is_open = false
	self.docker_panel = nil
end

function View:set_listeners()
	local function set_close_keymaps(key)
		self.docker_panel:map("n", key, function()
			self.docker_panel:off("BufLeave")
			self.docker_panel:unmount()
			self.is_open = false
		end, { noremap = true })
	end

	self.docker_panel:on(event.BufLeave, function()
		self.docker_panel:unmount()
		self.is_open = false
	end)

	set_close_keymaps("<esc>")
	set_close_keymaps("q")
end

function View:toggle()
	if self.is_open == false then
		self.docker_panel = Popup(config.options.popup_window)
		self.docker_panel:mount()

		vim.api.nvim_buf_set_lines(self.docker_panel.bufnr, 0, 1, false, { "LazyDocker will be rendered here" })

		self:set_listeners()

		self.is_open = true
	else
		self.docker_panel:off("BufLeave")
		self.docker_panel:unmount()
		self.is_open = false
	end
end

return View
