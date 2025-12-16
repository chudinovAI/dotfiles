syntax on
set background=dark
au BufWrite /private/tmp/crontab.* set nowritebackup nobackup
au BufWrite /private/etc/pw.* set nowritebackup nobackup
highlight LineNr ctermfg=NONE guifg=NONE
highlight CursorLineNr ctermfg=NONE guifg=NONE 
set tabstop=4
set shiftwidth=2
set expandtab
set ai
set mouse=a
set number
set relativenumber
set numberwidth=1
set hlsearch
set ruler
highlight Comment ctermfg=green
set wrap
set linebreak
set title
set titlestring=%t%m
