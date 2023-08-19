local View = require("lazydocker.view")
local M = {}

local LazydockerView = View()

function M.toggle()
	print("Init lazydocker")
	LazydockerView:open()
end

return M
