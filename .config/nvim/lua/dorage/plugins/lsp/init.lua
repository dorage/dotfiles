return {
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
		lazy = true,
    config = false,
    init = function()
      -- Disable automatic setup, we are doing it manually
      vim.g.lsp_zero_extend_cmp = 0
      vim.g.lsp_zero_extend_lspconfig = 0
    end,
  },
  {
    'williamboman/mason.nvim',
    lazy = false,
    config = true,
  },
	{ 
		"williamboman/mason-lspconfig.nvim"
	},
	-- Autocompletion
	{
		"L3MON4D3/LuaSnip",
		version = "v2.2",
		build = "make install_jsregexp"
	},
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
			{'VonHeikemen/lsp-zero.nvim'},
			{'hrsh7th/cmp-nvim-lsp'},
			{'hrsh7th/cmp-buffer'},
			{'hrsh7th/cmp-path'},
			{'hrsh7th/cmp-cmdline'},
      {'L3MON4D3/LuaSnip'}, -- snippet
			{'onsails/lspkind.nvim'}, -- vscode style compeletion
    },
    config = function()
			local cmp = require('cmp')
			local lsp_zero = require('lsp-zero')
			local cmp_action = lsp_zero.cmp_action()
			local lspkind = require('lspkind')
			local winhighlight = {
				winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel",
			}

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
					['<Tab>'] = cmp_action.luasnip_supertab(),
					['<S-Tab>'] = cmp_action.luasnip_shift_supertab(),

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
    end
  },

	-- LSP
  {
    'neovim/nvim-lspconfig',
    cmd = {'LspInfo', 'LspInstall', 'LspStart'},
    event = {'BufReadPre', 'BufNewFile'},
    dependencies = {
      {'hrsh7th/cmp-nvim-lsp'},
      {'williamboman/mason-lspconfig.nvim'},
    },
    config = function()
      -- This is where all the LSP shenanigans will live
      local lsp_zero = require('lsp-zero')
      lsp_zero.extend_lspconfig()

      --- if you want to know more about lsp-zero and mason.nvim
      --- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/integrate-with-mason-nvim.md
      lsp_zero.on_attach(function(client, bufnr)
        -- see :help lsp-zero-keybindings
        -- to learn the available actions
        lsp_zero.default_keymaps({buffer = bufnr})
      end)

      require('mason-lspconfig').setup({
				ensure_installed = {
					'rust_analyzer',
					'lua_ls',
					'astro',
					'html',
					'jedi_language_server',
					'biome',
					'cssls',
					'tailwindcss',
					'taplo',
					'vuels',
					'yamlls',
					'emmet_ls',
					'marksman',
					'sqlls',
				},
        handlers = {
          lsp_zero.default_setup,
          lua_ls = function()
            -- (Optional) Configure lua language server for neovim
            local lua_opts = lsp_zero.nvim_lua_ls()
            require('lspconfig').lua_ls.setup(lua_opts)
          end,
        }
      })
    end
  }
}
