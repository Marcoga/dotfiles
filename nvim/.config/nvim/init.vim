set scrolloff=16
set signcolumn=yes
set relativenumber
set number
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set smartindent
set ignorecase
set smartcase
set hidden
set noerrorbells
set nohlsearch
set noswapfile
set incsearch
set colorcolumn=120
set autoread

" add copilot shortcuts
nnoremap <leader>cc :Copilot<CR>
nnoremap <leader>cs :CopilotStop<CR>
imap <silent> <C-j> <Plug>(copilot-next)
imap <silent> <C-k> <Plug>(copilot-previous)

set wildmode=longest,list,full
set wildmenu
" Ignore files
set wildignore+=*.pyc
set wildignore+=*_build/*
set wildignore+=**/coverage/*
set wildignore+=**/node_modules/*
set wildignore+=**/android/*
set wildignore+=**/ios/*
set wildignore+=**/.git/*

let mapleader =" "
nnoremap <leader>pv :Vex<CR>
nnoremap <leader><CR> :so ~/.config/nvim/init.vim<CR>
nnoremap <leader>x :silent !chmod +x %<CR>
vnoremap <leader>y "+y
nnoremap <leader>y "+yiw

" Find files using Telescope command-line sugar.
nnoremap <leader>f <cmd>Telescope find_files<cr>
nnoremap <leader>e <cmd>Telescope git_files<cr>
nnoremap <leader>o <cmd>Telescope buffers<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope git_branches<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
noremap <leader>8 <cmd>Telescope grep_string<cr>
noremap <leader>fr <cmd>Telescope registers<cr>
nnoremap <leader>fe :GFiles<CR>
nnoremap <leader>ff :Files<CR>
inoremap <silent><leader>fr <cmd>lua require'telescope.builtin'.registers(require('telescope.themes').get_cursor({}))<cr>

" Harpoon shortcuts
nnoremap <leader>hh <cmd>:lua require("harpoon.mark").add_file()<cr>
nnoremap <leader>h <cmd>lua require("harpoon.ui").toggle_quick_menu()<cr>
nnoremap <leader>hk <cmd>lua require("harpoon.ui").nav_prev()<cr>
nnoremap <leader>hj <cmd>lua require("harpoon.ui").nav_next()<cr>

" Quickfix
nnoremap <leader>co :copen<CR>
nnoremap <leader>cn :cnext<CR>
nnoremap <leader>cp :cprevious<CR>

" Buffers
"nnoremap <leader>o :Buffers<CR>
nnoremap <leader>. :bnext<CR>
nnoremap <leader>, :bprevious<CR>
nnoremap <leader>w :bdelete<CR>
nnoremap <leader>` :bdelete!<CR>
nnoremap <leader>s :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>fq :qa!<CR>

" Git
noremap <Leader>ga :Gwrite<CR>
noremap <Leader>gc :Git commit --verbose<CR>
noremap <Leader>gsh :Git push<CR>
noremap <Leader>gll :Git pull<CR>
noremap <Leader>gs :Git<CR>
noremap <Leader>gb :Git blame<CR>
noremap <Leader>gd :Gvdiffsplit<CR>
noremap <Leader>gx :GRemove<CR>
noremap <Leader>gp :Git -c push.default=current push<CR>

"" Open current line on GitHub
nnoremap <Leader>gh :.GBrowse<CR>

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gr <Plug>(coc-references)
inoremap <silent><expr> <c-space> coc#refresh()
nmap <silent> <leader>[ <Plug>(coc-diagnostic-prev)
nmap <silent> <leader>] <Plug>(coc-diagnostic-next)
nnoremap <silent> <leader>d :<C-u>CocList diagnostics<cr>
nmap <leader>do <Plug>(coc-codeaction)
nmap <leader>rn <Plug>(coc-rename)

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

call plug#begin('~/.vim/plugged')

Plug 'ayu-theme/ayu-vim'
Plug 'haishanh/night-owl.vim'
Plug 'mhartington/oceanic-next'
Plug 'easymotion/vim-easymotion'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'ThePrimeagen/harpoon'

Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-treesitter/playground'

Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'
Plug 'pangloss/vim-javascript'
Plug 'jparise/vim-graphql'

Plug 'neoclide/coc.nvim', {'branch': 'release'}
let g:coc_global_extensions = [
          \ 'coc-tsserver'
  \ ]

Plug 'prettier/vim-prettier', { 'do': 'yarn install --frozen-lockfile --production' }

Plug 'neovim/nvim-lspconfig'
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'jose-elias-alvarez/nvim-lsp-ts-utils'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb' " required by fugitive to :Gbrowse
Plug 'airblade/vim-gitgutter'

Plug 'github/copilot.vim'

call plug#end()

let g:coc_global_extensions += ['coc-prettier']
let g:coc_global_extensions += ['coc-eslint']

"command! -nargs=0 Prettier :CocCommand prettier.formatFile
command! -nargs=0 Prettier :call CocAction('runCommand', 'prettier.formatFile')
let g:prettier#autoformat = 1

" set filetypes as typescriptreact
autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescriptreact


set termguicolors     " enable true colors support
let $NVIM_TUI_ENABLE_TRUE_COLOR=1
"let ayucolor="light"  " for light version of theme
"let ayucolor="mirage" " for mirage version of theme
"let ayucolor="da/Users/mgarcia/dream-tracker.md rk"   " for dark version of theme
syntax enable
colorscheme night-owl
"let g:lightline = { 'colorscheme': 'nightowl' }

" dark red
hi tsxTagName guifg=#E06C75
hi tsxComponentName guifg=#E06C75
hi tsxCloseComponentName guifg=#E06C75
"
" " orange
hi tsxCloseString guifg=#F99575
hi tsxCloseTag guifg=#F99575
hi tsxCloseTagName guifg=#F99575
hi tsxAttributeBraces guifg=#F99575
hi tsxEqual guifg=#F99575
"
" " yellow
hi tsxAttrib guifg=#F8BD7F cterm=italic

" light-grey
hi tsxTypeBraces guifg=#999999
" " dark-grey
hi tsxTypes guifg=#666666
