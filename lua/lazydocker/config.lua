local M = {}

function M.defaults()
	local defaults = {
		-- TODO: Add config options here
		popup_window = {
			border = {
				highlight = "FloatBorder",
				style = "rounded",
				text = {
					top = " ChatGPT ",
				},
			},
			win_options = {
				wrap = true,
				linebreak = true,
				foldcolumn = "1",
				winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
			},
			buf_options = {
				filetype = "markdown",
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
