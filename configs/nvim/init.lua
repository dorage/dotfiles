-- vim.cmd([[ language en_US ]])

vim.cmd([[ :set syntax=on ]])
vim.cmd([[ :set number ]])
vim.cmd([[ :set relativenumber ]])
vim.cmd([[ :set autoindent ]])
vim.cmd([[ :set tabstop=2 ]])
vim.cmd([[ :set shiftwidth=2 ]])
vim.cmd([[ :set smarttab ]])
vim.cmd([[ :set softtabstop=2 ]])
vim.cmd([[ :set mouse=a ]])
vim.cmd([[ :set encoding=utf-8 ]])
vim.cmd([[ :set fileencodings=utf-8,cp949 ]])
vim.cmd([[ :set termguicolors ]])
vim.cmd([[ :set nofoldenable ]])
vim.cmd([[ :set ignorecase smartcase ]])

vim.opt.grepprg = "rg --vimgrep --no-heading --smart-case"
vim.opt.grepformat = "%f:%l:%c:%m"

vim.lsp.config("*", {
	root_markers = { ".git" },
})

vim.diagnostic.config({
	virtual_lines = false,
	virtual_text = { current_line = false },
})

require("dorage.lazy")
require("dorage.configs")
