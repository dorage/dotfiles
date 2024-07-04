---------------------------------------------------------------------------------------
--
-- import modules
--
---------------------------------------------------------------------------------------

local f = require("dorage.utils.fp")

---------------------------------------------------------------------------------------
--
-- define type hints
--
---------------------------------------------------------------------------------------

---@class Import
---@field source string
---@field modules string[]
---@field default_modules string[]

---@class ImportMap: Import
---@field node TSNode

---------------------------------------------------------------------------------------
--
-- functions
--
---------------------------------------------------------------------------------------

---return root of AST
---@return TSNode
local function get_curr_bufr_root()
	local parser = vim.treesitter.get_parser()
	local tree = parser:parse()
	local root = tree[1]:root()

	return root
end

---return the text that the range indicates
---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
---@return string
local function get_text_by_range(start_row, start_col, end_row, end_col)
	return (vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {}))[1]
end

--- find a node by condition under node
--- @param node TSNode
--- @param condition fun(node:TSNode): boolean
---@return TSNode[]
local function search_node(node, condition)
	local found = {}

	if condition(node) then
		found = { node }
	end

	for child in node:iter_children() do
		local new_found = search_node(child, condition)
		for _, value in pairs(new_found) do
			found[#found + 1] = value
		end
	end

	return found
end

---get import statement nodes
---@return TSNode[]
local function get_import_statements()
	local root = get_curr_bufr_root()

	-- get import statements
	local import_statements = {}
	for child in root:iter_children() do
		if child:type() == "import_statement" then
			import_statements[#import_statements + 1] = child
		end
	end
	return import_statements
end

---comment
---@return ImportMap[]
local function get_parsed_import_statements()
	---@type Import[]
	local import_map = {}
	local import_statements = get_import_statements()

	-- parse import statements
	for _, import_stmt in ipairs(import_statements) do
		local source_nodes = search_node(import_stmt, function(node)
			return node:type() == "string_fragment"
		end)
		local module_nodes = search_node(import_stmt, function(node)
			return node:type() == "identifier" and node:parent():type() == "import_specifier"
		end)
		local default_module_nodes = search_node(import_stmt, function(node)
			return node:type() == "identifier" and node:parent():type() == "import_clause"
		end)

		local source = get_text_by_range(source_nodes[1]:range())
		local modules = f.map(module_nodes, function(node)
			return get_text_by_range(node:range())
		end)
		local default_modules = f.map(default_module_nodes, function(node)
			return get_text_by_range(node:range())
		end)

		import_map[#import_map + 1] =
			{ node = import_stmt, source = source, modules = modules, default_modules = default_modules }
	end

	return import_map
end

---generate import statement string
---@param import Import
local function gen_import_statement(import)
	---comment
	---@param source_name string
	local source_string = function(source_name)
		return "'" .. source_name .. "'"
	end

	-- import module
	if import.default_modules[#import.default_modules] == nil and import.modules[#import.modules] == nil then
		return "import" .. source_string(import.source)
	end

	---@type string[]
	local import_stmt_tokens = { "import" }

	-- add default modules
	if import.default_modules[#import.default_modules] ~= nil then
		import_stmt_tokens[#import_stmt_tokens + 1] = table.concat(import.default_modules, ", ")
		-- if modules exists
		if import.modules[#import.modules] ~= nil then
			import_stmt_tokens[#import_stmt_tokens + 1] = ","
		end
	end

	-- add modules
	if import.modules[#import.modules] ~= nil then
		import_stmt_tokens[#import_stmt_tokens + 1] = "{"
		import_stmt_tokens[#import_stmt_tokens + 1] = table.concat(import.modules, ", ")
		import_stmt_tokens[#import_stmt_tokens + 1] = "}"
	end

	import_stmt_tokens[#import_stmt_tokens + 1] = "from"
	import_stmt_tokens[#import_stmt_tokens + 1] = source_string(import.source)

	return table.concat(import_stmt_tokens, " ")
end

---------------------------------------------------------------------------------------
--
-- module end-points
--
---------------------------------------------------------------------------------------

local M = {}

---import modules under the last import statement in the buffer
---@param imports Import[]
M.import = function(imports)
	-- local import_stmts = get_import_statements()
	local parsed_import_stmts = get_parsed_import_statements()
	-- preserve cursor position
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))

	for _, import in ipairs(imports) do
		local matched_import_stmts = f.filter(parsed_import_stmts, function(import_stmt)
			return import_stmt.source == import.source
		end)

		-- if the import statement, has same source, does not exist
		if matched_import_stmts[#matched_import_stmts] == nil then
			local last_import_stmt = parsed_import_stmts[#parsed_import_stmts]
			if last_import_stmt == nil then
				local buf = vim.api.nvim_buf_get_lines(0, 0, -1, false)
				vim.api.nvim_buf_set_lines(0, 0, -1, false, { gen_import_statement(import), unpack(buf) })
			else
				local _, _, end_row = last_import_stmt.node:range()
				local buf = vim.api.nvim_buf_get_lines(0, end_row + 1, -1, false)
				vim.api.nvim_buf_set_lines(0, end_row + 1, -1, false, { gen_import_statement(import), unpack(buf) })
			end
			-- line had added
			row = row + 1
			goto continue
		end

		local existed_modules = f.pipe(
			f.pipe_curry(f.map, function(import_stmt)
				return import_stmt.modules
			end),
			unpack,
			f.combine
		)(matched_import_stmts)

		local existed_default_modules = f.pipe(
			f.pipe_curry(f.map, function(import_stmt)
				return import_stmt.default_modules
			end),
			unpack,
			f.combine
		)(matched_import_stmts)

		local missing_modules = f.filter(import.modules, function(module)
			return not f.some(existed_modules, function(existed_module)
				return module == existed_module
			end)
		end)

		local missing_default_modules = f.filter(import.default_modules, function(module)
			return not f.some(existed_default_modules, function(existed_default_module)
				return module == existed_default_module
			end)
		end)

		local last_import_stmt = matched_import_stmts[#matched_import_stmts]
		local start_row, _, end_row = last_import_stmt.node:range()

		vim.api.nvim_buf_set_lines(0, start_row, end_row + 1, false, {
			gen_import_statement({
				source = import.source,
				default_modules = f.combine(last_import_stmt.default_modules, missing_default_modules),
				modules = f.combine(last_import_stmt.modules, missing_modules),
			}),
		})

		::continue::
	end
end

---import modules under the last import statement in the buffer
---@param imports Import[]
M.import_callback = function(imports)
	return {
		[-1] = {
			[require("luasnip.util.events").enter] = function()
				vim.schedule(function()
					local start_node_row = vim.treesitter.get_node():range()
					local start_cursor_row, start_cursor_col = unpack(vim.api.nvim_win_get_cursor(0))

					M.import(imports)

					local final_node_row = vim.treesitter.get_node():range()
					vim.api.nvim_win_set_cursor(0, {
						final_node_row + (start_cursor_row - start_node_row),
						start_cursor_col,
					})
				end)
			end,
		},
	}
end

return M
