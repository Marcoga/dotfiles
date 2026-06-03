--optoptsks eymaps.lua
-- Neovim key mappings

-- file tree editor
vim.keymap.set("n", "<leader>f", ":Oil<CR>")
vim.keymap.set("n", "<leader>bc", ":bufdo bwipeout<CR>")
-- Copilot shortcuts
vim.keymap.set("n", "<leader>cc", ":Copilot<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>cs", ":CopilotStop<CR>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-j>", "<Plug>(copilot-next)", {})
vim.keymap.set("i", "<C-k>", "<Plug>(copilot-previous)", {})

-- File explorer
vim.keymap.set("n", "<leader>pv", ":Exp<CR>", { noremap = true, silent = true })

-- Source config
vim.keymap.set("n", "<leader><CR>", ":so ~/.config/nvim/init.lua<CR>", { noremap = true, silent = true })

-- Make file executable
vim.keymap.set("n", "<leader>x", ":silent !chmod +x %<CR>", { noremap = true, silent = true })

-- Yank to system clipboard
vim.keymap.set("v", "<leader>y", '"+y', { noremap = true, silent = true })
vim.keymap.set("n", "<leader>y", '"+yiw', { noremap = true, silent = true })

-- Harpoon shortcuts
vim.keymap.set("n", "<leader>hh", '<cmd>:lua require("harpoon.mark").add_file()<cr>', { noremap = true, silent = true })
vim.keymap.set(
	"n",
	"<leader>h",
	'<cmd>lua require("harpoon.ui").toggle_quick_menu()<cr>',
	{ noremap = true, silent = true }
)
vim.keymap.set("n", "<leader>hk", '<cmd>lua require("harpoon.ui").nav_prev()<cr>', { noremap = true, silent = true })
vim.keymap.set("n", "<leader>hj", '<cmd>lua require("harpoon.ui").nav_next()<cr>', { noremap = true, silent = true })

-- TypeScript errors to quickfix
-- Simple function to open Trouble with workspace diagnostics
---local function ts_errors_to_quickfix()
-- Open Trouble with workspace diagnostics
--vim.cmd('TroubleToggle workspace_diagnostics')

-- Optionally filter to only TypeScript files
-- This uses Trouble's built-in functionality
--vim.defer_fn(function()
-- This needs to run after Trouble opens
--vim.cmd([[TroubleRefresh]])
--end, 100)

--print("Showing TypeScript errors with Trouble")
--=end
--

-- Alternative using Telescope diagnostics
--local function ts_errors_with_telescope()
--vim.cmd('Telescope diagnostics')
--end

-- Add keybinding for TypeScript errors
--0vim.keymap.set('n', '<leader>te', ts_errors_to_quickfix, { noremap = true, silent = true })
-- Alternative using Telescope
--vim.keymap.set('n', '<leader>tE', ts_errors_with_telescope, { noremap = true, silent = true })

-- Quickfix
vim.keymap.set("n", "<leader>co", ":copen<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>cn", ":cnext<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>cp", ":cprevious<CR>", { noremap = true, silent = true })

-- Buffers
vim.keymap.set("n", "<leader>.", ":bnext<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>,", ":bprevious<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>w", ":bdelete<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>`", ":bdelete!<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>s", ":w<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>q", ":q<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>fq", ":qa!<CR>", { noremap = true, silent = true })

-- Git
vim.keymap.set("n", "<Leader>ga", ":Gwrite<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>gc", ":Git commit --verbose<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>gsh", ":Git push<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>gll", ":Git pull<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>gs", ":Git<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>gb", ":Git blame<CR>", { noremap = true, silent = true })
--vim.keymap.set("n", "<Leader>gd", ":Gvdiffsplit<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>gx", ":GRemove<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>gp", ":Git -c push.default=current push<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>gh", ":.GBrowse<CR>", { noremap = true, silent = true })

-- Escape with Ctrl+c
vim.keymap.set("i", "<C-c>", "<Esc>", { noremap = true, silent = true })

vim.keymap.set("i", "<C-h>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { noremap = true, silent = true })
--vim.keymap.set("n", "<leader>ld", "<cmd>Telescope diagnostics<CR>", { noremap = true, silent = true })
--vim.keymap.set("n", "<leader>li", "<cmd>LspInfo<CR>", { noremap = true, silent = true })
--vim.keymap.set("n", "<leader>la", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", { noremap = true, silent = true })

-- Formatting
--vim.keymap.set("n", "<leader>p", "<cmd>lua vim.lsp.buf.format()<CR>", { noremap = true, silent = true })

-- Trouble.nvim (advanced diagnostics view)
--vim.keymap.set('n', '<leader>tt', '<cmd>TroubleToggle<CR>', { noremap = true, silent = true })
--vim.keymap.set('n', '<leader>tw', '<cmd>TroubleToggle workspace_diagnostics<CR>', { noremap = true, silent = true })
--vim.keymap.set('n', '<leader>td', '<cmd>TroubleToggle document_diagnostics<CR>', { noremap = true, silent = true })
--vim.keymap.set('n', '<leader>tq', '<cmd>TroubleToggle quickfix<CR>', { noremap = true, silent = true })
--vim.keymap.set('n', '<leader>tl', '<cmd>TroubleToggle loclist<CR>', { noremap = true, silent = true })
--vim.keymap.set('n', 'gR', '<cmd>TroubleToggle lsp_references<CR>', { noremap = true, silent = true })

-- Undotree
vim.keymap.set("n", "<leader>u", ":UndotreeToggle<CR>", { noremap = true, silent = true })

-- Create a proper Prettier command with LSP formatting
vim.cmd([[command! -nargs=0 Prettier lua vim.lsp.buf.format({ async = true })]])
