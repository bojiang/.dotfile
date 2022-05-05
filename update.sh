#!/bin/sh
set -e
_PWD=$PWD
cd $HOME/.dotfile
git pull origin master --rebase || echo ".dotfile: main repo updating failed"
git submodule init
git submodule update
nvim -c 'PlugUpdate|qa!'
nvim -c 'CocUpdateSync|qa!'
cd $_PWD
