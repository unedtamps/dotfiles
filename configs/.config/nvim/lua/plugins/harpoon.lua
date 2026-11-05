return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local harpoon = require("harpoon")
		harpoon:setup({
			menu = {
				width = vim.api.nvim_win_get_width(0) - 4,
			},
			settings = {
				save_on_toggle = true,
			},
		})

		-- Reorder entries from inside the quick menu with J/K.
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "harpoon",
			callback = function()
				local opts = { buffer = true, silent = true }
				vim.keymap.set("n", "J", ":m '>+1<CR>", opts)
				vim.keymap.set("n", "K", ":m '<-2<CR>", opts)
			end,
		})
	end,
	keys = function()
		local keys = {
			{
				"<leader>a",
				function()
					require("harpoon"):list():add()
				end,
				desc = "Harpoon add file",
			},
			{
				"H",
				function()
					local harpoon = require("harpoon")
					harpoon.ui:toggle_quick_menu(harpoon:list())
				end,
				desc = "Harpoon quick menu",
			},
			{
				"<C-n>",
				function()
					require("harpoon"):list():next()
				end,
				desc = "Harpoon next file",
			},
			{
				"<C-p>",
				function()
					require("harpoon"):list():prev()
				end,
				desc = "Harpoon previous file",
			},
			{
				"<leader>fh",
				function()
					local harpoon = require("harpoon")
					local conf = require("telescope.config").values
					local file_paths = {}
					for _, item in ipairs(harpoon:list().items) do
						table.insert(file_paths, item.value)
					end

					require("telescope.pickers")
						.new({}, {
							prompt_title = "Harpoon",
							finder = require("telescope.finders").new_table({
								results = file_paths,
							}),
							previewer = conf.file_previewer({}),
							sorter = conf.generic_sorter({}),
						})
						:find()
				end,
				desc = "Harpoon picker",
			},
		}

		for i = 1, 9 do
			table.insert(keys, {
				"<leader>" .. i,
				function()
					require("harpoon"):list():select(i)
				end,
				desc = "Harpoon file " .. i,
			})
		end
		return keys
	end,
}
