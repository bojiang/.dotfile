#!/bin/sh
_PWD=$PWD
cd $HOME/.dotfile
git pull origin master --rebase
git submodule init
git submodule update
cd $HOME/.dotfile/.config/coc/extensions
npm install
cd $_PWD

