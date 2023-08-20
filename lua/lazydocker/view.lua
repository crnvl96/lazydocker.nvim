local class = require("lazydocker.common.class")
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event
local config = require("lazydocker.config")
local utils = require("lazydocker.utils")

local View = class({})

function View:init()
	self.is_open = false
	self.docker_panel = nil
end

function View:set_listeners()
	local function set_close_keymaps(key)
		self.docker_panel:map("n", key, function()
			self:close("disable_autocmd")
		end, { noremap = true })
	end

	self.docker_panel:on(event.BufLeave, function()
		self:close()
	end)

	set_close_keymaps("<esc>")
	set_close_keymaps("q")
end

function View:check_requirements()
	if utils.is_lazydocker_available() ~= true then
		print("Missing requirement: lazydocker not installed")
		return false
	end

	if utils.is_docker_available() ~= true then
		print("Missing requirement: docker not installed")
		return false
	end

	return true
end

function View:open()
	local all_requirements_ok = self:check_requirements()
	if all_requirements_ok ~= true then
		return
	end

	self.docker_panel = Popup(config.options.popup_window)
	self.docker_panel:mount()
	self:render()
	self:set_listeners()
	self.is_open = true
end

function View:close(opts)
	if opts == "disable_autocmd" then
		self.docker_panel:off("BufLeave")
	end

	self.docker_panel:unmount()
	self.is_open = false
end

function View:render()
	vim.fn.termopen("lazydocker")
end

function View:toggle()
	if self.is_open == false then
		self:open()
	else
		self:close("disable_autocmd")
	end
end

return View
