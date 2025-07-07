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
vim.lsp.enable({
	"jdtls",
	"bashls",
	-- "eslint",
	-- "denols",
	"pyright",
	"rust_analyzer",
	"lua_ls",
	-- "ts_ls",
	"astro",
	"html",
	"jedi_language_server",
	-- "biome",
	"cssls",
	"tailwindcss",
	"nil_ls", -- nix
	"taplo",
	"vuels",
	"yamlls",
	"marksman",
	"sqlls",
	"perlnavigator",
	"autotools_ls",
})

vim.diagnostic.config({
	virtual_lines = false,
	virtual_text = { current_line = false },
})

require("dorage.lazy")
require("dorage.configs")

vim.keymap.set("n", "K", function()
	vim.lsp.buf.hover({ border = "single", max_height = 25, max_width = 120 })
end, { silent = true })
