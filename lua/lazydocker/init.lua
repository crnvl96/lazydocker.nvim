local util = require("lazydocker.util")
local view = require("lazydocker.view")
local M = {}

function M.toggle()
	print("Toggle lazydocker")
	view.open()
	util.exec()
end

return M
