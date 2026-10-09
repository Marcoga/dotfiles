-- LSP for JS/TS follows the project's own toolchain (node_modules/.bin), never a global copy:
--  - TypeScript >= 7 (native compiler): `tsc --lsp --stdio`, the typescript-go server. Same compiler as
--    `pnpm run tsc`, so the editor and CI agree. ts_ls (tsserver) stays for projects still on TS <= 6,
--    and the two never attach together.
--  - Oxlint: `oxlint --lsp` from the project, so oxlint.config.mts, its jsPlugins and the type-aware
--    rules (tsgolint) all load exactly as on the command line. Replaces eslint_d.
-- Repo-wide checks (whole-program tsc, all of oxlint, prettier) are `:Check`, see lua/checks.lua.
--
-- Servers are declared with vim.lsp.config/vim.lsp.enable. mason-lspconfig v2 ignores the old
-- `handlers` table, so settings and capabilities passed through it never reached any server.

local lockfiles = { "pnpm-lock.yaml", "package-lock.json", "yarn.lock", "bun.lock", "bun.lockb" }

-- Neovim 0.11 calls a function `cmd` with the dispatchers only (0.12 also passes the config), so the
-- root a server is starting for is remembered here from root_dir.
local starting_root

---@param root string
---@param name string
---@return string? path of an executable in the project's node_modules/.bin
local function local_bin(root, name)
	local bin = vim.fs.joinpath(root, "node_modules/.bin", name)
	return vim.fn.executable(bin) == 1 and bin or nil
end

local native_tsc = {} ---@type table<string, string|false>

--- The project's tsc if it is TypeScript 7+ (has `--lsp`), else false. Cached per root.
---@param root string
---@return string|false
local function ts7_tsc(root)
	if native_tsc[root] == nil then
		local bin = local_bin(root, "tsc")
		local out = bin and vim.system({ bin, "--version" }, { text = true }):wait()
		local version = out and out.code == 0 and vim.version.parse(out.stdout or "")
		native_tsc[root] = version and version.major >= 7 and bin or false
	end
	return native_tsc[root]
end

---@param bufnr integer
local function project_root(bufnr)
	return vim.fs.root(bufnr, lockfiles)
end

---@param name string
---@param args string[]
local function project_cmd(name, args)
	return function(dispatchers, config)
		local root = (config or {}).root_dir or starting_root
		local cmd = name == "tsc" and ts7_tsc(root) or local_bin(root, name)
		return vim.lsp.rpc.start(vim.list_extend({ cmd }, args), dispatchers, { cwd = root })
	end
end

local servers = {
	-- TypeScript 7 native language server, only where the project ships TS 7.
	tsc = {
		cmd = project_cmd("tsc", { "--lsp", "--stdio" }),
		filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
		root_dir = function(bufnr, on_dir)
			local root = project_root(bufnr)
			if root and ts7_tsc(root) then
				starting_root = root
				on_dir(root)
			end
		end,
	},

	-- tsserver, for everything that is not on TS 7 (no lockfile, or an older local typescript).
	ts_ls = {
		root_dir = function(bufnr, on_dir)
			local root = project_root(bufnr)
			if not (root and ts7_tsc(root)) then
				on_dir(
					root
						or vim.fs.root(bufnr, { "tsconfig.json", "jsconfig.json", "package.json", ".git" })
						or vim.fn.getcwd()
				)
			end
		end,
	},

	oxlint = {
		cmd = project_cmd("oxlint", { "--lsp" }),
		filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
		root_dir = function(bufnr, on_dir)
			local root = vim.fs.root(bufnr, {
				"oxlint.config.mts",
				"oxlint.config.ts",
				"oxlint.config.mjs",
				"oxlint.config.js",
				".oxlintrc.json",
				".oxlintrc.jsonc",
			})
			-- Only with the project's own oxlint: a global one cannot load the config's jsPlugins.
			if root and local_bin(root, "oxlint") then
				starting_root = root
				on_dir(root)
			end
		end,
		-- Empty on purpose: the config file decides (oxlint.config.mts turns on typeAware and
		-- reportUnusedDisableDirectives itself).
		settings = {},
	},

	bashls = {},

	lua_ls = {
		settings = {
			Lua = {
				completion = {
					callSnippet = "Replace",
				},
				workspace = {
					checkThirdParty = false,
					ignoreDir = {
						"bin/.local/share",
						"bin/.local/state",
						".local/share",
						".local/state",
						"node_modules",
						".git",
					},
				},
				-- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
				-- diagnostics = { disable = { 'missing-fields' } },
			},
		},
	},
}

