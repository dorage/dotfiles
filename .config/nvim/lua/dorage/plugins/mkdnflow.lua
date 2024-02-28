return {
	'jakewvincent/mkdnflow.nvim',
	config = function ()
		require('mkdnflow').setup({
				-- links = {
				--     transform_explicit = function(text)
				--         -- Make lowercase, remove spaces, and reverse the string
				--         return string.lower(text:gsub(' ', ''))
				--     end
				-- }
		})
	end
}
