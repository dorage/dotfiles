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

			-- load debugger configs
			require("dorage.configs.debuggers")
		end,
	},
}
