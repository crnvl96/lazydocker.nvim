local M = {}

M.is_lazydocker_available = function()
	return vim.fn.executable("lazydocker") == 1
end

M.is_docker_available = function()
	return vim.fn.executable("docker") == 1
end

return M
