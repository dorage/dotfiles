local dap = require("dap")

-- how to config
-- https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#python

-- debugpy 는 mason 이 전용 virtualenv 에 설치함 (lsp/config.lua ensure_installed)
local debugpy_python = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"

dap.adapters.python = function(cb, config)
	if config.request == "attach" then
		---@diagnostic disable-next-line: undefined-field
		local port = (config.connect or config).port
		---@diagnostic disable-next-line: undefined-field
		local host = (config.connect or config).host or "127.0.0.1"
		cb({
			type = "server",
			port = assert(port, "`connect.port` is required for a python `attach` configuration"),
			host = host,
			options = {
				source_filetype = "python",
			},
		})
	else
		cb({
			type = "executable",
			command = debugpy_python,
			args = { "-m", "debugpy.adapter" },
			options = {
				source_filetype = "python",
			},
		})
	end
end

-- 디버깅 대상 프로그램을 실행할 interpreter (debugpy 를 실행하는 interpreter 와 별개)
local function python_path()
	local cwd = vim.fn.getcwd()
	for _, venv in ipairs({ "venv", ".venv" }) do
		if vim.fn.executable(cwd .. "/" .. venv .. "/bin/python") == 1 then
			return cwd .. "/" .. venv .. "/bin/python"
		end
	end
	if vim.env.VIRTUAL_ENV then
		return vim.env.VIRTUAL_ENV .. "/bin/python"
	end
	return vim.fn.exepath("python3")
end

dap.configurations.python = {
	{
		type = "python",
		request = "launch",
		name = "Launch file",
		program = "${file}",
		cwd = "${workspaceFolder}",
		pythonPath = python_path,
	},
	{
		type = "python",
		request = "attach",
		name = "Attach (127.0.0.1:5678)",
		connect = {
			host = "127.0.0.1",
			port = 5678,
		},
	},
}
