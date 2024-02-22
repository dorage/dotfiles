:set number
:set relativenumber
:set autoindent
:set tabstop=4
:set shiftwidth=4
:set smarttab
:set softtabstop=4
:set mouse=a

call plug#begin('~/.config/nvim/plugins')

Plug 'https://github.com/vim-airline/vim-airline' "statusbar on commadline
Plug 'https://github.com/preservim/nerdtree' "file treeview browser
Plug 'https://github.com/tpope/vim-commentary' "easy commenting
Plug 'https://github.com/ap/vim-css-color' " CSS Color Preview
Plug 'https://github.com/sainnhe/sonokai' " Monokai variant
Plug 'https://github.com/neoclide/coc.nvim'  " Auto Completion
Plug 'https://github.com/ryanoasis/vim-devicons' " Developer Icons
Plug 'https://github.com/tc50cal/vim-terminal' " Vim Terminal
Plug 'https://github.com/preservim/tagbar' " Tagbar for code navigation
Plug 'https://github.com/terryma/vim-multiple-cursors' " CTRL + N for multiple cursors
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.5' } " file explorer
Plug 'norcalli/nvim-colorizer.lua' " color highlighter
Plug 'https://github.com/rest-nvim/rest.nvim' " http request client

call plug#end()

"theme settings"

syntax on

if has('termguicolors')
	set termguicolors
endif

let g:sonokai_style = 'maia'
let g:sonokai_better_performance = 1

colorscheme sonokai
let g:lightline = {'colorscheme': 'sonokai'}

"nerd tree settings"

nnoremap <C-b> :NERDTreeToggle<CR>

let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '~'

"tag bar settings"

nmap <F8> :TagbarToggle<CR>

:set completeopt-=preview " For No Previews

"telescope settings"
" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" Using Lua functions
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>

