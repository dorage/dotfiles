return {
	{
		'l3mon4d3/luasnip',
		lazy=true,
		build = "make install_jsregexp",
		config = function()
			s("trig", {
				i(1), t"text", i(2), t"text again", i(3)
			})
		end
	}
}
