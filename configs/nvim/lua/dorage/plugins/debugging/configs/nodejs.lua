local dap = require("dap")

-- how to config
-- https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#vscode-js-debug

-- vscode-js-debug 는 mason 이 설치함 (lsp/config.lua ensure_installed 의 js-debug-adapter)
local js_debug_server = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"

local adapter_types = { "pwa-node", "pwa-chrome" }

-- setup adapter
for _, type in ipairs(adapter_types) do
	dap.adapters[type] = {
		type = "server",
		host = "localhost",
		port = "${port}",
		executable = {
			command = "node",
			args = { js_debug_server, "${port}" },
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
