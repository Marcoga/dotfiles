-- Prettier = the files i360's pre-commit hook formats (utils/config/.lintstagedrc.js):
-- *.{ts,tsx} and *.{js,jsx,json,mjs,less,css,html}.
local prettier = { "prettierd", "prettier", stop_after_first = true }

return {
	"stevearc/conform.nvim",
	opts = {},
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = prettier,
				javascriptreact = prettier,
				typescript = prettier,
				typescriptreact = prettier,
				json = prettier,
				jsonc = prettier,
				css = prettier,
				less = prettier,
				html = prettier,
				sh = { "shfmt" },
			},
			format_on_save = {
				-- These options will be passed to conform.format()
				timeout_ms = 500,
				lsp_format = "fallback",
			},
		})

		-- Format with Prettier, not with whatever LSP is attached (the TS 7 server formats too, differently).
		vim.api.nvim_create_user_command("Prettier", function()
			require("conform").format({ async = true, lsp_format = "never" })
		end, { desc = "Format the buffer with prettierd/prettier" })
	end,
}
