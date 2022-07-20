call plug#begin('~/.vim/plugged')
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'farmergreg/vim-lastplace'
Plug 'preservim/nerdcommenter'  " 快速注释
Plug 'nathanaelkane/vim-indent-guides' " 缩进高亮显示
Plug 'ryanoasis/vim-devicons' " icons
Plug 'tomasiser/vim-code-dark' " 主题
Plug 'roxma/vim-paste-easy' " set paste mode automatically
Plug 'github/copilot.vim'
Plug 'easymotion/vim-easymotion'
Plug 'wellle/targets.vim'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

call plug#end()

colorscheme codedark
let g:airline_theme = 'codedark'
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

set background=dark
set encoding=UTF-8
set nocompatible
set belloff=all
set hlsearch " 高亮搜索
set undofile " 保留撤销历史
set undodir=$HOME/.cache/vimundo " 历史文件不要保存在项目目录
set directory=$HOME/.cache/vimswp " 交换文件不要保存在项目目录
set backupdir=$HOME/.cache/vimbackup " 备份文件不要保存在项目目录
set number " 当前行号
set relativenumber " 相对行号
set cursorline " 高亮光标所在行
set nowrap
set colorcolumn=88,120 " 代码宽度标尺
set timeoutlen=350 " 连击等待时间200ms

let cwd = getcwd()

" yank to/put from system clipboard
if has('unnamedplus')
	set clipboard=unnamedplus " Linux with X11
else
	set clipboard=unnamed " others
endif


" format python buffer on save
function FormatPy(time)
	:let clipboard_save = &clipboard
	":let g:winview = winsaveview()
	:noa w
	:call CocAction('runCommand', 'editor.action.organizeImport')
	"exe 'sleep 1'
	:noa w
	:call CocAction('format')
	:silent! %s#\($\n\s*\)\+\%$##  " remove tail new line
	:let &clipboard = clipboard_save
	":call winrestview(g:winview)
	:noa w
endfunction

autocmd BufWritePre *.py :call timer_start(1, function('FormatPy', []))
"autocmd BufWritePost *.py :call winrestview(g:winview)

" write buffer to file by su
function SuWrite()
	:w !sudo tee % > /dev/null
	:edit!
	call feedkeys("<CR>")
endfunction
cmap w!! exec SuWrite()

" colors indents like a zebra
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_auto_colors = 0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  ctermbg=234
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=235

"key map
imap <C-j> <down>
imap <C-k> <up>
imap <C-h> <left>
imap <C-l> <right>

nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-h> <C-w>h
nmap <C-l> <C-w>l

nmap <C-n> :CocNext<CR>
nmap <C-p> :CocPrev<CR>

function ApplyThenWrite()
	call feedkeys(".")
	call timer_start(20, function("FormatPy", []))
endfunction
nmap <C-s> :call ApplyThenWrite()<CR>

nnoremap <silent> <C-g> :exe 'CocList -I --input='.expand('<cword>').' grep -w'<CR>
nnoremap <silent> <C-g><C-g> :exe 'CocList -I --input='.expand('<cword>').' grep'<CR>

nmap <C-f> :CocList mru<CR>
nmap <C-f><C-f> :CocList files<CR>

nmap <C-e> :CocCommand explorer<CR>
nmap <C-\> :CocCommand<CR>
"nmap <C-r> <Plug>(coc-rename)

nmap <C-j>d :call CocAction('jumpDefinition')<CR>
nmap <C-j>r :call CocAction('jumpReferences')<CR>

nmap <C-x><C-x> <plug>NERDCommenterToggle
vmap <C-x> <plug>NERDCommenterToggle gv
vmap > >gv
vmap < <gv

" Use space to show documentation in preview window
nnoremap <silent> <space> :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction
