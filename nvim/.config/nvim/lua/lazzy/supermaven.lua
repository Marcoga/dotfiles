return {
	"supermaven-inc/supermaven-nvim",
	event = "InsertEnter",
	opts = {
		keymaps = {
			accept_suggestion = "<Tab>",
			clear_suggestion = "<C-]>",
			accept_word = "<C-j>",
		},
		ignore_filetypes = { TelescopePrompt = true, ["avante-input"] = true },
		color = {
			suggestion_color = "#6c7086",
			cterm = 244,
		},
		log_level = "warn",
		disable_inline_completion = false,
		disable_keymaps = false,
	},
}
