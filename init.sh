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

#if [[ $(tmux -V 2>&1 | grep -Po '(?<=tmux )(.+)') < "3.0a" ]] ; then
	#echo ".dotfile requires tmux>=3.0a"
	#exit 1
#fi

BACKUP_DIR=$PWD/backup/$(date +"%Y%m%d_%H%M%S")

mkdir -p $BACKUP_DIR/git
mkdir -p $BACKUP_DIR/.config
mkdir -p $BACKUP_DIR/.claude
mkdir -p $BACKUP_DIR/.claude/hooks
mkdir -p $BACKUP_DIR/.codex
mkdir -p $BACKUP_DIR/.local/bin

mkdir -p $HOME/.cache/vimundo
mkdir -p $HOME/.config
mkdir -p $HOME/.local/bin
mkdir -p $HOME/.claude
mkdir -p $HOME/.codex

targets=".oh-my-zsh .config/nvim .tmux .tmux.conf .profile .local/bin/docker-clean"

for target in $targets; do
	[ -e $HOME/$target -o -L $HOME/$target ] && mv $HOME/$target $BACKUP_DIR/$target
done

[ -e $HOME/.gitignore -o -L $HOME/.gitignore ] && mv $HOME/.gitignore $BACKUP_DIR/git/.gitignore
[ -e $HOME/.gitconfig -o -L $HOME/.gitconfig ] && mv $HOME/.gitconfig $BACKUP_DIR/git/.gitconfig
[ -e $HOME/.claude/CLAUDE.md -o -L $HOME/.claude/CLAUDE.md ] && mv $HOME/.claude/CLAUDE.md $BACKUP_DIR/.claude/CLAUDE.md
[ -e $HOME/.codex/AGENTS.md -o -L $HOME/.codex/AGENTS.md ] && mv $HOME/.codex/AGENTS.md $BACKUP_DIR/.codex/AGENTS.md
[ -e $HOME/.codex/hooks.json -o -L $HOME/.codex/hooks.json ] && mv $HOME/.codex/hooks.json $BACKUP_DIR/.codex/hooks.json


for target in $targets; do
	ln -s $PWD/$target $HOME/$target
done

ln -s $PWD/git/.gitignore $HOME/.gitignore
ln -s $PWD/git/.gitconfig $HOME/.gitconfig
ln -s $PWD/.claude/CLAUDE.md $HOME/.claude/CLAUDE.md
ln -s $PWD/.claude/CLAUDE.md $HOME/.codex/AGENTS.md
ln -s $PWD/.codex/hooks.json $HOME/.codex/hooks.json
[ -e $HOME/.claude/hooks -o -L $HOME/.claude/hooks ] && mv $HOME/.claude/hooks $BACKUP_DIR/.claude/hooks
ln -s $PWD/.claude/hooks $HOME/.claude/hooks
[ -e $HOME/.claude/agents -o -L $HOME/.claude/agents ] && mv $HOME/.claude/agents $BACKUP_DIR/.claude/agents
ln -s $PWD/.claude/agents $HOME/.claude/agents
[ -e $HOME/.claude/settings.json -o -L $HOME/.claude/settings.json ] && mv $HOME/.claude/settings.json $BACKUP_DIR/.claude/settings.json
ln -s $PWD/.claude/settings.json $HOME/.claude/settings.json

# .zshrc is a local file (not a symlink) so host-side edits don't pollute the template.
[ -e $HOME/.zshrc -o -L $HOME/.zshrc ] && mv $HOME/.zshrc $BACKUP_DIR/.zshrc
cp $PWD/zshrc.template $HOME/.zshrc

git submodule init
git submodule update

cd $_PWD
echo "done"
