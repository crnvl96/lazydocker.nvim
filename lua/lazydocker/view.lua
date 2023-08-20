local class = require("lazydocker.common.class")
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event
local config = require("lazydocker.config")

local View = class({})

function View:init()
	self.active = false
end

function View:toggle()
	if self.active == false then
		self.docker_panel = Popup(config.options.popup_window)
		self.docker_panel:mount()

		vim.api.nvim_buf_set_lines(self.docker_panel.bufnr, 0, 1, false, { "LazyDocker will be rendered here" })
		self.active = true
	end

	self.docker_panel:on(event.BufLeave, function()
		if self.active == true then
			print("Close because of BufLeave")
			self.docker_panel:unmount()
			self.active = false
		end
	end)

	self.docker_panel:map("n", "<esc>", function()
		if self.active == true then
			print("Close because of <ESC>")
			self.docker_panel:unmount()
			self.active = false
		end
	end, { noremap = true })

	self.docker_panel:map("n", "q", function()
		if self.active == true then
			print("Close because of Q")
			self.docker_panel:unmount()
			self.active = false
		end
	end, { noremap = true })
end

return View
