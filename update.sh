#!/bin/sh
set -e
_PWD=$PWD
cd $HOME/.dotfile
git pull origin master --rebase || echo "No changes"
git submodule init
git submodule update
nvim -c 'PlugInstall|qa!'
nvim -c 'CocInstall -sync coc-explorer coc-git coc-highlight coc-html coc-json coc-lists coc-pyright coc-yaml|qa!'
cd $_PWD
