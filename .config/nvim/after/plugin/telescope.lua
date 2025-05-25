
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>e', '<cmd>Telescope git_files<cr>')
vim.keymap.set('n', '<leader>o', '<cmd>Telescope buffers<cr>')
vim.keymap.set('n', '<leader>l', builtin.oldfiles)

vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<cr>')
vim.keymap.set('n', '<leader>ps', function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end)
vim.keymap.set('n', '<leader>fb', '<cmd>Telescope git_branches<cr>')
vim.keymap.set('n', '<leader>fh', builtin.help_tags)
vim.keymap.set('n', '<leader>8', '<cmd>Telescope grep_string<cr>')

vim.keymap.set('n', '<leader>fr', '<cmd>Telescope registers<cr>')
vim.keymap.set('n', '<leader>fe', ':GFiles<CR>')
vim.keymap.set('n', '<leader>ff', ':Files<CR>')
