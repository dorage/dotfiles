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
Plug('hrsh7th/cmp-buffer')
Plug('hrsh7th/cmp-path')
Plug('hrsh7th/cmp-cmdline')
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
Plug('https://github.com/andweeb/presence.nvim') -- discord presence
Plug('https://github.com/nvim-treesitter/nvim-treesitter', {['do'] = 'TSUpdate'}) -- nvim treesitter
Plug('https://github.com/mattn/emmet-vim') -- emmet nvim
Plug('https://github.com/gen740/SmoothCursor.nvim') -- cursor animation
Plug('https://github.com/itchyny/lightline.vim') -- lightline
Plug('https://github.com/folke/tokyonight.nvim') -- theme
Plug('https://github.com/williamboman/mason.nvim') -- mason, LSP manager
Plug('https://github.com/williamboman/mason-lspconfig.nvim') -- mason-lspconfig
Plug('https://github.com/MunifTanjim/nui.nvim') -- dbee deps
Plug('https://github.com/kndndrj/nvim-dbee', {
	['do'] = function ()
		require('dbee').install()
	end
}) -- db client
Plug('https://github.com/romgrk/barbar.nvim') -- tabline plugin
Plug('https://github.com/Exafunction/codeium.nvim') -- alternative copilot
Plug('https://github.com/onsails/lspkind.nvim') -- vscode style completion
Plug('https://github.com/jakewvincent/mkdnflow.nvim') -- markdown editor
Plug('https://github.com/preservim/vim-indent-guides') -- indent guide
Plug('https://github.com/ray-x/aurora') -- color scheme
Plug('https://github.com/bluz71/vim-moonfly-colors') -- color scheme
Plug('https://github.com/navarasu/onedark.nvim') -- color scheme
Plug('https://github.com/catppuccin/nvim', {['as']= 'catppuccin'}) -- catppuccin

vim.call('plug#end')

-- [default keymap]

-- esc -> noh
vim.keymap.set('n', '<esc>', function()
	if vim.api.nvim_get_vvar('hlsearch') == 1 then
			return ":nohl<CR><esc>"
	end

	return "<esc>"
end, { silent = true, noremap = true})

-- theme setup

