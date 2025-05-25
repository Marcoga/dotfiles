-- telescope.lua
-- Telescope configuration with customizations

local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  return
end

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Custom function to delete buffer from Telescope

-- Configure Telescope with custom mappings
telescope.setup({
  defaults = {
    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-n>"] = actions.move_selection_next,
        ["<C-p>"] = actions.move_selection_previous,
        ["<C-x>"] = actions.close,
        ["<Esc>"] = actions.close,
      },
      n = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-n>"] = actions.move_selection_next,
        ["<C-p>"] = actions.move_selection_previous,
        ["<C-x>"] = actions.close,
        ["<Esc>"] = actions.close,
        ["q"] = actions.close,
      },
    },
  },

  pickers = {
    buffers = {
      sort_lastused = true,
    },
  },
})

return telescope
