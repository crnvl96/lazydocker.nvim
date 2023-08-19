local M = {}

M.is_lazydocker_available = function()
	return vim.fn.executable("lazydocker") == 1
end

return M
