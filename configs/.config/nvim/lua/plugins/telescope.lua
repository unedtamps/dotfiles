return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local builtin = require("telescope.builtin")

			-- git_status with per-file devicons. Telescope's default entry only
			-- renders the two status glyph columns, so add the icon ourselves.
			local function git_status_with_icons()
				local opts = {}
				local make_entry = require("telescope.make_entry")
				local entry_display = require("telescope.pickers.entry_display")
				local devicons = require("nvim-web-devicons")

				local git_abbrev = {
					A = { icon = "+", hl = "TelescopeResultsDiffAdd" },
					U = { icon = "‡", hl = "TelescopeResultsDiffAdd" },
					M = { icon = "~", hl = "TelescopeResultsDiffChange" },
					C = { icon = ">", hl = "TelescopeResultsDiffChange" },
					R = { icon = "➡", hl = "TelescopeResultsDiffChange" },
					D = { icon = "-", hl = "TelescopeResultsDiffDelete" },
					["?"] = { icon = "?", hl = "TelescopeResultsDiffUntracked" },
				}

				local displayer = entry_display.create({
					separator = "",
					items = { { width = 2 }, { width = 2 }, { width = 3 }, { remaining = true } },
				})

				local base = make_entry.gen_from_git_status(opts)
				opts.entry_maker = function(line)
					local entry = base(line)
					if not entry then
						return nil
					end
					entry.display = function(e)
						local staged = git_abbrev[string.sub(e.status, 1, 1)] or {}
						local unstaged = git_abbrev[string.sub(e.status, -1)] or {}
						local icon, icon_hl = devicons.get_icon(e.value, nil, { default = true })
						return displayer({
							{ staged.icon or " ", staged.hl },
							{ unstaged.icon or " ", unstaged.hl },
							{ icon or " ", icon_hl },
							{ e.value },
						})
					end
					return entry
				end

				builtin.git_status(opts)
			end

			vim.keymap.set("n", "<leader>ff", function()
				builtin.find_files({ hidden = true })
			end, {})
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
			vim.keymap.set("n", "<leader>pg", builtin.git_files, {})
			vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
			vim.keymap.set("n", "<leader>ps", builtin.grep_string, {})
			vim.keymap.set("n", "<leader>fd", function()
				if vim.fn.finddir(".git", ".;") == "" then
					vim.notify("Not a git repository", vim.log.levels.WARN)
					return
				end
				git_status_with_icons()
			end, { desc = "[F]ind [D]irty files (git status)" })
		end,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
				-- config - config coba di default
				defaults = {
					file_ignore_patterns = { "node_modules" },
					initial_mode = "insert",
					vimgrep_arguments = {
						"rg",
						"--color=never",
						"--no-heading",
						"--with-filename",
						"--line-number",
						"--column",
						"--smart-case",
						"--ignore-case",
					},
				},
			})
			require("telescope").load_extension("ui-select")
		end,
	},
	{
		"nvim-telescope/telescope-file-browser.nvim",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
		config = function()
			local telescope = require("telescope")
			telescope.load_extension("file_browser")

			vim.keymap.set("n", "<leader>pd", telescope.extensions.file_browser.file_browser, {})
		end,
	},
}
