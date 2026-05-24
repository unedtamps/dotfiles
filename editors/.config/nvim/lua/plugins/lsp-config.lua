return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"ray-x/lsp_signature.nvim",
		event = "InsertEnter",
		opts = {
			-- cfg options
		},
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"svelte",
					"ast_grep",
					"bashls",
					"templ",
					"remark_ls",
					"rust_analyzer",
					"jdtls",
					"prismals",
					"pyright",
					"intelephense",
					"lua_ls",
					"jsonls",
					"gopls",
					"clangd",
					"html",
					"cssls",
					"biome",
					"asm_lsp",
					"awk_ls",
					"docker_compose_language_service",
					"dockerls",
					"htmx",
					"hydra_lsp",
					"kotlin_language_server",
					"marksman",
					"sqlls",
					"stimulus_ls",
					"tailwindcss",
					"ts_ls",
					"yamlls",
					"csharp_ls",
					"terraformls",
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local on_attach = function(client, bufnr)
				if client.server_capabilities.inlayHintProvider then
					vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
				end
			end

			vim.lsp.config("*", {
				on_attach = on_attach,
				capabilities = capabilities,
			})
			vim.lsp.config("gopls", {
				settings = {
					gopls = {
						hints = {
							assignVariableTypes = true,
							compositeLiteralFields = true,
							parameterNames = true,
						},

						buildFlags = { "-tags=wireinject" },
					},
				},
			})
			vim.lsp.config("pyright", {})
			vim.lsp.config("ts_ls", {})
			vim.lsp.config("rust_analyzer", {
				settings = {
					["rust-analyzer"] = {
						inlayHints = { enable = true },
					},
				},
			})

			vim.api.nvim_command("highlight DiagnosticVirtualTextError guifg=#fa1616 guibg=NONE")
			vim.api.nvim_command("highlight DiagnosticVirtualTextWarn guifg=#f1fa8c guibg=NONE")
			vim.api.nvim_command("highlight DiagnosticVirtualTextInfo guifg=#8be9fd guibg=NONE")
			vim.api.nvim_command("highlight DiagnosticVirtualTextHint guifg=#50fa7b guibg=NONE")

			vim.diagnostic.config({
				virtual_text = {
					spacing = 4,
					prefix = "●",
				},
				signs = true,
				underline = false,
				update_in_insert = false,
				severity_sort = true,
				float = {
					border = "rounded",
					source = "if_many",
				},
			})

			-- vim.api.nvim_create_autocmd("CursorHold", {
			-- 	callback = function()
			-- 		vim.diagnostic.open_float(nil, { focus = false })
			-- 	end,
			-- })

			local on_references = vim.lsp.handlers["textDocument/references"]
			vim.lsp.handlers["textDocument/references"] = vim.lsp.with(on_references, {
				loclist = true,
			})
			vim.diagnostic.update_in_insert = false

			vim.keymap.set("n", "<leader>ds", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "<leader>da", vim.diagnostic.open_float, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
			vim.keymap.set("n", "<leader>dt", vim.lsp.buf.type_definition, {})
		end,
	},
	{
		"nvim-lua/lsp-status.nvim",
	},
	{
		"ricardoramirezr/blade-nav.nvim",
		dependencies = {
			"hrsh7th/nvim-cmp",
		},
		ft = { "blade", "php" },
	},
}
