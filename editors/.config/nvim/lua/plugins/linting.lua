return {
	{
		"mfussenegger/nvim-lint",
		event = {
			"BufReadPre",
			"BufNewFile",
		},
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
				golang = { "golangci-lint" },
				php = { "phpcs" },
				c = { "cpplint" },
				cpp = { "cpplint" },
				python = { "pylint", "ruff" },
				java = { "checkstyle" },
				-- rust = { "snyk" },
				sh = { "shellcheck" },
				make = { "checkmake" },
				kotlin = { "ktlint" },
			}
			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})
			vim.keymap.set("n", "<leader>li", function()
				lint.try_lint()
			end, { desc = "Trigger linting for current file" })

			-- Point pylint at the project's virtualenv so it can import installed packages
			local function venv_site_paths()
				local root = vim.fs.root(0, { ".venv", "venv", ".git", "pyproject.toml", "setup.py" })
				local py = root
						and vim.fn.executable(root .. "/.venv/bin/python") == 1
						and (root .. "/.venv/bin/python")
					or nil
				py = py
						or (vim.env.VIRTUAL_ENV
							and vim.fn.executable(vim.env.VIRTUAL_ENV .. "/bin/python") == 1
							and (vim.env.VIRTUAL_ENV .. "/bin/python"))
					or nil
				if not py then
					return nil
				end
				local out = vim.fn.system(py .. " -c 'import sysconfig as s; print(s.get_paths()[\"purelib\"]); print(s.get_paths()[\"platlib\"])'")
				local paths = {}
				for line in out:gmatch("[^\n]+") do
					line = line:gsub("%s+$", "")
					if line ~= "" then
						table.insert(paths, line)
					end
				end
				return paths
			end

			lint.linters.pylint.args = {
				"-f",
				"json",
				"--from-stdin",
				function()
					return vim.api.nvim_buf_get_name(0)
				end,
				"--init-hook",
				function()
					local paths = venv_site_paths()
					if not paths then
						return "import sys"
					end
					local stmts = {}
					for _, p in ipairs(paths) do
						table.insert(stmts, "sys.path.insert(0, " .. vim.fn.string(p) .. ")")
					end
					return "import sys; " .. table.concat(stmts, "; ")
				end,
			}
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		config = function()
			local mason_tool = require("mason-tool-installer")
			mason_tool.setup({
				ensure_installed = {
					"prettier",
					"stylua",
					"isort",
					"black",
					"eslint_d",
					"phpcs",
					"golangci-lint",
					"cpplint",
					"checkmake",
					"ktlint",
					"shellcheck",
					"checkstyle",
					"eslint_d",
"pylint",
				"golangci-lint",
				"ruff",
				},
			})
		end,
	},
}
