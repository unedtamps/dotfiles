return {
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {}, -- this is equalent to setup({}) function
	},
	{
		"tpope/vim-commentary",
	},
	{
		"norcalli/nvim-colorizer.lua",
		config = function()
			require("colorizer").setup()
		end,
	},
	{
		"christoomey/vim-tmux-navigator",
		lazy = false,
		vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>"),
		vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<CR>"),
		vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<CR>"),
		vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<CR>"),
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
	},
}
