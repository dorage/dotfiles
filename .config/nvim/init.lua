vim.cmd([[ language en_US ]])

vim.cmd([[ :set syntax="on" ]])
vim.cmd([[ :set number ]])
vim.cmd([[ :set relativenumber ]])
vim.cmd([[ :set autoindent ]])
vim.cmd([[ :set tabstop=2 ]])
vim.cmd([[ :set shiftwidth=2 ]])
vim.cmd([[ :set smarttab ]])
vim.cmd([[ :set softtabstop=2 ]])
vim.cmd([[ :set mouse=a ]])

vim.cmd([[ nnoremap <leader>p "+p ]])
vim.cmd([[ vnoremap <leader>p "+p ]])
vim.cmd([[ nnoremap <leader>P "+P ]])
vim.cmd([[ vnoremap <leader>P "+P ]])
vim.cmd([[ nnoremap <leader>y "+y ]])
vim.cmd([[ vnoremap <leader>y "+y ]])
vim.cmd([[ nnoremap <leader>Y "+y$ ]])


require('dorage.lazy')
