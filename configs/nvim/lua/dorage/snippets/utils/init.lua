local M = {}

--- 커서 위치를 원복시키는데 사용
M.restore_cursor = function(fn)
	vim.schedule(function()
		local ns = vim.api.nvim_create_namespace("auto_async")
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		local extmark_id = vim.api.nvim_buf_set_extmark(0, ns, row - 1, col, {})

		fn()

		local restore_pos = vim.api.nvim_buf_get_extmark_by_id(0, ns, extmark_id, {})
		vim.api.nvim_win_set_cursor(0, { restore_pos[1] + 1, restore_pos[2] })

		vim.api.nvim_buf_del_extmark(0, ns, extmark_id)
		vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
	end)
end

return M
