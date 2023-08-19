local class = require("lazydocker.common.class")
local Popup = require("nui.popup")
local config = require("lazydocker.config")

local View = class({})

function View:init()
	self.active = false
end

function View:toggle()
	self.docker_panel = Popup(config.options.popup_window)
	self.docker_panel:mount()

	vim.api.nvim_buf_set_lines(self.docker_panel.bufnr, 0, 1, false, { "LazyDocker will be rendered here" })
end

return View
