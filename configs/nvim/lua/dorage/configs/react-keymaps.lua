-- react keymap
vim.api.nvim_create_autocmd("FileType", {
	pattern = "javascript,typescript,javascriptreact,typescriptreact",
	callback = function()
		vim.keymap.set({ "n" }, "<leader>mc", function()
			-- Search for 'className='
			local search_result = vim.fn.search("className=", "W")

			-- Check if search was successful
			if search_result == 0 then
				vim.api.nvim_echo({ { "No 'className=' found.", "WarningMsg" } }, true, {})
				return
			end

			-- Get the current line
			local current_line = vim.api.nvim_get_current_line()

			-- Find position of next quote/double quote after current cursor position
			local quote_pos = string.find(current_line, "[\"'`]", vim.fn.col("."))

			-- Check if a quote was found
			if quote_pos == nil then
				vim.api.nvim_echo({ { "No quote found after 'className='.", "WarningMsg" } }, true, {})
				return
			end
			-- Move cursor to the quote position + 1 (inside the quotes)
			vim.api.nvim_win_set_cursor(0, { vim.fn.line("."), quote_pos })
		end, { desc = "move to className", buffer = true })
	end,
})
