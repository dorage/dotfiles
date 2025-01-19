return {
	-- split & join
	{
		"echasnovski/mini.splitjoin",
		version = false,
		config = function()
			local miniSplitjoin = require("mini.splitjoin")
			miniSplitjoin.setup({})
		end,
	},
	-- jump
	{
		"echasnovski/mini.jump",
		version = false,
		config = function()
			local miniJump = require("mini.jump")
			miniJump.setup({})
		end,
	},
	-- pick
	{
		"echasnovski/mini.pick",
		version = false,
		config = function()
			local miniPick = require("mini.pick")
			local builtin = miniPick.builtin

			miniPick.setup({})

			vim.keymap.set("n", "<leader>ff", builtin.files, { desc = "find files" })
			vim.keymap.set("n", "<leader>fg", builtin.grep_live, { desc = "live grep" })
			vim.keymap.set("n", "<leader>fw", builtin.buffers, { desc = "buffers" })
			-- diagnostics
			-- keymaps
			-- color
		end,
	},
	-- filetree
	-- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-files.md
	{
		"echasnovski/mini.files",
		version = false,
		config = function()
			local miniFiles = require("mini.files")
			miniFiles.setup({
				windows = {
					preview = true,
					width_preview = 50,
				},
			})

			vim.keymap.set("n", "<leader>fb", function()
				miniFiles.open()
			end, { desc = "files in root directory" })
			vim.keymap.set("n", "<leader>fv", function()
				miniFiles.open(vim.api.nvim_buf_get_name(0))
			end, { desc = "files in current file directory" })
		end,
	},
	-- indent
	{
		"echasnovski/mini.indentscope",
		version = false,
		config = function()
			local miniIndentscope = require("mini.indentscope")
			miniIndentscope.setup({})
		end,
	},
	-- notify
	{
		"echasnovski/mini.notify",
		version = false,
		config = function()
			local miniNotify = require("mini.notify")
			miniNotify.setup({})
		end,
	},
	-- comment
	{
		"echasnovski/mini.comment",
		dependencies = { "JoosepAlviste/nvim-ts-context-commentstring", opts = { enable_autocmd = true } },
		version = "*",
		opts = {
			mappings = {
				-- Toggle comment (like `gcip` - comment inner paragraph) for both
				-- Normal and Visual modes
				comment = "gc",
				-- Toggle comment on current line
				comment_line = "gcc",
				-- Toggle comment on visual selection
				comment_visual = "gc",
				-- Define 'comment' textobject (like `dgc` - delete whole comment block)
				-- Works also in Visual mode if mapping differs from `comment_visual`
				textobject = "gc",
			},
			options = {
				custom_commentstring = function()
					return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
				end,
			},
		},
	},
	-- surrounding
	{
		"echasnovski/mini.surround",
		version = "*",
		opts = {
			mappings = {
				add = "sa", -- Add surrounding in Normal and Visual modes
				delete = "sd", -- Delete surrounding
				find = "sf", -- Find surrounding (to the right)
				find_left = "sF", -- Find surrounding (to the left)
				highlight = "sh", -- Highlight surrounding
				replace = "sr", -- Replace surrounding
				update_n_lines = "sn", -- Update `n_lines`

				suffix_last = "l", -- Suffix to search with "prev" method
				suffix_next = "n", -- Suffix to search with "next" method
			},
		},
	},
}