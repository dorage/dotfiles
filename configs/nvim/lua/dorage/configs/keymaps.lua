-- LSP actions
vim.keymap.set(
	{ "n" },
	"gl",
	"<cmd>lua vim.diagnostic.open_float()<cr><esc>",
	{ desc = "Show diagnostic in a floating window" }
)
vim.keymap.set(
	{ "n" },
	"[d",
	"<cmd>lua vim.diagnostic.goto_prev()<cr><esc>",
	{ desc = "Move to the previous diagnostic in the current buffer" }
)
vim.keymap.set(
	{ "n" },
	"]d",
	"<cmd>lua vim.diagnostic.goto_next()<cr><esc>",
	{ desc = "Move to the next diagnostic in the current buffer" }
)

-- blazing fast save
vim.keymap.set({ "i", "x", "n", "s" }, "<leader>w", "<cmd>w<cr><esc>", { desc = "Save file" })
vim.keymap.set({ "n", "s" }, "<leader>n", "<cmd>noh<cr><esc>", { desc = ":noh" })

-- yank to clipboard
vim.keymap.set({ "n", "s" }, "<leader>y", '"+y', { desc = "Copy to clipboard" })
-- paste from clipboard
vim.keymap.set({ "n", "s" }, "<leader>p", '"+p', { desc = "Paste from clipboard" })
vim.keymap.set({ "n", "s" }, "<leader>P", '"+P', { desc = "Paste from clipboard" })

-- better substitute
-- references: https://www.youtube.com/watch?v=k_PBlhH-DKk&t=13s
vim.keymap.set({ "n" }, "<leader>sa", ":%s/<C-R><C-W>/<C-R>0/g<CR>:noh<CR>", { desc = "Substitute all" })
vim.keymap.set({ "n" }, "<leader>ss", ":s/<C-R><C-W>/<C-R>0/g<CR>:noh<CR>", { desc = "Substitute current line" })
vim.keymap.set({ "v" }, "<leader>sa", '"vy:%s/<C-R>v/<C-R>0/g<CR>:noh<CR>', { desc = "Substitute selected in file" })
vim.keymap.set(
	{ "v" },
	"<leader>ss",
	'"vy:s/<C-R>v/<C-R>0/g<CR>:noh<CR>',
	{ desc = "Substitute selected in current line" }
)
