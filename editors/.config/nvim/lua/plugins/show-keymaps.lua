return {
	{
		"nvim-telescope/telescope.nvim",
		init = function()
			-- Create a user command :ShowKeymaps
			vim.api.nvim_create_user_command("ShowKeymaps", function()
				require("telescope.builtin").keymaps({ modes = { "n", "i", "v", "x", "t" } })
			end, { desc = "Show all keymaps" })
		end,
		keys = {
			-- Add a keybinding for easy access
			{ "<leader>fk", "<cmd>ShowKeymaps<cr>", desc = "[F]ind [K]eymaps" },
		},
	},
}
