local util = require("lazydocker.util")
local view = require("lazydocker.view")
local config = require("lazydocker.config")
local M = {}

function M.toggle()
	print("Init lazydocker")
	config.load()
	view.open()
	util.exec()
end

return M
