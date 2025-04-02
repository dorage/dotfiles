local dap = require("dap")

-- how to config
-- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#javascript

local adapter_types = { "pwa-node", "pwa-chrome" }

-- setup adapter
for _, type in ipairs(adapter_types) do
	dap.adapters[type] = {
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
end

for _, language in ipairs({ "javascript" }) do
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

for _, language in ipairs({ "typescript" }) do
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

for _, language in ipairs({ "javascriptreact", "typescriptreact" }) do
	dap.configurations[language] = {
		{
			type = "pwa-chrome",
			request = "launch",
			name = "Launch Chrome (nvim-dap)",
			url = function()
				local co = coroutine.running()
				return coroutine.create(function()
					vim.ui.input({ prompt = "Enter URL: ", default = "http://localhost:" }, function(url)
						if url == nil or url == "" then
							return
						else
							coroutine.resume(co, url)
						end
					end)
				end)
			end,
			webRoot = "${workspaceFolder}",
			sourceMaps = true,
		},
	}
end
