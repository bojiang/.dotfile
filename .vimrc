call plug#begin('~/.vim/plugged')
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'farmergreg/vim-lastplace'
Plug 'preservim/nerdcommenter'  " 快速注释
Plug 'nathanaelkane/vim-indent-guides' " 缩进高亮显示
Plug 'ryanoasis/vim-devicons' " icons
Plug 'tomasiser/vim-code-dark' " 主题
Plug 'roxma/vim-paste-easy' " set paste mode automatically
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
set cursorline " 高亮光标所在行
set nowrap
set nobackup " 不创建备份文件
set noswapfile " 不创建交换文件
set colorcolumn=88,120 " 代码宽度标尺
set timeoutlen=350 " 连击等待时间200ms

let cwd = getcwd()

" yank to/put from system clipboard
if has('unnamedplus')
	set clipboard=unnamedplus " Linux with X11
else
	set clipboard=unnamed " others
endif

" coc.nvim extensions
let g:coc_global_extensions = [
	\ "coc-explorer", "coc-git", "coc-highlight", "coc-html", "coc-json",
	\ "coc-lists", "coc-prettier", "coc-pyright", "coc-rls", "coc-rust-analyzer",
	\ "coc-snippets", "coc-tabnine", "coc-yaml"]

" format python buffer on save
function FormatPy()
	:let clipboard_save = &clipboard
	:let g:winview = winsaveview()
	:noa w
	:call CocAction('runCommand', 'editor.action.organizeImport')
	exe 'sleep 1'
	:noa w
	:call CocAction('format')
	:silent! %s#\($\n\s*\)\+\%$##  " remove tail new line
	:let &clipboard = clipboard_save
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

nnoremap <silent> <C-g> :exe 'CocList -I --input='.expand('<cword>').' grep -w'<CR>
nnoremap <silent> <C-g><C-g> :exe 'CocList -I --input='.expand('<cword>').' grep'<CR>

nmap <C-f> :CocList mru<CR>
nmap <C-f><C-f> :CocList files<CR>

nmap <C-e> :CocCommand explorer<CR>
nmap <C-\> :CocCommand<CR>

nmap <C-j>d :call CocAction('jumpDefinition')<CR>
nmap <C-j>r :call CocAction('jumpReferences')<CR>

nmap <C-x><C-x> <plug>NERDCommenterToggle
vmap <C-x> <plug>NERDCommenterToggle gv
vmap > >gv
vmap < <gv

