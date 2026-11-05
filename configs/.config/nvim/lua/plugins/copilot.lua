-- Codeium disabled 2026-11-03 (commented out, not removed)
--[[
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
--]]
return {}
