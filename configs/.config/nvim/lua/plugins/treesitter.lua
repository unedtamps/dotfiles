return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local treesitter = require("nvim-treesitter")

		treesitter.setup()
		treesitter.install({ "typescript", "tsx" })

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "typescript", "typescriptreact" },
			callback = function()
				pcall(vim.treesitter.start)
			end,
		})
	end,
}
