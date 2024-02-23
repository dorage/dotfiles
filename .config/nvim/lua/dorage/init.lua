local vim = vim
local Plug = vim.fn['plug#']

vim.call('plug#begin')

Plug('https://github.com/tpope/vim-commentary') -- easy commenting
Plug('https://github.com/ap/vim-css-color') -- CSS Color Preview
Plug('https://github.com/sainnhe/sonokai') -- Monokai variant
Plug('norcalli/nvim-colorizer.lua') -- color highlighter
Plug('https://github.com/rest-nvim/rest.nvim') -- http request client
Plug('tribela/vim-transparent') -- set background opacity
Plug('https://github.com/VonHeikemen/lsp-zero.nvim') -- LSP zero configuration
Plug('https://github.com/hrsh7th/nvim-cmp') -- Completion engine
Plug('hrsh7th/cmp-nvim-lsp')
Plug('L3MON4D3/LuaSnip')
Plug('https://github.com/neovim/nvim-lspconfig') -- LSP configs
Plug('https://github.com/nvim-tree/nvim-tree.lua') -- file browser
Plug('nvim-lua/plenary.nvim')
Plug('nvim-telescope/telescope.nvim') -- fuzzy finder
Plug('https://github.com/jose-elias-alvarez/null-ls.nvim')
Plug('https://github.com/MunifTanjim/prettier.nvim') -- prettier formatter
Plug('https://github.com/voldikss/vim-floaterm') -- floating window
Plug('https://github.com/windwp/nvim-autopairs') -- autopair
Plug('https://github.com/folke/which-key.nvim') -- tooltips of keybindings
Plug('https://github.com/nvimdev/dashboard-nvim') -- custom banner
Plug('https://github.com/nvim-tree/nvim-web-devicons')
Plug('https://github.com/mg979/vim-visual-multi') -- mulit cursor

vim.call('plug#end')

-- theme setup

vim.cmd('syntax on')
vim.g.termguicolors = true
vim.g.colorscheme = 'maia'
vim.g.sonokai_better_performance = 1
vim.g.lightline = "{'colorscheme': 'sonokai'}"
vim.call('background#enable')

-- lsp-zero setup

local lsp_zero = require('lsp-zero')
lsp_zero.on_attach(function(client, bufnr)
	lsp_zero.default_keymaps({buffer = bufnr})
end)
lsp_zero.setup_servers({'tsserver', 'rust_analyzer'})

-- nvim-lspconfig setup

local lspconfig = require('lspconfig')
lspconfig.tsserver.setup({
	single_file_support=false,
	on_init = function(client)
		-- disable formatting capabilities
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentFormattingRangeProvider = false
	end,
})
lspconfig.rust_analyzer.setup({})

local lua_opts = lsp_zero.nvim_lua_ls()
lspconfig.lua_ls.setup(lua_opts)

-- nvim-comp setup

local cmp = require('cmp')
local cmp_action = lsp_zero.cmp_action()

cmp.setup({
	source = {
		{name = 'nvim_lsp'}
	},
	mapping = cmp.mapping.preset.insert({
		-- Enable "Super Tab"
		['<Tab>'] = cmp_action.luasnip_supertab(),
		['<S-Tab>'] = cmp_action.luasnip_shift_supertab(),


		['<C-y>'] = cmp.mapping.confirm({select = false}),
		['<C-e>'] = cmp.mapping.abort(),
		['<Up>'] = cmp.mapping.select_prev_item({behavior = 'select'}),
		['<Down>'] = cmp.mapping.select_next_item({behavior = 'select'}),
		['<C-p>'] = cmp.mapping(function()
			if cmp.visible() then
				cmp.select_prev_item({behavior = 'insert'})
			else
				cmp.complete()
			end
		end),
		['<C-n>'] = cmp.mapping(function()
			if cmp.visible() then
				cmp.select_next_item({behavior = 'insert'})
			else
				cmp.complete()
			end
		end),
	}),
	completion = {
	},
	snippet = {
		expand = function(args)
			require('luasnip').lsp_expand(args.body)
		end
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
})

-- nvim-tree setup
-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

local nvim_tree = require('nvim-tree')
nvim_tree.setup({
  sort = {
    sorter = "case_sensitive",
  },
  view = {
    width = 30,
		relativenumber = true
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    -- dotfiles = true,
  },
	actions = {
		change_dir = {
			enable = false,
			global = false,
			restrict_above_cwd = false,
		}
	}
})
vim.cmd([[
    :hi      NvimTreeExecFile    guifg=#ffa0a0
    :hi      NvimTreeSpecialFile guifg=#ff80ff gui=underline
    :hi      NvimTreeSymlink     guifg=Yellow  gui=italic
    :hi link NvimTreeImageFile   Title
]])

vim.keymap.set('n', '<C-b>', '<Cmd>:NvimTreeToggle<CR>', {silent = true})

-- telescope setup
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- prettier setup

local null_ls = require("null-ls")

local group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = false })
local event = "BufWritePre" -- or "BufWritePost"
local async = event == "BufWritePost"

null_ls.setup({
  on_attach = function(client, bufnr)
    if client.supports_method("textDocument/formatting") then
      vim.keymap.set("n", "<Leader>f", function()
        vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
      end, { buffer = bufnr, desc = "[lsp] format" })

      -- format on save
      vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })
      vim.api.nvim_create_autocmd(event, {
        buffer = bufnr,
        group = group,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr, async = async })
        end,
        desc = "[lsp] format on save",
      })
    end

    if client.supports_method("textDocument/rangeFormatting") then
      vim.keymap.set("x", "<Leader>f", function()
        vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
      end, { buffer = bufnr, desc = "[lsp] format" })
    end
  end,
})

local prettier = require("prettier")

prettier.setup({
  bin = 'prettier', -- or `'prettierd'` (v0.23.3+)
  filetypes = {
    "css",
    "graphql",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "less",
    "markdown",
    "scss",
    "typescript",
    "typescriptreact",
    "yaml",
  },
  cli_options = {
	config_precedence = "prefer-file",
  },
})

-- floaterm setup

vim.keymap.set('n', '<C-g>', '<Cmd>:FloatermNew lazygit<CR>')

-- nvim-autopairs setup
require('nvim-autopairs').setup({})

-- dashboard setup
local db = require('dashboard')
 db.setup({
    theme = 'hyper',
    config = {
      week_header = {
       enable = true,
      },
      shortcut = {
        { desc = '󰊳 Update', group = '@property', action = 'Lazy update', key = 'u' },
        {
          icon = ' ',
          icon_hl = '@variable',
          desc = 'Files',
          group = 'Label',
          action = 'Telescope find_files',
          key = 'f',
        },
        {
          desc = ' Apps',
          group = 'DiagnosticHint',
          action = 'Telescope app',
          key = 'a',
        },
        {
          desc = ' dotfiles',
          group = 'Number',
          action = 'Telescope dotfiles',
          key = 'd',
        },
      },
    },
  })
