return {
	"nvim-telescope/telescope.nvim",

	tag = "0.1.5",

	dependencies = {
		"nvim-lua/plenary.nvim",
	},

	config = function()
		require("telescope").setup({})

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>e", builtin.git_files)
		vim.keymap.set("n", "<leader>o", builtin.buffers)
		vim.keymap.set("n", "<leader>l", builtin.oldfiles)
		vim.keymap.set("n", "<leader>fs", builtin.git_status)
		vim.keymap.set("n", "<leader>fc", builtin.git_commits)
		vim.keymap.set("n", "<leader>fz", builtin.git_stash)
		vim.keymap.set("n", "<leader>ff", builtin.find_files)

		vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
		vim.keymap.set("n", "<leader>ps", function()
			builtin.grep_string({ search = vim.fn.input("Grep > ") })
		end)
		vim.keymap.set("n", "<leader>fb", "<cmd>Telescope git_branches<cr>")
		vim.keymap.set("n", "<leader>fh", builtin.help_tags)
		vim.keymap.set("n", "<leader>8", "<cmd>Telescope grep_string<cr>")

		vim.keymap.set("n", "<leader>fr", "<cmd>Telescope registers<cr>")
		vim.keymap.set("n", "<leader>fe", ":GFiles<CR>")
	end,
}
