return {
	{
		"stevearc/conform.nvim",
		-- event = { "BufReadPre", "BufNewFile", "BufWritePre" },
		config = function()
			local conform = require("conform")
			conform.setup({
				formatters_by_ft = {
					javascript = { "prettierd", "prettier" },
					typescript = { "prettierd", "prettier" },
					typescriptreact = { "prettierd", "prettier" },
					json = { "prettier" },
					html = { "prettier" },
					go = { "gofumpt", "goimports", "golines" },
					lua = { "stylua" },
					c = { "clang-format" },
					cpp = { "clang-format" },
					php = { "phpcbf" },
					blade = { "blade-formatter" },
					python = { "isort", "black" },
					yaml = { "yamlfmt" },
					java = { "google-java-format" },
					sql = { "sqlfmt" },
					sh = { "shfmt" },
					asm = { "asmfmt" },
					kotlin = { "ktlint" },
				},

				format_on_save = {
					lsp_format = "fallback",
					timeout_ms = 500,
				},

				notify_on_error = true,
			})

			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*",
				callback = function(args)
					require("conform").format({ bufnr = args.buf })
				end,
			})

			vim.keymap.set({ "n", "v" }, "<c-I>", function()
				conform.format({
					lsp_fallback = true,
					asyc = false,
					timeout_ms = 10000,
				})
			end, { desc = "Format file on range (invisual mode)" })
		end,
	},
	{
		"rust-lang/rust.vim",
	},
}
