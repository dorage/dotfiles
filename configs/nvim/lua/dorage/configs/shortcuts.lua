vim.keymap.set({'i', 'x', 'n', 's'}, '<leader>w', '<cmd>w<cr><esc>', {desc = "Save file"})

vim.keymap.set({'n', 's'}, '<leader>y', '"+y', {desc = "Copy to clipboard"})
vim.keymap.set({'n', 's'}, '<leader>p', '"+p', {desc = "Paste from clipboard"})

