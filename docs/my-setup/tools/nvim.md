# Neovim Configuration

Config: `~/.config/nvim/` (stowed from `~/dotfiles/.config/nvim/`)

## Architecture

Three-module system loaded from `init.lua`:

```lua
require("options")    -- Editor settings
require("keymaps")    -- Key bindings
require("lazy_init")  -- Plugin manager bootstrap
```

## Leader Key

**`<Space>`**

## Editor Settings (options.lua)

| Setting | Value |
|---------|-------|
| Tab width | 2 spaces |
| Line numbers | Absolute + relative |
| Color column | 120 |
| Mouse | Enabled |
| True colors | Enabled |
| Swap files | Disabled |
| Undo file | Enabled (persistent undo) |
| Search | Case-insensitive, smart case |
| Scroll offset | 10 lines |

### Auto-commands

- **Highlight yank:** Brief highlight on yank (40ms)
- **Trim whitespace:** Remove trailing whitespace on save

## Key Bindings (keymaps.lua)

### Files & Buffers

| Keybinding | Action |
|------------|--------|
| `<leader>f` | Oil file browser |
| `<leader>s` | Save file |
| `<leader>w` | Close buffer |
| `<leader>`` | Force close buffer |
| `<leader>.` | Next buffer |
| `<leader>,` | Previous buffer |
| `<leader>bc` | Close all buffers |

### Navigation

| Keybinding | Action |
|------------|--------|
| `<leader>hh` | Harpoon: Add file |
| `<leader>h` | Harpoon: Toggle menu |
| `<leader>hk` | Harpoon: Previous |
| `<leader>hj` | Harpoon: Next |

### Git (Fugitive)

| Keybinding | Action |
|------------|--------|
| `<leader>gs` | Git status |
| `<leader>ga` | Git add (current file) |
| `<leader>gc` | Git commit (verbose) |
| `<leader>gsh` | Git push |
| `<leader>gll` | Git pull |
| `<leader>gb` | Git blame |
| `<leader>gd` | Git diff split |
| `<leader>gh` | Open in GitHub |

### GitHub PRs (Octo)

| Keybinding | Action |
|------------|--------|
| `<leader>pc` | My open PRs (i360) |
| `<leader>pr` | PRs requesting my review |
| `<leader>pa` | All open PRs (i360) |

### Copilot

| Keybinding | Action |
|------------|--------|
| `<leader>cc` | Toggle Copilot |
| `<leader>cs` | Stop Copilot |
| `Ctrl+j` (insert) | Next suggestion |
| `Ctrl+k` (insert) | Previous suggestion |

### Utilities

| Keybinding | Action |
|------------|--------|
| `<leader>y` | Yank to system clipboard |
| `<leader>x` | Make file executable |
| `<leader>u` | Toggle undotree |
| `<leader><CR>` | Source config |
| `Ctrl+c` (insert) | Escape |

### Quickfix

| Keybinding | Action |
|------------|--------|
| `<leader>co` | Open quickfix |
| `<leader>cn` | Next item |
| `<leader>cp` | Previous item |

## Plugins

Plugin manager: **lazy.nvim**

Plugins configured in `lua/lazzy/`:

| Plugin | File | Purpose |
|--------|------|---------|
| telescope | `telescope.lua` | Fuzzy finder |
| oil.nvim | `oil.lua` | File browser |
| harpoon | (keymaps) | Quick file navigation |
| fugitive | `fugitive.lua` | Git integration |
| octo.nvim | `octo.lua` | GitHub PRs in nvim |
| treesitter | `treesitter.lua` | Syntax parsing |
| nvim-lspconfig | `lsp.lua` | Language servers |
| blink.cmp | `blink.lua` | Completion |
| conform.nvim | `conform.lua` | Formatting |
| trouble.nvim | `trouble.lua` | Diagnostics |
| undotree | `undotree.lua` | Undo history |
| avante | `avante.lua` | AI assistant |
| copilot.lua | (keymaps) | GitHub Copilot |
| LuaSnip | `snippets.lua` | Snippets |
| cloak | `cloak.lua` | Hide secrets |
| peek | `peek.lua` | Markdown preview |
| fzf | `fzf.lua` | FZF integration |
| lazydev | `lazydev.lua` | Lua dev tools |

### Theme

Default: **night-owl** (configured in `colors.lua`)

Available: rose-pine, gruvbox, nord

## Dependencies

- Neovim 0.9+
- Nerd Font (for icons)
- ripgrep (for telescope grep)
- fd (for telescope find)
- Node.js (for some LSPs)
