-- ~/.config/nvim/after/ftdetect/terraform.lua
vim.filetype.add({
	extension = {
		tf = "terraform",
		tfvars = "terraform",
	},
})
