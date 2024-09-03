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

# python?
read -p "是否安装Python语言支持？(y/n) " install_python

if [ "$install_python" = "y" ]; then
    echo "正在安装Python语言支持..."
    sudo apt install npm -y
    sudo npm install -g pyright
    echo "Python语言支持已安装"
else
    echo "跳过Python语言支持安装"
fi

# lua?
read -p "是否安装Lua语言支持？(y/n) " install_lua

if [ "$install_lua" = "y" ]; then
    echo "正在安装Lua语言支持..."
    LUA_LS_URL="https://github.com/LuaLS/lua-language-server/releases/download/3.10.5/lua-language-server-3.10.5-linux-x64.tar.gz"
    LUA_LS_DIR="/opt/lua-language-server"
    curl -LO $LUA_LS_URL
    sudo mkdir -p $LUA_LS_DIR
    sudo tar xzf lua-language-server-3.10.5-linux-x64.tar.gz -C $LUA_LS_DIR
    sudo ln -sf $LUA_LS_DIR/bin/lua-language-server /usr/local/bin/lua-language-server
    rm lua-language-server-3.10.5-linux-x64.tar.gz
    echo "Lua语言支持已安装"
else
    echo "跳过Lua语言支持安装"
fi