vim.cmd('syntax on')
vim.g.termguicolors = true
vim.cmd [[colorscheme moonfly]]
vim.cmd [[let g:lightline = {'colorscheme': 'moonfly'}]]
vim.call('background#enable')
vim.cmd [[highlight LineNr guifg=#FFFFFF]]
vim.cmd [[hi LineNrAbove guifg=#16FF00]]
vim.cmd [[hi LineNrBelow guifg=#16FF00]]
vim.g.moonflyCursorColor = true
vim.g.moonflyItalics = true
vim.g.moonflyNormalFloat = true
vim.g.moonflyTerminalColors = true
vim.g.moonflyTransparent = true
local custom_highlight = vim.api.nvim_create_augroup("CustomHighlight", {})
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "moonfly",
  callback = function()
    vim.api.nvim_set_hl(0, "Function", { fg = "#74b2ff", bold = true })
  end,
  group = custom_highlight,
})
local winhighlight = {
  winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel",
}

-- require('onedark').setup({
-- 	style = 'dark',
-- 	transparent = true,
-- })
-- require('onedark').load()

-- require('tokyonight').setup({
-- 	style = {
-- 		comments = {
-- 		}
-- 	}
-- })

-- lsp-zero setup

local lsp_zero = require('lsp-zero')
lsp_zero.on_attach(function(client, bufnr)
	lsp_zero.default_keymaps({buffer = bufnr})
end)
-- lsp_zero.setup_servers({'tsserver', 'rust_analyzer'})

-- [ mason setup ]

require('mason').setup({
	ensure_installed = {
		'rust_analyzer',
		'lua_ls',
		'astro',
		'html',
		'jedi_language_server',
		'json',
		'biome',
		'cssls',
		'tailwindcss',
		'taplo',
		'vuels',
		'yamlls',
		'deno',
		'emmet_ls',
		'marksman',
		'sqls',
	},
	handlers = {
		lsp_zero.default_setup,
	},
})

require('mason-lspconfig').setup({
	handlers = {
		lsp_zero.default_setup,
	}
})

-- nvim-lspconfig setup

-- local lspconfig = require('lspconfig')
-- lspconfig.tsserver.setup({
-- 	single_file_support=false,
-- 	on_init = function(client)
-- 		-- disable formatting capabilities
-- 		client.server_capabilities.documentFormattingProvider = false
-- 		client.server_capabilities.documentFormattingRangeProvider = false
-- 	end,
-- })
-- lspconfig.rust_analyzer.setup({})

-- local lua_opts = lsp_zero.nvim_lua_ls()
-- lspconfig.lua_ls.setup(lua_opts)

-- [ treesitter setup ]

require('nvim-treesitter').setup({
	ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "javascript", "typescript", "tsx", "json", "python", "regex", "rust", "sql" },
	sync_install = true,
	auto_install = true,
})
require('nvim-treesitter.configs').setup({
	highlight = {
		enable = true,
	},
})

-- nvim-comp setup

local cmp = require('cmp')
local cmp_action = lsp_zero.cmp_action()
local lspkind = require('lspkind')

cmp.setup({
	source = {
		{name = 'path'},
		{name = 'nvim_lsp'},
		{name = 'buffer'},
		{name = 'codeium'},
		{name = 'mkdnflow'},
	},
	mapping = cmp.mapping.preset.insert({
		-- Enable "Super Tab"
		-- ['<Tab>'] = cmp_action.luasnip_supertab(),
		-- ['<S-Tab>'] = cmp_action.luasnip_shift_supertab(),

		-- ['<C-y>'] = cmp.mapping.confirm({select = false}),
		-- ['<C-e>'] = cmp.mapping.abort(),
		-- ['<Up>'] = cmp.mapping.select_prev_item({behavior = 'select'}),
		-- ['<Down>'] = cmp.mapping.select_next_item({behavior = 'select'}),
		-- ['<C-p>'] = cmp.mapping(function()
		-- 	if cmp.visible() then
		-- 		cmp.select_prev_item({behavior = 'insert'})
		-- 	else
		-- 		cmp.complete()
		-- 	end
		-- end),
		-- ['<C-n>'] = cmp.mapping(function()
		-- 	if cmp.visible() then
		-- 		cmp.select_next_item({behavior = 'insert'})
		-- 	else
		-- 		cmp.complete()
		-- 	end
		-- end),
		['<C-b>'] = cmp.mapping.scroll_docs(-4),
		['<C-f>'] = cmp.mapping.scroll_docs(4),
		['<C-Space>'] = cmp.mapping.complete(),
		['<C-e>'] = cmp.mapping.abort(),
		['<CR>'] = cmp.mapping.confirm({ select = true })
	}),
	completion = {
	},
	snippet = {
		expand = function(args)
			require('luasnip').lsp_expand(args.body)
		end
	},
	window = {
    completion = cmp.config.window.bordered(winhighlight),
    documentation = cmp.config.window.bordered(winhighlight),
	},
	formatting = {
		formatting = {
			format = lspkind.cmp_format({
				mode = 'symbol_text',
				maxwidth = 50,
				ellipsis_char = '...',
				show_labelDetails = true,
				symbol_map = {
					Codeium = "🤖",
				}
			}),
		}
	}
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
local telescope = require('telescope')
telescope.setup({
	pickers = {
		find_files = {
			hidden = true
		}
	},
})

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

-- [discord presence setup]

require("presence").setup({
	    -- General options
    auto_update         = true,                       -- Update activity based on autocmd events (if `false`, map or manually execute `:lua package.loaded.presence:update()`)
    neovim_image_text   = "The One True Text Editor", -- Text displayed when hovered over the Neovim image
    main_image          = "neovim",                   -- Main image display (either "neovim" or "file")
    log_level           = nil,                        -- Log messages at or above this level (one of the following: "debug", "info", "warn", "error")
    debounce_timeout    = 10,                         -- Number of seconds to debounce events (or calls to `:lua package.loaded.presence:update(<filename>, true)`)
    enable_line_number  = false,                      -- Displays the current line number instead of the current project
    blacklist           = {},                         -- A list of strings or Lua patterns that disable Rich Presence if the current file name, path, or workspace matches
    buttons             = false,                       -- Configure Rich Presence button(s), either a boolean to enable/disable, a static table (`{{ label = "<label>", url = "<url>" }, ...}`, or a function(buffer: string, repo_url: string|nil): table)
    file_assets         = {},                         -- Custom file asset definitions keyed by file names and extensions (see default config at `lua/presence/file_assets.lua` for reference)
    show_time           = true,                       -- Show the timer

    -- Rich Presence text options
    editing_text        = "Working!",               -- Format string rendered when an editable file is loaded in the buffer (either string or function(filename: string): string)
    file_explorer_text  = "Working!",              -- Format string rendered when browsing a file explorer (either string or function(file_explorer_name: string): string)
    git_commit_text     = "Working!",       -- Format string rendered when committing changes in git (either string or function(filename: string): string)
    plugin_manager_text = "Working!",         -- Format string rendered when managing plugins (either string or function(plugin_manager_name: string): string)
    reading_text        = "Working!",               -- Format string rendered when a read-only or unmodifiable file is loaded in the buffer (either string or function(filename: string): string)
    workspace_text      = "Private Workspace!",            -- Format string rendered when in a git repository (either string or function(project_name: string|nil, filename: string): string)
    line_number_text    = "Working!",        -- Format string rendered when `enable_line_number` is set to true (either string or function(line_number: number, line_count: number): string)
})

-- [ emmet-vim setup ]

-- [ smoothcursor setup ]

require('smoothcursor').setup({
	type = "default",           -- Cursor movement calculation method, choose "default", "exp" (exponential) or "matrix".

	cursor = "🍕",              -- Cursor shape (requires Nerd Font). Disabled in fancy modee.
	texthl = "SmoothCursor",   -- Highlight group. Default is { bg = nil, fg = "#FFD400" }. Disabled in fancy mode.
	linehl = nil,              -- Highlights the line under the cursor, similar to 'cursorline'. "CursorLine" is recommended. Disabled in fancy mode.

	autostart = true,           -- Automatically start SmoothCursor
	always_redraw = true,       -- Redraw the screen on each update
	flyin_effect = nil,         -- Choose "bottom" or "top" for flying effect
	speed = 25,                 -- Max speed is 100 to stick with your current position
	intervals = 35,             -- Update intervals in milliseconds
	priority = 10,              -- Set marker priority
	timeout = 3000,             -- Timeout for animations in milliseconds
	threshold = 10,              -- Animate only if cursor moves more than this many lines
	disable_float_win = false,  -- Disable in floating windows
	enabled_filetypes = nil,    -- Enable only for specific file types, e.g., { "lua", "vim" }
	disabled_filetypes = nil,   -- Disable for these file types, ignored if enabled_filetypes is set. e.g., { "TelescopePrompt", "NvimTree" }
	-- Show the position of the latest input mode positions. 
	-- A value of "enter" means the position will be updated when entering the mode.
	-- A value of "leave" means the position will be updated when leaving the mode.
	-- `nil` = disabled
	show_last_positions = nil,
})

-- [ dbee setup ]

require('dbee').setup()

-- [ barbar setup ]

local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Move to previous/next
map('n', '<A-,>', '<Cmd>BufferPrevious<CR>', opts)
map('n', '<A-.>', '<Cmd>BufferNext<CR>', opts)
-- Re-order to previous/next
map('n', '<A-<>', '<Cmd>BufferMovePrevious<CR>', opts)
map('n', '<A->>', '<Cmd>BufferMoveNext<CR>', opts)
-- Goto buffer in position...
map('n', '<A-1>', '<Cmd>BufferGoto 1<CR>', opts)
map('n', '<A-2>', '<Cmd>BufferGoto 2<CR>', opts)
map('n', '<A-3>', '<Cmd>BufferGoto 3<CR>', opts)
map('n', '<A-4>', '<Cmd>BufferGoto 4<CR>', opts)
map('n', '<A-5>', '<Cmd>BufferGoto 5<CR>', opts)
map('n', '<A-6>', '<Cmd>BufferGoto 6<CR>', opts)
map('n', '<A-7>', '<Cmd>BufferGoto 7<CR>', opts)
map('n', '<A-8>', '<Cmd>BufferGoto 8<CR>', opts)
map('n', '<A-9>', '<Cmd>BufferGoto 9<CR>', opts)
map('n', '<A-0>', '<Cmd>BufferLast<CR>', opts)
-- Pin/unpin buffer
map('n', '<A-p>', '<Cmd>BufferPin<CR>', opts)
-- Close buffer
map('n', '<A-c>', '<Cmd>BufferClose<CR>', opts)
-- Wipeout buffer
--                 :BufferWipeout
-- Close commands
--                 :BufferCloseAllButCurrent
--                 :BufferCloseAllButPinned
--                 :BufferCloseAllButCurrentOrPinned
--                 :BufferCloseBuffersLeft
--                 :BufferCloseBuffersRight
-- Magic buffer-picking mode
map('n', '<C-p>', '<Cmd>BufferPick<CR>', opts)
-- Sort automatically by...
map('n', '<Space>bb', '<Cmd>BufferOrderByBufferNumber<CR>', opts)
map('n', '<Space>bd', '<Cmd>BufferOrderByDirectory<CR>', opts)
map('n', '<Space>bl', '<Cmd>BufferOrderByLanguage<CR>', opts)
map('n', '<Space>bw', '<Cmd>BufferOrderByWindowNumber<CR>', opts)

-- Other:
-- :BarbarEnable - enables barbar (enabled by default)
-- :BarbarDisable - very bad command, should never be used

-- [ codeium setup ]

require('codeium').setup({})

-- [ mkdnflow setup ]
require('mkdnflow').setup({
    -- links = {
    --     transform_explicit = function(text)
    --         -- Make lowercase, remove spaces, and reverse the string
    --         return string.lower(text:gsub(' ', ''))
    --     end
    -- }
})

