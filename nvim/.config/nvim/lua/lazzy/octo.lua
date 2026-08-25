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
		require("octo").setup({
			enable_builtin = true,
			-- The runner's i360 worktrees fetch from the mini's bare repo over git://,
			-- so "origin" is not a GitHub URL there and octo resolves the wrong host.
			-- A "github" remote is added on that box; prefer it when present.
			default_remote = { "github", "upstream", "origin" },
		})
	end,
	keys = {
		--{ "<leader>pl", "<cmd>Octo issue list<cr>", desc = "List issues" },
		--{ "<leader>gp", "<cmd>Octo pr list<cr>", desc = "List pull requests" },
		--{ "<leader>gc", "<cmd>Octo commands<cr>", desc = "Show commands" },
		{ "<leader>P", "<cmd>Octo<cr>", desc = "Quick pick" },
	},
}
