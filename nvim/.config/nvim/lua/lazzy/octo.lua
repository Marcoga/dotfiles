return {
	"pwntester/octo.nvim",
	requires = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		-- OR 'ibhagwan/fzf-lua',
		-- OR 'folke/snacks.nvim',
		"nvim-tree/nvim-web-devicons",
	},
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
