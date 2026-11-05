return {
	-- Jupyter notebook REPL support using iron.nvim
	{
		"Vigemus/iron.nvim",
		config = function()
			local iron = require("iron.core")
			local view = require("iron.view")
			local common = require("iron.fts.common")

			iron.setup({
				config = {
					-- Whether a repl should be discarded or not
					scratch_repl = true,
					-- Your repl definitions come here
					repl_definition = {
						sh = {
							command = { "zsh" },
						},
						python = {
							-- Use ipython for better Jupyter-like experience
							-- or { "python3" } for standard python REPL
							command = { "ipython", "--no-autoindent" },
							format = common.bracketed_paste_python,
							block_dividers = { "# %%", "#%%" },
						},
						-- Map markdown to python REPL (for jupytext .ipynb -> .md files)
						markdown = {
							command = { "ipython", "--no-autoindent" },
							format = common.bracketed_paste_python,
							block_dividers = { "# %%", "#%%", "```python", "```" },
						},
						julia = {
							command = { "julia" },
						},
						r = {
							command = { "R" },
						},
					},
					-- How the repl window will be displayed
					repl_open_cmd = view.split.rightbelow("25%"),
					-- Send selections to the DAP repl if an nvim-dap session is running
					dap_integration = true,
				},
				-- Keymaps - matching the original molten keybindings where possible
				keymaps = {
					toggle_repl = "<leader>ri", -- toggles the repl open and closed (like MoltenInit)
					restart_repl = "<leader>rR", -- restarts the repl
					send_motion = "<leader>mr", -- send motion (like MoltenEvaluateOperator)
					visual_send = "<leader>r", -- send visual selection
					send_file = "<leader>rf", -- send entire file
					send_line = "<leader>rr", -- send current line (like MoltenEvaluateLine)
					send_paragraph = "<leader>rp", -- send paragraph
					send_until_cursor = "<leader>ru", -- send from start to cursor
					send_code_block = "<leader>rc", -- send code block (like MoltenReevaluateCell)
					send_code_block_and_move = "<leader>rn", -- send code block and move to next
					interrupt = "<leader>r<space>", -- interrupt repl
					exit = "<leader>rq", -- exit repl
					clear = "<leader>rd", -- clear repl (like MoltenDelete)
					cr = "<leader>r<cr>", -- send carriage return
				},
				highlight = {
					italic = true,
				},
				ignore_blank_lines = true,
			})

			-- Helper function to save REPL buffer content to file
			local function save_repl_output()
				local buffers = vim.api.nvim_list_bufs()
				local repl_buf = nil

				-- Find the REPL buffer (iron REPLs have filetype matching the language)
				for _, buf in ipairs(buffers) do
					local bufname = vim.api.nvim_buf_get_name(buf)
					local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
					local filetype = vim.api.nvim_buf_get_option(buf, "filetype")

					-- Iron REPL buffers are typically named "iron://..." or have special buftype
					if buftype == "terminal" or bufname:match("^iron://") then
						repl_buf = buf
						break
					end
				end

				if not repl_buf then
					vim.notify("No active REPL found!", vim.log.levels.ERROR)
					return
				end

				-- Get all lines from the REPL buffer
				local lines = vim.api.nvim_buf_get_lines(repl_buf, 0, -1, false)
				local content = table.concat(lines, "\n")

				-- Generate filename with timestamp
				local timestamp = os.date("%Y%m%d_%H%M%S")
				local ft = vim.api.nvim_buf_get_option(repl_buf, "filetype") or "repl"
				local default_name = string.format("repl_output_%s_%s.txt", ft, timestamp)

				-- Prompt for filename
				vim.ui.input({
					prompt = "Save REPL output to: ",
					default = default_name,
				}, function(filename)
					if not filename or filename == "" then
						return
					end

					-- Expand path and write file
					local filepath = vim.fn.expand(filename)
					local file = io.open(filepath, "w")
					if file then
						file:write(content)
						file:close()
						vim.notify("REPL output saved to: " .. filepath, vim.log.levels.INFO)
					else
						vim.notify("Failed to save file: " .. filepath, vim.log.levels.ERROR)
					end
				end)
			end

			-- Helper function to save REPL output with custom name in specific directory
			local function save_repl_session()
				local buffers = vim.api.nvim_list_bufs()
				local repl_buf = nil

				for _, buf in ipairs(buffers) do
					local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
					if buftype == "terminal" then
						local bufname = vim.api.nvim_buf_get_name(buf)
						if bufname:match("iron") or vim.api.nvim_buf_get_option(buf, "filetype") == "python" then
							repl_buf = buf
							break
						end
					end
				end

				if not repl_buf then
					vim.notify("No active REPL found! Start one with <leader>ri", vim.log.levels.ERROR)
					return
				end

				-- Get current file's directory or use cwd
				local current_file = vim.api.nvim_buf_get_name(0)
				local base_dir = current_file ~= "" and vim.fn.fnamemodify(current_file, ":h") or vim.fn.getcwd()

				-- Get lines
				local lines = vim.api.nvim_buf_get_lines(repl_buf, 0, -1, false)

				-- Clean up prompt markers for cleaner output
				local cleaned_lines = {}
				for _, line in ipairs(lines) do
					-- Remove common IPython/Python prompt markers for cleaner output
					local cleaned = line:gsub("^In %[%d+%]: ", ""):gsub("^Out%[%d+%]: ", "")
					table.insert(cleaned_lines, cleaned)
				end

				local content = table.concat(cleaned_lines, "\n")

				-- Generate default name based on current file
				local base_name = current_file ~= "" and vim.fn.fnamemodify(current_file, ":t:r") or "session"
				local default_name = base_dir .. "/" .. base_name .. "_output.txt"

				vim.ui.input({
					prompt = "Save REPL session to: ",
					default = default_name,
				}, function(filename)
					if not filename or filename == "" then
						return
					end

					local filepath = vim.fn.expand(filename)
					local file = io.open(filepath, "w")
					if file then
						file:write("-- REPL Session Output --\n")
						file:write("-- Source: " .. (current_file or "unknown") .. "\n")
						file:write("-- Saved: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
						file:write("--\n\n")
						file:write(content)
						file:close()
						vim.notify("Session saved to: " .. filepath, vim.log.levels.INFO)
					else
						vim.notify("Failed to save: " .. filepath, vim.log.levels.ERROR)
					end
				end)
			end

			-- Create user commands
			vim.api.nvim_create_user_command("IronSaveOutput", save_repl_output, {
				desc = "Save REPL output to file",
			})

			vim.api.nvim_create_user_command("IronSaveSession", save_repl_session, {
				desc = "Save REPL session with metadata",
			})

			-- Keymaps for saving
			vim.keymap.set("n", "<leader>rS", save_repl_session, { desc = "Iron: Save REPL session to file" })
			vim.keymap.set("n", "<leader>rO", save_repl_output, { desc = "Iron: Quick save REPL output" })

			-- Auto-save on REPL close (optional - uncomment if desired)
			-- vim.api.nvim_create_autocmd("BufDelete", {
			-- 	pattern = "*",
			-- 	callback = function(args)
			-- 		local buftype = vim.api.nvim_buf_get_option(args.buf, "buftype")
			-- 		if buftype == "terminal" then
			-- 			-- Auto-save logic here
			-- 		end
			-- 	end,
			-- })
		end,
		keys = {
			-- Additional keymaps that don't fit in iron's keymap config
			{ "<leader>rF", "<cmd>IronFocus<cr>", desc = "Iron: Focus REPL" },
			{ "<leader>rh", "<cmd>IronHide<cr>", desc = "Iron: Hide REPL" },
			{ "<leader>rS", desc = "Iron: Save REPL session" },
			{ "<leader>rO", desc = "Iron: Quick save output" },
		},
	},
	-- Edit Jupyter notebooks (.ipynb) as markdown or python files
	{
		"GCBallesteros/jupytext.nvim",
		opts = {
			style = "markdown",
			output_extension = "md",
			force_ft = "markdown",
		},
		lazy = false,
	},
	-- Optional: image support for displaying plots
	-- Only loads when not in tmux or when tmux allow-passthrough is enabled
	{
		"3rd/image.nvim",
		cond = function()
			-- Outside tmux, assume the terminal supports Kitty graphics.
			if not vim.env.TMUX then
				return true
			end

			-- Inside tmux, image.nvim needs allow-passthrough enabled.
			local result = vim.fn.system({ "tmux", "show", "-Apv", "allow-passthrough" })
			if vim.v.shell_error ~= 0 then
				return false
			end

			local value = result:gsub("%s+", "")
			return value == "on" or value == "all"
		end,
		opts = {
			backend = "kitty", -- or "ueberzug" for other terminals
			integrations = {
				markdown = {
					enabled = true,
					clear_in_insert_mode = false,
					download_remote_images = true,
					only_render_image_at_cursor = false,
					filetypes = { "markdown", "vimwiki" },
				},
			},
			max_width = nil,
			max_height = nil,
			max_width_window_percentage = nil,
			max_height_window_percentage = 50,
			kitty_method = "normal",
		},
	},
}
