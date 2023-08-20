local M = {}

M.is_lazydocker_available = function()
	return vim.fn.executable("lazydocker") == 1
end

M.is_docker_available = function()
	return vim.fn.executable("docker") == 1
end

M.is_nui_available = function()
	local has_nui, _ = pcall(require, "nui")
	return has_nui
end

return M
