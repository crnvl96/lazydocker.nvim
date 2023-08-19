local M = {}

function M.defaults()
	local defaults = {
		-- TODO: Add config options here
		popup_window = {
			enter = true,
			focusable = true,
			border = {
				highlight = "FloatBorder",
				style = "rounded",
				text = {
					top = " Lazydocker ",
				},
			},
			position = "50%",
			size = {
				width = "80%",
				height = "80%",
			},
		},
	}
	return defaults
end

M.options = {}

M.namespace_id = vim.api.nvim_create_namespace("LazyDocker")

function M.setup(options)
	options = options or {}
	M.options = vim.tbl_deep_extend("force", {}, M.defaults(), options)
end

return M
