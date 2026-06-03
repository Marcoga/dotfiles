-- lua/plugins/init.lua (or wherever your lazy.nvim plugins are defined)

return {
	-- Your other plugins...

	{
		"junegunn/fzf",
		build = function()
			-- This build step is usually not necessary for fzf.vim itself,
			-- as it mostly relies on the external fzf binary.
			-- However, some setups might include specific post-install hooks here.
			-- For most cases, you can remove or comment out the 'build' key for fzf.
			-- If you *do* want to ensure fzf is available *within* Neovim's context,
			-- especially if you're using it in a unique way, you might put
			-- a check or install command here.
			-- For standard fzf.vim usage, rely on system-wide installation.
		end,
		-- Important: fzf.vim provides commands, so we set cmd = true
		-- or provide a list of commands it registers.
		cmd = { "Fzf", "Rg", "Buffers", "Files", "GFiles", "History" },
		-- You can also use event for lazy loading, e.g., 'BufReadPre'
		-- event = 'BufReadPre',
		-- Alternatively, if you want it loaded early for global keybindings:
		-- lazy = false,
		config = function()
			-- Optional: Add any fzf.vim specific configurations here.
			-- For example, to change default window options:
			-- vim.g.fzf_layout = { width = '80%', height = '60%' }
			-- vim.g.fzf_buffers_jump = 1 -- Jump to buffer if already open
			-- print("fzf.vim loaded and configured.")
		end,
	},

	-- More plugins...
}
