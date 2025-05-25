-- options.lua
-- Neovim options and settings

local opt = vim.opt
local g = vim.g

-- General settings
opt.scrolloff = 8
opt.signcolumn = "yes"

opt.relativenumber = true
opt.number = true

opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

opt.hlsearch = false
opt.incsearch = true

opt.ignorecase = true
opt.smartcase = true
opt.hidden = true
opt.errorbells = false
opt.swapfile = false
vim.opt.backup = false
opt.colorcolumn = "120"
opt.autoread = true
opt.termguicolors = true
vim.opt.updatetime = 50

vim.opt.undofile = true

-- Enable filetype detection and indentation
vim.cmd('filetype plugin indent on')

-- Prettier settings
g.prettier_autoformat = 1
g.prettier_autoformat_config_present = 1
g.prettier_autoformat_require_pragma = 0

-- Format on save for TypeScript/React files
vim.cmd([[
  autocmd BufWritePre *.tsx,*.ts,*.jsx,*.js Prettier
]])

-- Wildmenu settings
opt.wildmode = "longest,list,full"
opt.wildmenu = true
opt.wildignore:append {
  "*.pyc",
  "*_build/*",
  "**/coverage/*",
  "**/node_modules/*",
  "**/android/*",
  "**/ios/*",
  "**/.git/*"
}

-- Leader key
g.mapleader = " "

-- Theme settings
--g.NVIM_TUI_ENABLE_TRUE_COLOR = 1

-- Syntax highlighting
--vim.cmd('syntax enable')
require("night-owl").setup()
vim.cmd.colorscheme("night-owl")

