vim.api.nvim_create_user_command("LazyDocker", function()
	if vim.fn.has("nvim-0.5") == 0 then
		print("lazydocker.nvim needs Neovim >= 0.5")
		return
	end

	require("lazydocker").toggle()
end, {})
