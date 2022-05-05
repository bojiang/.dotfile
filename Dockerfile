from debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends --no-install-suggests \
yarnpkg tmux zsh git neovim ripgrep fzf sudo

ENV USER="agent"
RUN useradd -m -s /usr/bin/zsh -G sudo $USER

USER $USER
WORKDIR /home/$USER
ADD --chown=$USER:sudo . /home/$USER/.dotfile/
#RUN git clone https://github.com/bojiang/.dotfile.git
WORKDIR /home/$USER/.dotfile
RUN ./init.sh
RUN ./update.sh

WORKDIR /home/$USER
CMD ["/usr/bin/zsh"]
