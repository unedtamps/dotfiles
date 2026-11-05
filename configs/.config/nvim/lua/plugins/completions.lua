return {
	{
		{
			"hrsh7th/cmp-nvim-lsp",
		},
		{
			"L3MON4D3/LuaSnip",
			version = "v2.*",
			build = "make install_jsregexp",
		},
		{

			"hrsh7th/nvim-cmp",
			version = false,
			event = "InsertEnter",
			dependencies = {
				"hrsh7th/cmp-buffer",
				"hrsh7th/cmp-path",
				"davidsierradz/cmp-conventionalcommits",
			},
			opts = function()
				require("luasnip.loaders.from_vscode").load()

				local luasnip = require("luasnip")
				luasnip.filetype_extend("ruby", { "rails" })
				luasnip.filetype_extend("typescript", { "javascript" })
				luasnip.filetype_extend("typescriptreact", { "javascript" })
				luasnip.filetype_extend("templ", { "html" })
				luasnip.filetype_extend("blade", { "html" })

				vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
				local cmp = require("cmp")
				local defaults = require("cmp.config.default")()

				return {
					completion = {
						completeopt = "menu,menuone,noinsert",
					},
					snippet = {
						expand = function(args)
							require("luasnip").lsp_expand(args.body)
						end,
					},
					window = {
						completion = cmp.config.window.bordered(),
						documentation = cmp.config.window.bordered(),
					},

					mapping = cmp.mapping.preset.insert({
						["J"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
						["K"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
						["<C-b>"] = cmp.mapping.scroll_docs(-4),
						["<C-f>"] = cmp.mapping.scroll_docs(4),
						["<C-Space>"] = cmp.mapping.complete(),
						["<C-e>"] = cmp.mapping.abort(),
						["<CR>"] = cmp.mapping.confirm({ select = true }),
						["<S-CR>"] = cmp.mapping.confirm({
							behavior = cmp.ConfirmBehavior.Replace,
							select = true,
						}),
						["<C-CR>"] = function(fallback)
							cmp.abort()
							fallback()
						end,
					}),
					formatting = {
						format = function(entry, vim_item)
							vim_item.menu = ({
								nvim_lsp = "🔧 [LSP]",
								luasnip = "🔑 [LuaSnip]",
								path = "[Path]",
								buffer = "[Buffer]",
							})[entry.source.name]
							return vim_item
						end,
					},
					sources = cmp.config.sources({
						{ name = "nvim_lsp" },
						{ name = "luasnip" },
						{ name = "path" },
						{ name = "conventionalcommits" },
					}, {
						{ name = "buffer" },
					}),

					experimental = {
						ghost_text = {
							hl_group = "CmpGhostText",
						},
					},

					sorting = defaults.sorting,
				}
			end,
			config = function(_, opts)
				for _, source in ipairs(opts.sources) do
					source.group_index = source.group_index or 1
				end
				local cmp = require("cmp")
				cmp.setup(opts)
			end,
		},
	},
}
