local dap = require("dap")
local dapvscode = require("dap-vscode-js")

local debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug/"

dapvscode.setup({
	-- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
	debugger_path = debugger_path, -- Path to vscode-js-debug installation.
	-- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
	adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" }, -- which adapters to register in nvim-dap
	-- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
	-- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
	-- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
})

for _, language in ipairs({ "typescript", "javascript", "javascriptreact", "typescriptreact" }) do
	dap.configurations[language] = {
		-- Reference
		-- https://github.com/mxsdev/nvim-dap-vscode-js?tab=readme-ov-file#user-content-fn-2-62526e2d932e479bbb5e3b34b5b27246
		-- https://github.com/anasrar/.dotfiles/blob/fdf4b88dfd2255b90f03c62dfc0f3f9458dc99a9/neovim/.config/nvim/lua/rin/DAP/languages/typescript.lua
		--
		-- -----------
		--
		-- debug jest
		{
			type = "pwa-node",
			request = "launch",
			name = "Jest: Current File",
			trace = true, -- include debugger info
			-- runtimeExecutable = "node",
			runtimeArgs = {
				"./node_modules/jest/bin/jest.js",
				"--runInBand",
				"--",
				"${file}",
			},
			rootPath = "${workspaceFolder}",
			cwd = "${workspaceFolder}",
			console = "integratedTerminal",
			internalConsoleOptions = "neverOpen",
		},
		-- debug Node
		{
			type = "pwa-node",
			request = "launch",
			name = "Node: Current File",
			cwd = vim.fn.getcwd(),
			runtimeExecutable = "ts-node",
			args = { "${file}" },
			sourceMaps = true,
			protocol = "inspector",
			skipFiles = { "<node_internals>/**", "node_modules/**" },
			resolveSourceMapLocations = {
				"${workspaceFolder}/**",
				"!**/node_modules/**",
			},
		},
		{
			type = "pwa-node",
			request = "attach",
			name = "Node:Attach",
			processId = require("dap.utils").pick_process,
			runtimeArgs = { "-r", "ts-node/register" },
			cwd = "${workspaceFolder}",
			sourceMaps = true,
			protocol = "inspector",
			skipFiles = { "<node_internals>/**", "node_modules/**" },
			resolveSourceMapLocations = {
				"${workspaceFolder}/**",
				"!**/node_modules/**",
			},
		},
	}
end
