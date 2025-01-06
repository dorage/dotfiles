-- LSP actions
vim.keymap.set(
	{ "n" },
	"gl",
	"<cmd>lua vim.diagnostic.open_float()<cr><esc>",
	{ desc = "Show diagnostic in a floating window" }
)
vim.keymap.set(
	{ "n" },
	"[d",
	"<cmd>lua vim.diagnostic.goto_prev()<cr><esc>",
	{ desc = "Move to the previous diagnostic in the current buffer" }
)
vim.keymap.set(
	{ "n" },
	"]d",
	"<cmd>lua vim.diagnostic.goto_next()<cr><esc>",
	{ desc = "Move to the next diagnostic in the current buffer" }
)

-- blazing fast save
vim.keymap.set({ "i", "x", "n", "s" }, "<leader>w", "<cmd>:w<cr>", { desc = "Save file" })
vim.keymap.set({ "n", "s" }, "<leader>n", "<cmd>noh<cr><esc>", { desc = ":noh" })

-- yank to clipboard
vim.keymap.set({ "n", "s" }, "<leader>y", '"+y', { desc = "Copy to clipboard" })
-- paste from clipboard
vim.keymap.set({ "n", "s" }, "<leader>p", '"+p', { desc = "Paste from clipboard" })
vim.keymap.set({ "n", "s" }, "<leader>P", '"+P', { desc = "Paste from clipboard" })

-- better substitute
-- references: https://www.youtube.com/watch?v=k_PBlhH-DKk&t=13s
vim.keymap.set({ "n" }, "<leader>sa", ":%s/<C-R><C-W>/<C-R>0/g<CR>:noh<CR>", { desc = "Substitute all" })
vim.keymap.set({ "n" }, "<leader>ss", ":s/<C-R><C-W>/<C-R>0/g<CR>:noh<CR>", { desc = "Substitute current line" })
vim.keymap.set({ "v" }, "<leader>sa", '"vy:%s/<C-R>v/<C-R>0/g<CR>:noh<CR>', { desc = "Substitute selected in file" })
vim.keymap.set(
	{ "v" },
	"<leader>ss",
	'"vy:s/<C-R>v/<C-R>0/g<CR>:noh<CR>',
	{ desc = "Substitute selected in current line" }
)

-- window adjust
vim.keymap.set({ "n" }, "<space>h", "10<c-w><", { desc = "Decrease window" })
vim.keymap.set({ "n" }, "<space>l", "10<c-w>>", { desc = "Increase window" })
vim.keymap.set({ "n" }, "<space>j", "10<c-w>-", { desc = "Decrease height" })
vim.keymap.set({ "n" }, "<space>k", "10<c-w>+", { desc = "Increase height" })
vim.keymap.set({ "n" }, "<space>o", "<c-w>o", { desc = "Close all other windows" })
vim.keymap.set({ "n" }, "<space>sh", "<c-w>s", { desc = "Split window horizontally" })
vim.keymap.set({ "n" }, "<space>sv", "<c-w>v", { desc = "Split window vertically" })

-- etc
vim.keymap.set({ "n", "s" }, "<leader>n", "<cmd>noh<cr><esc>", { desc = ":noh" })
vim.keymap.set({ "n" }, "<c-u>", "<c-u>zz", { silent = true })
vim.keymap.set({ "n" }, "<c-d>", "<c-d>zz", { silent = true })

-- buffer manipulation
vim.keymap.set({ "n" }, "<a-c>", "<cmd>bp<cr><esc>", { desc = "delete current buffer" })
vim.keymap.set({ "n" }, "<a-.>", "<cmd>bn<cr><esc>", { desc = "move to next buffer" })
vim.keymap.set({ "n" }, "<a-,>", "<cmd>bp<cr><esc>", { desc = "move to prev buffer" })

-- httpyac
vim.keymap.set({ "n" }, "<leader>hh", function()
	local fpath = vim.fn.expand("%")
	if string.match(fpath, "%.http") then
		vim.schedule(function()
			os.execute("httpyac " .. fpath)
		end)
	end
end, { desc = "Httpyac: reqeust current buffer" })
