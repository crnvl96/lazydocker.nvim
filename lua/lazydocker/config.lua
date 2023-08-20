local M = {}

function M.defaults()
	local defaults = {
		-- TODO: Add config options here
		popup_window = {
			enter = true,
			focusable = true,
			zindex = 50,
			buf_options = {
				modifiable = false,
				readonly = true,
			},
			win_options = {
				winblend = 10,
				winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
			},
			border = {
				highlight = "FloatBorder",
				style = "rounded",
				text = {
					top = " Lazydocker ",
				},
			},
			position = "50%",
			size = {
				width = 90,
				height = 90,
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
