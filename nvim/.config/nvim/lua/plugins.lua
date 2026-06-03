vim.cmd.packadd("packer.nvim")

return require("packer").startup(function(use)
	-- Packer can manage itself
	use("wbthomason/packer.nvim")

	use({
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		requires = { { "nvim-lua/plenary.nvim" } },
	})

	use({
		"folke/trouble.nvim",
		config = function()
			require("trouble").setup({
				opts = {},
				-- your configuration comes here
				-- or leave it empty to use the default settings
				-- refer to the configuration section below
				cmd = "Trouble",
				keys = {
					{
						"<leader>dx",
						"<cmd>Trouble diagnostics toggle<cr>",
						desc = "Diagnostics (Trouble)",
					},
					{
						"<leader>dX",
						"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
						desc = "Buffer Diagnostics (Trouble)",
					},
					{
						"<leader>ds",
						"<cmd>Trouble symbols toggle focus=false<cr>",
						desc = "Symbols (Trouble)",
					},
					{
						"<leader>cl",
						"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
						desc = "LSP Definitions / references / ... (Trouble)",
					},
					{
						"<leader>dL",
						"<cmd>Trouble loclist toggle<cr>",
						desc = "Location List (Trouble)",
					},
					{
						"<leader>dQ",
						"<cmd>Trouble qflist toggle<cr>",
						desc = "Quickfix List (Trouble)",
					},
				},
			})
		end,
	})

	use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })
	use("nvim-treesitter/playground")
	use("theprimeagen/harpoon")
	use("mbbill/undotree")
	use("tpope/vim-fugitive")
	use("nvim-treesitter/nvim-treesitter-context")

	use({ "stevearc/conform.nvim" })
	use({
		"williamboman/mason-lspconfig.nvim",
		requires = {
			-- Automatically install LSPs and related tools to stdpath for Neovim
			-- Mason must be loaded before its dependents so we need to set it up here.
			-- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",

			-- Useful status updates for LSP.
			{ "j-hui/fidget.nvim", opts = {} },

			-- Allows extra capabilities provided by blink.cmp
			"saghen/blink.cmp",
		},
	})

	use({ "hrsh7th/cmp-nvim-lsp" })
	use({ "hrsh7th/cmp-buffer" })
	use({ "hrsh7th/cmp-path" })
	use({ "hrsh7th/cmp-cmdline" })
	use({ "hrsh7th/nvim-cmp" })
	use({ "L3MON4D3/LuaSnip" })
	use({ "saadparwaiz1/cmp_luasnip" })
	use({ "j-hui/fidget.nvim" })

	use("nvim-tree/nvim-web-devicons")

	use("airblade/vim-gitgutter")
	use("folke/zen-mode.nvim")
	use("github/copilot.vim")
	use("eandrju/cellular-automaton.nvim")
	use("laytan/cloak.nvim")

	use("oxfist/night-owl.nvim")
	use("mhartington/oceanic-next")

	-- Navigation
	use("easymotion/vim-easymotion")

	-- Status line
	use("vim-airline/vim-airline")
	use("vim-airline/vim-airline-themes")

	-- FZF
	use({
		"junegunn/fzf",
		run = function()
			fn["fzf#install"]()
		end,
	})
	use("junegunn/fzf.vim")

	-- Text manipulation
	use("tommcdo/vim-exchange")
	use("tpope/vim-surround")
	use("psliwka/vim-smoothie")
end)
