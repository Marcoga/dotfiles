-- lua/plugins/init.lua (or wherever your lazy.nvim plugins are defined)

return {
	-- Your other plugins...

	{
		"junegunn/fzf",
		build = function() end,
		cmd = { "Fzf", "Rg", "Buffers", "Files", "GFiles", "History" },
		run = function()
			fn["fzf#install"]()
		end,
	},

	-- More plugins...
}
