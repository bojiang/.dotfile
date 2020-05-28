#!/bin/sh
BACKUP_DIR=$PWD/backup/$(date +"%Y%m%d_%H%M%S")
mkdir -p $BACKUP_DIR/git
mkdir -p $BACKUP_DIR/.config

mv $HOME/.oh-my-zsh $BACKUP_DIR/.oh-my-zsh
mv $HOME/.zshrc $BACKUP_DIR/.zshrc
mv $HOME/.zprofile $BACKUP_DIR/.zprofile

mv $HOME/.vim $BACKUP_DIR/.vim
mv $HOME/.vimrc $BACKUP_DIR/.vimrc
mv $HOME/.vimrc.before.local $BACKUP_DIR/.vimrc.before.local
mv $HOME/.config/coc $BACKUP_DIR/.config/coc

mv $HOME/.tmux $BACKUP_DIR/.tmux
mv $HOME/.tmux.conf $BACKUP_DIR/.tmux.conf

mv $HOME/.profile $BACKUP_DIR/.profile

mv $HOME/.gitignore $BACKUP_DIR/git/.gitignore
mv $HOME/.gitconfig $BACKUP_DIR/git/.gitconfig

mkdir -p $HOME/.cache/vimundo
mkdir -p $HOME/.config

ln -s $PWD/.oh-my-zsh $HOME/.oh-my-zsh
ln -s $PWD/.zshrc $HOME/.zshrc
ln -s $PWD/.zprofile $HOME/.zprofile

ln -s $PWD/.vim $HOME/.vim
ln -s $PWD/.vimrc $HOME/.vimrc
ln -s $PWD/.vimrc.before.local $HOME/.vimrc.before.local
ln -s $PWD/.config/coc $HOME/.config/coc


ln -s $PWD/.tmux $HOME/.tmux
ln -s $PWD/.tmux.conf $HOME/.tmux.conf

ln -s $PWD/.profile $HOME/.profile

ln -s $PWD/git/.gitignore $HOME/.gitignore
ln -s $PWD/git/.gitconfig $HOME/.gitconfig

mkdir -p $HOME/.local/bin
ln -s $PWD/tool/docker-clean/docker-clean $HOME/.local/bin/docker-clean

