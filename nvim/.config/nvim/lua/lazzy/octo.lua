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

		-- Kill a wasted request that hard-blocks the UI on big PRs.
		-- The PullRequest constructor prefetches the raw unified diff and then never
		-- reads it: pr.diff is assigned once (model/pull-request.lua:118) and has no
		-- reader anywhere in the plugin. GitHub refuses that endpoint above 300 files
		-- with HTTP 406, octo raises it, and the multi-line message trips a
		-- "Press ENTER to continue" prompt on EVERY review of such a PR (i360 #6659 is
		-- 446 files). Nothing downstream notices it going away.
		require("octo.model.pull-request").PullRequest.get_diff = function() end
	end,
	keys = {
		--{ "<leader>pl", "<cmd>Octo issue list<cr>", desc = "List issues" },
		--{ "<leader>gp", "<cmd>Octo pr list<cr>", desc = "List pull requests" },
		--{ "<leader>gc", "<cmd>Octo commands<cr>", desc = "Show commands" },
		{ "<leader>P", "<cmd>Octo<cr>", desc = "Quick pick" },
		-- GitHub's "Files changed" tab: changed-file panel + side-by-side diff of
		-- base...head. Bare ":Octo review" resolves the PR from the current octo
		-- buffer, else from the checked-out branch, and RESUMES a pending review
		-- (keeping unsubmitted comments) instead of starting a fresh one.
		{ "<leader>p", "<cmd>Octo review<cr>", desc = "PR diff (Files changed)" },
	},
}
