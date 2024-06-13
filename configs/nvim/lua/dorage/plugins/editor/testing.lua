local utils = require("dorage.utils")

return {
	{ "nvim-neotest/neotest-jest" },
	{ "nvim-neotest/neotest-plenary" },
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			"nvim-neotest/neotest-plenary",
			"nvim-neotest/neotest-jest",
		},
		config = function()
			require("neotest").setup({
				adapters = {
					require("neotest-plenary"),
					-- require("neotest-vim-test")({
					-- 	ignore_file_types = { "python", "vim", "lua" },
					-- }),
					-- TODO: Error in monorepo. in finding jest dependencies
					require("neotest-jest")({
						jestCommand = "pnpm test --",
						jestConfigFile = function()
							local jsPath = utils.path.findDirectoryByFilename(vim.fn.expand("%"), "jest.config.js")
							if jsPath ~= nil then
								return jsPath .. "jest.config.js"
							end
							local tsPath = utils.path.findDirectoryByFilename(vim.fn.expand("%"), "jest.config.ts")
							print("tsPath is", tsPath)
							if tsPath ~= nil then
								return tsPath .. "jest.config.ts"
							end
							return vim.fn.getcwd()
						end,
						env = { CI = true },
						cwd = function()
							local rootPath = utils.path.findDirectoryByFilename(vim.fn.expand("%"), "package.json")
							print("rootPath is", rootPath)
							if rootPath == nil then
								return vim.fn.getcwd()
							end
							return rootPath
						end,
					}),
				},
				status = { virtual_text = true },
				output = { open_on_run = true },
				-- TODO: add custom debugging strategy
			})

			local neotest_ns = vim.api.nvim_create_namespace("neotest")
			vim.diagnostic.config({
				virtual_text = {
					format = function(diagnostic)
						-- Replace newline and tab characters with space for more compact diagnostics
						local message =
							diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
						return message
					end,
				},
			}, neotest_ns)
		end,
		keys = {
			{
				"<leader>tt",
				function()
					require("neotest").run.run(vim.fn.expand("%"))
				end,
				desc = "Test:Run File",
			},
			{
				"<leader>tT",
				function()
					require("neotest").run.run(vim.uv.cwd())
				end,
				desc = "Test:Run All Test Files",
			},
			{
				"<leader>tr",
				function()
					require("neotest").run.run()
				end,
				desc = "Test:Run Nearest",
			},
			{
				"<leader>td",
				function()
					require("neotest").run.run({ strategy = "dap" })
				end,
				desc = "Test:Debug Nearest",
			},
			{
				"<leader>tl",
				function()
					require("neotest").run.run_last()
				end,
				desc = "Test:Run Last",
			},
			{
				"<leader>tl",
				function()
					require("neotest").run.run_last({ strategy = "dap" })
				end,
				desc = "Test:Debug Last",
			},
			{
				"<leader>tw",
				function()
					require("neotest").run.run({ jestCommand = "jest --watch" })
				end,
				desc = "Test:Run Watch",
			},
			{
				"<leader>ts",
				function()
					require("neotest").summary.toggle()
				end,
				desc = "Test:Toggle Summary",
			},
			{
				"<leader>to",
				function()
					require("neotest").output.open({ enter = true, auto_close = true })
				end,
				desc = "Test:Show Output",
			},
			{
				"<leader>tO",
				function()
					require("neotest").output_panel.toggle()
				end,
				desc = "Test:Toggle Output Panel",
			},
			{
				"<leader>tS",
				function()
					require("neotest").run.stop()
				end,
				desc = "Test:Stop",
			},
		},
	},
}
