-- options.lua
-- Neovim options and settings

local opt = vim.opt
local g = vim.g
local augroup = vim.api.nvim_create_augroup
local MarcogaGroup = augroup("Marcoga", {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup("HighlightYank", {})

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = false
vim.o.mouse = "a"
vim.o.showmode = false
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = "yes"
vim.o.updatetime = 50
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = false
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.o.inccommand = "split"
vim.o.cursorline = true
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true
-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

opt.relativenumber = true
opt.number = true

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

opt.hlsearch = false
opt.incsearch = true

opt.hidden = true
opt.errorbells = false
opt.swapfile = false
vim.opt.backup = false
opt.colorcolumn = "120"
opt.autoread = true
opt.termguicolors = true

vim.opt.undofile = true

-- Enable filetype detection and indentation
vim.cmd("filetype plugin indent on")

-- Prettier settings
--g.prettier_autoformat = 1
--g.prettier_autoformat_config_present = 1
--g.prettier_autoformat_require_pragma = 0

-- Format on save for TypeScript/React files
--vim.cmd([[
--autocmd BufWritePre *.tsx,*.ts,*.jsx,*.js,*.less Prettier
--]])

-- Wildmenu settings
opt.wildmode = "longest,list,full"
opt.wildmenu = true
opt.wildignore:append({
	"*.pyc",
	"*_build/*",
	"**/coverage/*",
	"**/node_modules/*",
	"**/android/*",
	"**/ios/*",
	"**/.git/*",
})

-- Theme settings
--g.NVIM_TUI_ENABLE_TRUE_COLOR = 1

-- Syntax highlighting
--vim.cmd('syntax enable')
require("night-owl").setup()
vim.cmd.colorscheme("night-owl")

vim.filetype.add({
	extension = {
		templ = "templ",
	},
})

autocmd("TextYankPost", {
	group = yank_group,
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({
			higroup = "IncSearch",
			timeout = 40,
		})
	end,
})

autocmd({ "BufWritePre" }, {
	group = MarcogaGroup,
	pattern = "*",
	command = [[%s/\s\+$//e]],
})

autocmd("LspAttach", {
	group = MarcogaGroup,
	callback = function(e)
		local opts = { buffer = e.buf }

        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
        vim.keymap.set('n', 'gy', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
        vim.keymap.set('n', '<leader>[', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
        vim.keymap.set('n', '<leader>]', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
        vim.keymap.set('n', '<leader>d', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
        vim.keymap.set('n', '<leader>do', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
        vim.keymap.set('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
        vim.keymap.set('i', '<C-h>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
        vim.keymap.set('n', '<leader>ld', '<cmd>Telescope diagnostics<CR>', opts)
        vim.keymap.set('n', '<leader>li', '<cmd>LspInfo<CR>', opts)
        vim.keymap.set('n', '<leader>la', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
        vim.keymap.set('n', '<leader>lr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
        vim.keymap.set('n', '<leader>ll', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
	end,
})
