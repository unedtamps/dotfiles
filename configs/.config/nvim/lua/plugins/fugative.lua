return {
	{
		"tpope/vim-fugitive",
		-- vim.keymap.set("n", "<leader>gg", "<cmd>vertical rightbelow G<CR>"),
		-- vim.keymap.set("n", "<leader>gb", "<cmd>vertical rightbelow G blame<CR>"),
		vim.keymap.set("n", "<leader>gl", "<cmd>vertical rightbelow G log<CR>"),
	},

	{
		"NeogitOrg/neogit",
		lazy = true,
		dependencies = {
			"nvim-lua/plenary.nvim", -- required
			"sindrets/diffview.nvim", -- optional - Diff integration

			-- Only one of these is needed.
			"nvim-telescope/telescope.nvim", -- optional
			"ibhagwan/fzf-lua", -- optional
			"nvim-mini/mini.pick", -- optional
			"folke/snacks.nvim", -- optional
		},
		cmd = "Neogit",
		keys = {
			{ "<leader>gg", "<cmd>Neogit<cr>", desc = "Show Neogit UI" },
		},
	},
}
