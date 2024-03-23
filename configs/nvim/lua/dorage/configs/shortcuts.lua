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
vim.keymap.set("n", "<leader>ss", ":%s/<C-R><C-W>/<C-R>0/g<CR>", { desc = "Substitute" })
