local class = require("lazydocker.common.class")
local Popup = require("nui.popup")
local config = require("lazydocker.config")
local utils = require("lazydocker.utils")

local View = class({})

function View:init()
	self.is_open = false
	self.docker_panel = nil
end

function View:set_listeners()
	self.docker_panel:map("n", "q", function()
		self:close("disable_autocmd")
	end, { noremap = true })

	self.docker_panel:on("BufLeave,InsertLeave", function()
		self:close()
	end)
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
		self.docker_panel:off("BufLeave,InsertLeave")
	end

	self.docker_panel:unmount()
	self.is_open = false
	vim.cmd("silent! :checktime")
end

function View:render()
	vim.fn.termopen("lazydocker", {
		on_exit = function()
			self:close()
		end,
	})
	vim.cmd("startinsert")
end

function View:toggle()
	if self.is_open == false then
		self:open()
	else
		self:close("disable_autocmd")
	end
end

return View
