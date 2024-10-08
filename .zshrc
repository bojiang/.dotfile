# If you come from bash you might have to change your $PATH.

export ZSH=$HOME/.oh-my-zsh
[[ -e ~/.zprofile ]] && source ~/.zprofile

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(fzf git kubectl docker zsh-interactive-cd systemd kube-ps1)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

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
	if [[ $ORIGIN =~ "((git@[a-Z0-9\.\-]+:)|(https?:\/\/[a-Z0-9\.\-]+\/))([a-Z0-9\-]+)\/([a-Z0-9\.\-]+\.git)" ]]
	then
		SERVER=$match[1]
		NAMESPACE=$match[4]
		REPO=$match[5]
	else
		echo "$ORIGIN"
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
	if [[ $ORIGIN =~ "((git@[a-Z0-9\.\-]+:)|(https?:\/\/[a-Z0-9\.\-]+\/))([a-Z0-9\-]+)\/([a-Z0-9\.\-]+\.git)" ]]
	then
		SERVER=$match[1]
		NAMESPACE=$match[4]
		REPO=$match[5]
	else
		echo "origin is not a valid git remote url: $ORIGIN"
		return 1
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

# dotfile
alias dotupdate='$HOME/.dotfile/update.sh'
if [ -f $HOME/.dotfile/custom/zshrc ]; then
	source $HOME/.dotfile/custom/zshrc
fi

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
