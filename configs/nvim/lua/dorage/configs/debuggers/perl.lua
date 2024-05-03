local dap = require("dap")
dap.adapters.perl = {
	type = "executable",
	-- Path to perl-debug-adapter - will be different based on the installation method
	-- mason.nvim
	command = vim.env.MASON .. "/bin/perl-debug-adapter",
	-- AUR (or if perl-debug-adapter is in PATH)
	-- command = 'perl-debug-adapter',
	args = {},
}

dap.configurations.perl = {
	{
		type = "perl",
		request = "launch",
		name = "Launch Perl",
		program = "${workspaceFolder}/${relativeFile}",
	},
}
-- this is optional but can be helpful when starting out
dap.set_log_level("TRACE")
