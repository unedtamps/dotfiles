--return {
--	{
--		"zbirenbaum/copilot.lua",
--		cmd = "Copilot",
--		event = "InsertEnter",
--		config = function()
--			require("copilot").setup({
--				panel = {
--					enabled = true,
--					auto_refresh = true,
--					keymap = {
--						jump_prev = "[[",
--						jump_next = "]]",
--						accept = "<CR>",
--						refresh = "gr",
--						open = "<M-CR>",
--					},
--					layout = {
--						position = "left", -- | top | left | right
--						ratio = 0.4,
--					},
--				},
--				suggestion = {
--					enabled = true,
--					auto_trigger = true,
--					debounce = 25,
--					keymap = {
--						accept = "<tab>",
--						accept_word = false,
--						accept_line = false,
--						next = "<down>",
--						prev = "<up>",
--						dismiss = "<left>",
--					},
--				},
--				filetypes = {
--					yaml = true,
--					dockerfile = true,
--					markdown = true,
--					help = false,
--					gitcommit = true,
--					gitrebase = false,
--					hgcommit = false,
--					svn = false,
--					cvs = false,
--					--["."] = false,
--				},
--				copilot_node_command = "node", -- Node.js version must be > 18.x
--				server_opts_overrides = {},
--			})
--		end,
--	},
--}
return {
	"Exafunction/codeium.nvim",
	lazy = false,
	config = function()
		require("codeium").setup({
			enable_cmp_source = false,
			virtual_text = {
				enabled = true,
				manual = false,
				filetypes = {},
				default_filetype_enabled = true,
				idle_delay = 75,
				virtual_text_priority = 65535,
				map_keys = true,
				accept_fallback = nil,
				key_bindings = {
					accept = "<Tab>",
					accept_word = false,
					accept_line = false,
					clear = false,
					next = "<M-]>",
					prev = "<M-[>",
				},
			},

			enabled_chat = false,
		})
	end,
}
