from debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends --no-install-suggests \
yarnpkg tmux zsh git neovim ripgrep fzf sudo

ARG USER="agent"

RUN useradd -m -s /usr/bin/zsh -G sudo $USER 

ADD --chown=$USER:sudo . /home/$USER/.dotfile/
RUN sudo -u $USER /home/$USER/.dotfile/init.sh

RUN apt-get update && apt-get install -y --no-install-recommends --no-install-suggests \
gpg ssh wget

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.11.0-Linux-x86_64.sh
RUN chmod +x Miniconda3-py38_4.11.0-Linux-x86_64.sh && \
	sudo -u $USER mkdir -p /home/$USER/.dotfile/tool && \
	sudo -u $USER ./Miniconda3-py38_4.11.0-Linux-x86_64.sh -b -p /home/$USER/.dotfile/tool/miniconda && \
	rm Miniconda3-py38_4.11.0-Linux-x86_64.sh && \
	sudo -u $USER /home/$USER/.dotfile/tool/miniconda/bin/conda update -y conda && \
	sudo -u $USER /home/$USER/.dotfile/tool/miniconda/bin/conda init zsh


WORKDIR /home/$USER
USER $USER
CMD ["/usr/bin/zsh"]
