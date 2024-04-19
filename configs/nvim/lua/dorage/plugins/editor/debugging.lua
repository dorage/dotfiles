return {
	{ "nvim-neotest/nvim-nio" },
	{ "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
	{
		"mfussenegger/nvim-dap",
		depends = { "rcarriga/nvim-dap-ui" },
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- dap ui
			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end

			-- dap keymap
			vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint, { desc = "Debug:Toggle breakpoint" })
			vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug:Continue" })

			-- node.js debugger setup
			dap.adapters["pwa-node"] = {
				type = "server",
				host = "localhost",
				port = "${port}",
				executable = {
					command = "node",
					-- 💀 Make sure to update this path to point to your installation
					args = { "~/.config/debuggers/js-debug/src/dapDebugServer.js", "${port}" },
				},
			}
			dap.configurations.javascript = {
				{
					type = "pwa-node",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					cwd = "${workspaceFolder}",
				},
			}
			dap.configurations.typescript = {
				{
					type = "pwa-node",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					cwd = "${workspaceFolder}",
				},
			}
		end,
	},
}
