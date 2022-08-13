#!/bin/bash
set -e
_PWD=$PWD

if [ ! -f $PWD/.dotfile_flag ] ; then
	if [ ! -f $HOME/.dotfile/.dotfile_flag ] ; then
		echo "please make sure .dotfile is in your HOME directory"
		exit 1
	else
		cd $HOME/.dotfile
	fi
fi

if [[ $(tmux -V 2>&1 | grep -Po '(?<=tmux )(.+)') < "3.0a" ]] ; then
	echo ".dotfile requires tmux>=3.0a"
	exit 1
fi

BACKUP_DIR=$PWD/backup/$(date +"%Y%m%d_%H%M%S")

mkdir -p $BACKUP_DIR/git
mkdir -p $BACKUP_DIR/.config
mkdir -p $BACKUP_DIR/.local/bin

mkdir -p $HOME/.cache/vimundo
mkdir -p $HOME/.config
mkdir -p $HOME/.local/bin

targets=".oh-my-zsh .zshrc .vim .vimrc .vimrc.before.local .config/coc .config/nvim .tmux .tmux.conf .profile .local/bin/docker-clean"

for target in $targets; do
	[ -e $HOME/$target -o -L $HOME/$target ] && mv $HOME/$target $BACKUP_DIR/$target
done

[ -e $HOME/.gitignore ] && mv $HOME/.gitignore $BACKUP_DIR/git/.gitignore
[ -e $HOME/.gitconfig ] && mv $HOME/.gitconfig $BACKUP_DIR/git/.gitconfig


for target in $targets; do
	ln -s $PWD/$target $HOME/$target
done

ln -s $PWD/git/.gitignore $HOME/.gitignore
ln -s $PWD/git/.gitconfig $HOME/.gitconfig

git submodule init
git submodule update

nvim -c 'PlugInstall|qa!'
nvim -c 'CocInstall -sync coc-explorer coc-git coc-highlight coc-json coc-lists coc-pyright coc-yaml|qa!'
yarnpkg cache clean

cd $_PWD
echo "done"
