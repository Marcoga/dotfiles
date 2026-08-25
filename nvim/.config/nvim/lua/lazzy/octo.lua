return {
	"pwntester/octo.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		-- OR 'ibhagwan/fzf-lua',
		-- OR 'folke/snacks.nvim',
		"nvim-tree/nvim-web-devicons",
	},
	-- Without this, :Octo only exists after <leader>P has been pressed, so the
	-- ":Octo search ..." keymaps in keymaps.lua fail with E492.
	cmd = "Octo",
	config = function()
		require("octo").setup({ enable_builtin = true })
	end,
	keys = {
		--{ "<leader>pl", "<cmd>Octo issue list<cr>", desc = "List issues" },
		--{ "<leader>gp", "<cmd>Octo pr list<cr>", desc = "List pull requests" },
		--{ "<leader>gc", "<cmd>Octo commands<cr>", desc = "Show commands" },
		{ "<leader>P", "<cmd>Octo<cr>", desc = "Quick pick" },
	},
}
