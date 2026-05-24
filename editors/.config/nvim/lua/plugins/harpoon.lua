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
	end,
	keys = function()
		local keys = {
			{
				"<leader>H",
				function()
					require("harpoon"):list():add()
				end,
				desc = "Harpoon File",
			},
			{
				"<leader>fa",
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
							phreviewer = conf.file_previewer({}),
							sorter = conf.generic_sorter({}),
						})
						:find()
				end,
				desc = "Open harpoon window",
			},
			{
				"<C-m>",
				function()
					require("harpoon"):list():next()
				end,
				desc = "Harpoon File",
			},
			{
				"<C-p>",
				function()
					require("harpoon"):list():prev()
				end,
				desc = "Harpoon File",
			},
			{
				"H",
				function()
					local harpoon = require("harpoon")
					harpoon.ui:toggle_quick_menu(harpoon:list())
				end,
				desc = "Harpoon Quick Menu",
			},
		}

		for i = 1, 9 do
			table.insert(keys, {
				"<leader>" .. i,
				function()
					require("harpoon"):list():select(i)
				end,
				desc = "Harpoon to File " .. i,
			})
		end
		return keys
	end,
}
