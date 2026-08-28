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
					-- "svelte",
					-- "ast_grep",
					-- "bashls",
					-- "templ",
					-- "remark_ls",
					-- "rust_analyzer",
					"jdtls",
					-- "prismals",
					-- "pyright",
					-- "intelephense",
					-- "lua_ls",
					-- "jsonls",
					-- "gopls",
					-- "clangd",
					-- "html",
					-- "cssls",
					-- "biome",
					-- "asm_lsp",
					-- "awk_ls",
					-- "docker_compose_language_service",
					-- "dockerls",
					-- "htmx",
					-- "hydra_lsp",
					-- "kotlin_language_server",
					-- "marksman",
					-- "sqlls",
					-- "stimulus_ls",
					-- "tailwindcss",
					-- "ts_ls",
					-- "yamlls",
					-- "csharp_ls",
					-- "terraformls",
					-- "helm_ls",
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local mason_package_path = vim.fn.stdpath("data") .. "/mason/packages"
			local on_attach = function(client, bufnr)
				if client.server_capabilities.inlayHintProvider then
					vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
				end
			end

			vim.lsp.set_log_level("ERROR")
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
			vim.lsp.config("jdtls", {
				cmd = {
					mason_package_path .. "/jdtls/jdtls",
					"--jvm-arg=-javaagent:" .. mason_package_path .. "/jdtls/lombok.jar",
				},
				filetypes = { "java" },
				root_markers = { "pom.xml", ".classpath", ".project" },
				settings = {
					java = {
						configuration = {
							updateBuildConfiguration = "automatic",
						},
						eclipse = { downloadSources = true },
						maven = { downloadSources = true },
						implementationsCodeLens = { enabled = true },
						referencesCodeLens = { enabled = true },
						autobuild = { enabled = true },
						completion = {
							favoriteStaticMembers = {},
							guessMethodArguments = true,
							importOrder = {
								"com",
								"io",
								"jakarta",
								"java",
								"javax",
								"lombok",
								"org",
								"",
							},
						},
						saveActions = {
							organizeImports = true,
						},
					},
				},
				init_options = {
					extendedClientCapabilities = {
						classFileContentsSupport = true,
					},
				},
			})
			-- Resolve the project's virtualenv (or the activated one) so pyright uses the right interpreter.
			local function find_venv_python(root)
				local candidates = {}
				if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= "" then
					table.insert(candidates, vim.env.VIRTUAL_ENV .. "/bin/python")
				end
				if root then
					table.insert(candidates, root .. "/.venv/bin/python")
					table.insert(candidates, root .. "/venv/bin/python")
					table.insert(candidates, root .. "/env/bin/python")
				end
				for _, p in ipairs(candidates) do
					if vim.fn.executable(p) == 1 then
						return p
					end
				end
			end

			vim.lsp.config("pyright", {
				settings = {
					python = {
						analysis = {
							autoSearchPaths = true,
						},
					},
				},
			})

			-- Point pyright at the project's virtualenv before it starts, so installed
			-- packages are recognized without a stale-import analysis pass.
			vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
				pattern = { "*.py" },
				callback = function()
					local root = vim.fs.root(0, { ".venv", "venv", ".git", "pyproject.toml", "setup.py" })
					local py = find_venv_python(root)
					if py then
						vim.lsp.config("pyright", {
							settings = {
								python = {
									pythonPath = py,
									analysis = { autoSearchPaths = true },
								},
							},
						})
					end
				end,
			})
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
			vim.lsp.config("helm_ls", {
				settings = {
					["helm-ls"] = {
						yamlls = {
							enabled = true,
							enabledForFilesGlob = "*.{yaml,yml}",
							config = {
								schemas = {
									kubernetes = "templates/**",
								},
								completion = true,
								hover = true,
							},
						},
					},
				},
			})

			vim.lsp.config("html", {
				filetypes = { "html", "blade", "php" },
			})

			vim.keymap.set("n", "<leader>ds", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "<leader>da", vim.diagnostic.open_float, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
			vim.keymap.set("n", "<leader>dt", vim.lsp.buf.type_definition, {})
			vim.keymap.set("n", "<leader>jd", function()
				vim.lsp.buf.code_action({
					context = {
						only = { "source.generateJavadoc" },
						diagnostics = {},
					},
					apply = true,
				})
			end, { desc = "Generate Javadoc" })

			-- Restart csharp_ls in place. The built-in `:lsp restart` stops the client but
			-- fails to start a new one, so do a manual stop + start + re-attach instead.
			local function restart_csharp_ls()
				local client = vim.lsp.get_clients({ name = "csharp_ls" })[1]
				if not client then
					return
				end
				local attached = vim.tbl_keys(client.attached_buffers)
				local config = client.config
				client:stop(true)
				vim.schedule(function()
					local new_id = vim.lsp.start(config, { attach = false })
					if new_id and #attached > 0 then
						for _, bufnr in ipairs(attached) do
							vim.lsp.buf_attach_client(bufnr, new_id)
						end
					end
				end)
			end

			-- Auto-restart csharp_ls when project/dependency files change (e.g. after `dotnet add package`)
			local cs_restart_timer
			vim.api.nvim_create_autocmd("BufWritePost", {
				pattern = {
					"*.csproj",
					"*.sln",
					"*.slnx",
					"Directory.Packages.props",
					"Directory.Build.props",
					"Directory.Build.targets",
					"packages.lock.json",
				},
				callback = function()
					if not vim.lsp.get_clients({ name = "csharp_ls" })[1] then
						return
					end
					if cs_restart_timer then
						cs_restart_timer:stop()
					end
					cs_restart_timer = vim.uv.new_timer()
					cs_restart_timer:start(2000, 0, function()
						vim.schedule(function()
							cs_restart_timer:close()
							restart_csharp_ls()
						end)
					end)
				end,
			})
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
