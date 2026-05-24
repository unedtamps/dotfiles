return {
	"kevinhwang91/nvim-ufo",
	dependencies = { "kevinhwang91/promise-async" },
	config = function()
		vim.o.foldcolumn = "1"
		vim.o.foldlevel = 99
		vim.o.foldlevelstart = 99
		vim.o.foldenable = true

		-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
		vim.keymap.set("n", "zj", require("ufo").openAllFolds)
		vim.keymap.set("n", "zk", require("ufo").closeFoldsWith)
		-- za for toggle fold

		-- vim.keymap.set("n", "zh", function()
		-- 	local winid = require("ufo").peekFoldedLinesUnderCursor()
		-- 	if not winid then
		-- 		-- choose one of coc.nvim and nvim lsp
		-- 		vim.fn.CocActionAsync("definitionHover") -- coc.nvim
		-- 		vim.lsp.buf.hover()
		-- 	end
		-- end)
		require("ufo").setup({
			provider_selector = function(bufnr, filetype, buftype)
				return { "treesitter", "indent" }
			end,
		})
	end,
}
