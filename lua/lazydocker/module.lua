local View = require("lazydocker.view")
local M = {}

local LazydockerView = View()

function M.toggle()
	LazydockerView:toggle()
end

return M
