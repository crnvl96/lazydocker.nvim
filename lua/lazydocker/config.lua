local M = {}

function M.defaults()
	local defaults = {
		popup_window = {
			enter = true,
			focusable = false,
			zindex = 40,
			position = "50%",
			relative = "win",
			size = {
				width = "90%",
				height = "90%",
			},
			buf_options = {
				modifiable = false,
				readonly = false,
			},
			win_options = {
				winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
				winblend = 0,
			},
			border = {
				highlight = "FloatBorder",
				style = "rounded",
				text = {
					top = " Lazydocker ",
				},
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
