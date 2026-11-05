return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	opts = {},
	keys = {
		{
			"<leader>mp",
			"<cmd>RenderMarkdown toggle<CR>",
			ft = "markdown",
			desc = "Toggle markdown rendering",
		},
	},
}
