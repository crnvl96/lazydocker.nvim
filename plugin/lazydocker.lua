vim.api.nvim_create_user_command("LazyDocker", function()
	if vim.fn.has("nvim-0.9") == 0 then
		print("lazydocker.nvim needs Neovim >= 0.9")
		return
	end

	return require("lazydocker").toggle()
end, {})
