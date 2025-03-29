local dap = require("dap")

-- how to config
-- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#javascript

-- setup adapter
dap.adapters["pwa-node"] = {
	type = "server",
	host = "localhost",
	port = "${port}",
	executable = {
		command = "node",
		args = {
			-- https://github.com/microsoft/vscode-js-debug/releases
			-- $HOME/, ~/ 은 상대패스를 이용함. vim.env.HOME으로 패스 잡아주기
			vim.env.HOME .. "/.config/nvim/lua/dorage/plugins/debugging/js-debug/src/dapDebugServer.js",
			"${port}",
		},
	},
}

for _, language in ipairs({ "javascript", "javascriptreact" }) do
	dap.configurations[language] = {
		{
			type = "pwa-node",
			request = "launch",
			name = "Launch file",
			program = "${file}",
			cwd = "${workspaceFolder}",
		},
	}
end

for _, language in ipairs({ "typescript", "typescriptreact" }) do
	dap.configurations[language] = {
		{
			type = "pwa-node",
			request = "launch",
			name = "Launch file",
			program = "${file}",
			runtimeExecutable = "tsx",
			cwd = "${workspaceFolder}",
		},
	}
end
