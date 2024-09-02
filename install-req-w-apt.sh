#!/usr/bin/sh

set -e
sudo apt update
sudo apt install curl -y
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# install nodejs, yarnpkg, zsh, tmux, git, ripgrep, fzf
sudo apt install zsh tmux git ripgrep fzf -y

# download newest nvim from https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
INSTALL_DIR="/opt/nvim"
curl -LO $NVIM_URL
sudo mkdir -p $INSTALL_DIR
sudo tar xzf nvim-linux64.tar.gz -C $INSTALL_DIR --strip-components=1
sudo ln -sf $INSTALL_DIR/bin/nvim /usr/local/bin/nvim
sudo ln -sf $INSTALL_DIR/bin/nvim /usr/local/bin/vim
rm nvim-linux64.tar.gz
echo "nvim installed to /usr/local/bin/nvim"