return {
	-- Main LSP Configuration
	"neovim/nvim-lspconfig",
	dependencies = {
		-- Mason installs the servers that are not project-local (lua_ls, bashls, ts_ls) and the formatters.
		-- Mason must be loaded before its dependents so we need to set it up here.
		{ "mason-org/mason.nvim", opts = {} },
		"mason-org/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",

		-- Useful status updates for LSP.
		{ "j-hui/fidget.nvim", opts = {} },

		-- Allows extra capabilities provided by blink.cmp
		"saghen/blink.cmp",
	},
	config = function()
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
			callback = function(event)
				local map = function(keys, func, desc, mode)
					mode = mode or "n"
					vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
				end

				vim.keymap.set("n", "gy", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
				vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
				vim.keymap.set("n", "<leader>[", "<cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
				vim.keymap.set("n", "<leader>]", "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
				vim.keymap.set("n", "<leader>d", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
				vim.keymap.set("n", "<leader>do", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
				vim.keymap.set("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
				vim.keymap.set("n", "<leader>rs", "<cmd>LspInfo<CR>", opts)
				vim.keymap.set("i", "<C-h>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
				vim.keymap.set("n", "<leader>ld", "<cmd>Telescope diagnostics<CR>", opts)
				vim.keymap.set("n", "<leader>li", "<cmd>LspInfo<CR>", opts)
				vim.keymap.set("n", "<leader>la", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", opts)
				vim.keymap.set("n", "<leader>lr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", opts)
				vim.keymap.set(
					"n",
					"<leader>ll",
					"<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>",
					opts
				)

				map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
				map("ga", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
				map("gi", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
				map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
				map("gO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")
				map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")
				map("gt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")

				local client = vim.lsp.get_client_by_id(event.data.client_id)

				-- Highlight references of the word under the cursor while it rests there.
				if client and client:supports_method("textDocument/documentHighlight", event.buf) then
					local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.document_highlight,
					})

					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.clear_references,
					})

					vim.api.nvim_create_autocmd("LspDetach", {
						group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
						callback = function(event2)
							vim.lsp.buf.clear_references()
							vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
						end,
					})
				end

				if client and client:supports_method("textDocument/inlayHint", event.buf) then
					map("<leader>th", function()
						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
					end, "[T]oggle Inlay [H]ints")
				end

				if client and client.name == "oxlint" then
					map("<leader>lf", function()
						require("checks").oxlint_fix(event.buf)
					end, "Oxlint safe fixes (as the pre-commit hook)")
				end
			end,
		})

		-- Diagnostic Config
		-- See :help vim.diagnostic.Opts
		vim.diagnostic.config({
			severity_sort = true,
			float = { border = "rounded", source = "if_many" },
			underline = { severity = vim.diagnostic.severity.ERROR },
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "󰅚 ",
					[vim.diagnostic.severity.WARN] = "󰀪 ",
					[vim.diagnostic.severity.INFO] = "󰋽 ",
					[vim.diagnostic.severity.HINT] = "󰌶 ",
				},
			},
			virtual_text = {
				-- tsc and oxlint both report on TS files; "if_many" names the one that said it.
				source = "if_many",
				spacing = 2,
			},
		})

		vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
		for name, config in pairs(servers) do
			vim.lsp.config(name, config)
			vim.lsp.enable(name)
		end

		-- tsc and oxlint come from each project's node_modules, so Mason only installs the rest.
		require("mason-tool-installer").setup({
			ensure_installed = {
				"lua_ls",
				"bashls",
				"ts_ls", -- projects still on TypeScript <= 6
				"stylua", -- Used to format Lua code
				"prettierd", -- Used to format JavaScript, TypeScript, HTML, CSS, etc.
				"shfmt", -- Another shell script formatter
			},
		})

		-- Servers are enabled above; never auto-enable whatever else Mason has installed
		-- (an old eslint/vscode-eslint install would otherwise attach to every TS file).
		require("mason-lspconfig").setup({ automatic_enable = false })

		require("checks").setup()
	end,
}
