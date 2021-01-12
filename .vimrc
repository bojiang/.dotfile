call plug#begin('~/.vim/plugged')
Plug 'neoclide/coc.nvim', {'branch': 'release'}
"Plug 'rking/ag.vim'
Plug 'farmergreg/vim-lastplace'
Plug 'mhinz/vim-startify'  " 最近打开文件
Plug 'preservim/nerdcommenter'  " 快速注释
Plug 'nathanaelkane/vim-indent-guides' " 缩进高亮显示
Plug 'ryanoasis/vim-devicons' " icons
Plug 'tomasiser/vim-code-dark' " 主题
call plug#end()

colorscheme codedark
set background=dark
set encoding=UTF-8
set nocompatible
set belloff=all
set hlsearch " 高亮搜索
set undofile " 保留撤销历史
set undodir=$HOME/.cache/vimundo " 历史文件不要保存在项目目录
set number " 当前行号
set relativenumber " 相对行号
set cursorline
set nowrap
set nobackup " 不创建备份文件
set noswapfile " 不创建交换文件
set colorcolumn=88,120

" yank to/put from system clipboard
if has('unnamedplus')
	set clipboard=unnamedplus " Linux with X11
else
	set clipboard=unnamed " others
endif

" format python buffer on save
function FormatPy()
	:let g:winview = winsaveview()
	:noa w
	:call CocAction('runCommand', 'editor.action.organizeImport')
	exe 'sleep 1'
	:noa w
	:call CocAction('format')
	:silent! %s#\($\n\s*\)\+\%$##  " remove tail new line
endfunction
autocmd BufWritePre *.py exec FormatPy()
autocmd BufWritePost *.py :call winrestview(g:winview)

" write buffer to file by su
function SuWrite()
	:w !sudo tee % > /dev/null
	:edit!
	call feedkeys("<CR>")
endfunction
cmap w!! exec SuWrite()

" start page
let g:startify_lists = [
        \ { 'type': 'dir',       'header': ['   MRU '. getcwd()] },
        \ { 'type': 'files',     'header': ['   MRU']            },
        \ { 'type': 'sessions',  'header': ['   Sessions']       },
        \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      },
        \ ]
let g:startify_change_to_dir = 0

let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_auto_colors = 0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  ctermbg=234
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=235

"key map
let mapleader = ","

imap <C-j> <down>
imap <C-k> <up>
imap <C-h> <left>
imap <C-l> <right>

nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-h> <C-w>h
nmap <C-l> <C-w>l

nmap <C-n> :cn<CR>
nmap <C-p> :cp<CR>

"nmap <C-g> :Ag! -w <cword><CR>
nnoremap <silent> <C-g> :exe 'CocList -I --input='.expand('<cword>').' grep'<CR>
nmap <C-f> :CocList files<CR>
nmap <C-m> :CocList mru<CR>
nmap <C-e> :CocCommand explorer<CR>
nmap <C-\> :CocCommand<CR>

nmap <C-j>d :call CocAction('jumpDefinition')<CR>
nmap <C-j>r :call CocAction('jumpReferences')<CR>

nmap <C-x><C-x> <plug>NERDCommenterToggle
vmap <C-x> <plug>NERDCommenterToggle gv
vmap > >gv
vmap < <gv

