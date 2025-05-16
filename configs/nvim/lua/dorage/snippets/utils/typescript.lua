local M = {}

M.auto_async = function()
	local pos = vim.api.nvim_win_get_cursor(0)
	local row = pos[1] - 1
	local col = pos[2]
	local node = vim.treesitter.get_node({ pos = { row, col } })

	if node == nil then
		return
	end

	while node:type() ~= "program" do
		if
			node:type() == "function_declaration"
			or node:type() == "function_expression"
			or node:type() == "arrow_function"
		then
			local start_row, start_col, end_row, end_col = node:range()
			local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})

			if lines[1]:sub(1, 5) == "async" then
				return
			end

			vim.api.nvim_buf_set_text(0, start_row, start_col, start_row, start_col, { "async " })
		end
		node = node:parent()
	end
end

M.add_to_export = function()
	local node = vim.treesitter.get_node()

	while node:parent():type() ~= "program" do
		node = node:parent()
	end

	local type = node:type()
	vim.tbl_filter(function(v)
		return type == v
	end, {
		"function_declaration",
		"function_expression",
		"arrow_function",
		"lexical_declaration",
		"variable_declaration",
		"class_declaration",
	})

	local parser = vim.treesitter.get_parser()

	if parser == nil then
		print("Can't find Treesitter parser for this file")
		return
	end
end

return M
