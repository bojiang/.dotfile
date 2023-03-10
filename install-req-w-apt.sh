#!/usr/bin/sh
sudo apt update
sudo apt install curl -y
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt update
sudo apt install nodejs yarnpkg zsh tmux git ripgrep fzf neovim -y
