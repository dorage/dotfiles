-- LSP actions
vim.keymap.set(
	{ "n" },
	"gl",
	"<cmd>lua vim.diagnostic.open_float()<cr><esc>",
	{ desc = "Show diagnostic in a floating window" }
)
-- vim.keymap.set(
-- 	{ "n" },
-- 	"[d",
-- 	"<cmd>lua vim.diagnostic.goto_prev()<cr><esc>",
-- 	{ desc = "Move to the previous diagnostic in the current buffer" }
-- )
-- vim.keymap.set(
-- 	{ "n" },
-- 	"]d",
-- 	"<cmd>lua vim.diagnostic.goto_next()<cr><esc>",
-- 	{ desc = "Move to the next diagnostic in the current buffer" }
-- )

-- blazing fast save
vim.keymap.set({ "i", "x", "n", "s" }, "<leader>w", "<cmd>:w<cr>", { desc = "Save file" })

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
-- close buffer only
vim.keymap.set({ "n" }, "<c-w>b", "<cmd>bp | sp | bn | bd<cr>", { desc = "Close buffer" })

-- etc
vim.keymap.set({ "n", "s" }, "<leader>n", "<cmd>noh<cr><esc>", { desc = "No highlight" })
vim.keymap.set({ "n" }, "<c-u>", "<c-u>zz", { silent = true, desc = "scroll up and center" })
vim.keymap.set({ "n" }, "<c-d>", "<c-d>zz", { silent = true, desc = "scroll down and center" })

-- buffer manipulation
vim.keymap.set({ "n" }, "<a-c>", "<cmd>bd<cr><esc>", { desc = "delete current buffer" })
vim.keymap.set({ "n" }, "<a-.>", "<cmd>bn<cr><esc>", { desc = "move to next buffer" })
vim.keymap.set({ "n" }, "<a-,>", "<cmd>bp<cr><esc>", { desc = "move to prev buffer" })
vim.keymap.set({ "n" }, "<a-;>", "<cmd>b#<cr><esc>", { desc = "move to last buffer" })

-- httpyac
vim.keymap.set({ "n" }, "<leader>hh", function()
	local fpath = vim.fn.expand("%")
	if string.match(fpath, "%.http") then
		vim.schedule(function()
			os.execute("httpyac " .. fpath)
		end)
	end
end, { desc = "Httpyac: reqeust current buffer" })

-- replace floaterm
vim.keymap.set({ "n" }, "<leader>ag", function()
	vim.fn.jobstart(
		"zellij run --floating --name lazygit --width 90% --height 90% -x 5% -y 5% --close-on-exit -- lazygit"
	)
end, { desc = "open lazygit" })
vim.keymap.set({ "n" }, "<leader>ao", function()
	vim.fn.jobstart(
		"zellij run --floating --name lazygit --width 90% --height 90% -x 5% -y 5% --close-on-exit -- lazydocker"
	)
end, { desc = "open lazydocker" })

-- LSP
vim.keymap.set("n", "K", function()
	vim.lsp.buf.hover({ border = "single", max_height = 25, max_width = 120 })
end, { silent = true })
vim.keymap.set("n", "gl", function()
	vim.diagnostic.open_float({ border = "single", max_height = 25, max_width = 120 })
end, { silent = true })

-- Markdown view with typora
vim.keymap.set("n", "<leader>zp", function()
	vim.cmd("!open -a typora " .. vim.fn.expand("%:p"))
end, { desc = "Open Markdown in Typora" })
