#!/bin/sh
BACKUP_DIR=$PWD/backup/$(date +"%Y%m%d_%H%M%S")

mkdir -p $BACKUP_DIR/git
mkdir -p $BACKUP_DIR/.config
mkdir -p $BACKUP_DIR/.local/bin

mkdir -p $HOME/.cache/vimundo
mkdir -p $HOME/.config
mkdir -p $HOME/.local/bin

targets=".oh-my-zsh .zshrc .vim .vimrc .vimrc.before.local .config/coc .tmux .tmux.conf .profile .local/bin/docker-clean"

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

