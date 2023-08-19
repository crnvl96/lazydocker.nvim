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
		vim.fn.filetype.add("lazydocker-float")
		self.active = true
	end

	self.docker_panel:on({ event.BufLeave, event.FocusLost }, function()
		print("leaving")
		self.active = false
	end)

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("close_lazydocker", { clear = true }),
		pattern = {
			"lazydocker-float",
		},
		callback = function(e)
			vim.bo[e.buf].buflisted = false
			vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = e.buf, silent = true })
		end,
	})
end

return View
