
fpath=(~/.zsh/completion $fpath)
# If you come from bash you might have to change your $PATH.

export ZSH=$HOME/.oh-my-zsh
[[ -e ~/.zprofile ]] && source ~/.zprofile

if [ -f $HOME/.dotfile/custom/zshrc ]; then
	source $HOME/.dotfile/custom/zshrc
fi
ZSH_THEME="robbyrussell"

CASE_SENSITIVE="true"

DISABLE_AUTO_UPDATE="true"

export ZSH_AI_COMMANDS_HOTKEY='^I^I^I'
export ZSH_CUSTOM=$HOME/.dotfile/oh_my_zsh_custom

if [[ "$OSTYPE" == "darwin"* ]]; then
    export PATH=/opt/homebrew/bin:/Users/agent/Library/Python/3.9/bin/:$PATH
fi

export ZSH_AI_COMMANDS_OPENAI_API_KEY=$OPENAI_API_KEY

alias vim=nvim

plugins=(git kubectl docker zsh-interactive-cd systemd zsh-ai-commands)

source $ZSH/oh-my-zsh.sh

# docker
alias dls="docker container list"
alias dr="docker container restart "
alias dx="docker container stop "
alias dclean="docker-clean images"
alias dlog="docker logs "

# git & github
alias gu='function _blah(){
	git config user.name "$1"
	git config user.email "$2"

	KEYS=$(gpg --list-keys)
	echo $KEYS

	if [[ $? == 0 ]] && [[ $KEYS =~ .*$2.* ]]
	then
		git config user.signkey "$2"
		git config commit.gpgsign true
		echo "you are $1($2) now [with key]"
	else
		echo "you are $1($2) now"
	fi
};_blah'

alias gs="git --no-pager branch;git --no-pager log --decorate=short --pretty=oneline -n 5;git status"
alias gc="git commit --all -v"
alias gca="git commit --all --amend -v"
alias gck="git checkout "
alias gcap="gca --no-edit;gp"
alias gbcl="git branch --merged | xargs git branch -d"

alias gp='function _blah(){
	ORIGIN="$(git remote get-url origin)"
	if [[ $ORIGIN =~ ^git@([^:]+):([^/]+)/(.+)\.git$ ]]; then
	    # SSH 格式: git@server:namespace/repo.git
	    SERVER=${BASH_REMATCH[1]}
	    NAMESPACE=${BASH_REMATCH[2]}
	    REPO=${BASH_REMATCH[3]}
	elif [[ $ORIGIN =~ ^https?://([^/]+)/([^/]+)/(.+)\.git$ ]]; then
	    # HTTPS 格式: https://server/namespace/repo.git
	    SERVER=${BASH_REMATCH[1]}
	    NAMESPACE=${BASH_REMATCH[2]}
	    REPO=${BASH_REMATCH[3]}
	else
	    echo "无法识别的 remote URL 格式: $ORIGIN"
	    return
	fi

	if [[ -z $1 ]] || [[ $1 == "-"* ]]
	then
		echo "git push origin HEAD $@"
		git push origin HEAD $@
	elif [[ $1 != "-"* ]] && ( [[ -z $2 ]] || [[ $2 == "-"* ]])
	then
		IFS=":" read -r REMOTE BRANCH <<< "$1"
		shift
		if [[ -z $BRANCH ]]
		then
			BRANCH=$REMOTE
			echo "git push origin HEAD:$BRANCH $@"
			git push origin HEAD:$BRANCH $@
		else
			if git remote get-url $REMOTE > /dev/null 2>&1
			then
				echo "git push $REMOTE HEAD:$BRANCH $@"
				git push $REMOTE HEAD:$BRANCH $@
			else
				echo "git push $SERVER$REMOTE/$REPO HEAD:$BRANCH $@"
				git push $SERVER$REMOTE/$REPO HEAD:$BRANCH $@
			fi
		fi
	else
		echo "usage: gp [remote:]branch --options"
	fi
};_blah'

alias grc="git rebase --continue"
alias gra="git rebase --abort"
alias gr='function _blah(){
	ORIGIN="$(git remote get-url origin)"
	if [[ $ORIGIN =~ ^git@([^:]+):([^/]+)/(.+)\.git$ ]]; then
	    # SSH 格式: git@server:namespace/repo.git
	    SERVER=${BASH_REMATCH[1]}
	    NAMESPACE=${BASH_REMATCH[2]}
	    REPO=${BASH_REMATCH[3]}
	elif [[ $ORIGIN =~ ^https?://([^/]+)/([^/]+)/(.+)\.git$ ]]; then
	    # HTTPS 格式: https://server/namespace/repo.git
	    SERVER=${BASH_REMATCH[1]}
	    NAMESPACE=${BASH_REMATCH[2]}
	    REPO=${BASH_REMATCH[3]}
	else
	    echo "无法识别的 remote URL 格式: $ORIGIN"
	    return
	fi

	if [[ -z $1 ]] || [[ $1 == "-"* ]]
	then
		echo "git pull origin main --rebase $@"
		git pull origin main --rebase $@
	elif [[ $1 != "-"* ]] && ( [[ -z $2 ]] || [[ $2 == "-"* ]])
	then
		IFS=":" read -r REMOTE BRANCH <<< "$1"
		shift
		if [[ -z $BRANCH ]]
		then
			BRANCH=$REMOTE
			echo "git pull origin $BRANCH --rebase $@"
			git pull origin $BRANCH --rebase $@
		else
			if git remote get-url $REMOTE > /dev/null 2>&1
			then
				echo "git pull $REMOTE $BRANCH --rebase $@"
				git pull $REMOTE $BRANCH --rebase $@
			else
				echo "git pull $SERVER$REMOTE/$REPO $BRANCH --rebase $@"
				git pull $SERVER$REMOTE/$REPO $BRANCH --rebase $@
			fi
		fi
	else
		echo "usage gr [remote:]branch --options"
	fi
};_blah'

OMZ_PROMPT="$PROMPT"
# shell
# PROMPT='$USER $([ -d .git ] && echo "git:"$(git config user.name)"("$(git rev-parse --abbrev-ref HEAD 2>/dev/null)") ")'"${OMZ_PROMPT}"
PROMPT='$([ -d .git ] && echo " "$(git config user.name)" ")'"${OMZ_PROMPT}"
alias di="echo -ne '\007'"
export TERM=xterm-256color

# dotfile
alias dotupdate='$HOME/.dotfile/update.sh'

# more completion
if [ $commands[gh] ]; then
	source <(gh completion --shell zsh)
	compdef _gh gh
	#compdump
fi
export PATH=$HOME/.dotfile/tool/docker-clean:$PATH

# pnpm
export PNPM_HOME="/home/agent/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Function to activate virtual environment
activate_venv() {
    if [[ -d ".venv" ]]; then
        source .venv/bin/activate
    fi
}

# Activate venv in the current directory
activate_venv

# Auto-activate venv when changing directories
autoload -U add-zsh-hook
add-zsh-hook chpwd activate_venv

# Hook for uv venv creation
uv_venv() {
    if [[ "$1" == "venv" ]]; then
        command uv venv "${@:2}"
        activate_venv
    else
        command uv "$@"
    fi
}
alias uv=uv_venv
