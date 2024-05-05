for _, ftype in ipairs({ "nodejs", "perl" }) do
	require("dorage.configs.debuggers." .. ftype)
end
