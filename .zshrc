
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

export SMART_SUGGESTION_DEBUG=true

# ai tools
alias cc="ANTHROPIC_API_KEY=sk-dummy ANTHROPIC_BASE_URL=http://localhost:4141 claude --dangerously-skip-permissions"

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

	# SSH key configuration
	if [[ "$1" == "a0gent" ]]; then
		git config core.sshCommand "ssh -i ~/.ssh/id_ed25519"
		echo "SSH key: ~/.ssh/id_ed25519"
	else
		git config --unset core.sshCommand 2>/dev/null || true
		echo "SSH key: default"
	fi

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

alias m4a2mp3='function _blah(){
	for f in *.m4a; do
		ffmpeg -i "$f" -codec:a libmp3lame -b:a 320k "${f%.m4a}.mp3"
	done
};_blah'

alias mp42mp3='function _blah(){
	local mp4_files=(*.mp4)
	if [[ ! -f "${mp4_files[0]}" ]]; then
		echo "No MP4 files found in current directory."
		return
	fi

	local total=${#mp4_files[@]}
	local max_concurrent=8
	local temp_dir=$(mktemp -d)
	local pids=()

	echo "Converting $total MP4 files to MP3 (max $max_concurrent concurrent)..."
	echo "Start time: $(date)"

	for file in "${mp4_files[@]}"; do
		while (( ${#pids[@]} >= max_concurrent )); do
			for i in "${!pids[@]}"; do
				if ! kill -0 "${pids[i]}" 2>/dev/null; then
					unset "pids[i]"
				fi
			done
			pids=("${pids[@]}")
			[[ ${#pids[@]} -ge $max_concurrent ]] && sleep 0.1
		done

		(
			output="${file%.mp4}.mp3"
			if ffmpeg -i "$file" -vn -acodec mp3 -ab 192k -ar 44100 -y "$output" 2>/dev/null; then
				echo "✓ $(date +%T) Success: $output" | tee "$temp_dir/success_$$.log"
			else
				echo "✗ $(date +%T) Failed: $file" | tee "$temp_dir/failed_$$.log"
			fi
		) &
		pids+=($!)
		echo "Started: $file (PID: $!)"
	done

	echo "Waiting for all conversions to complete..."
	wait

	local success_count=$(find "$temp_dir" -name "success_*.log" 2>/dev/null | wc -l)
	local failed_count=$(find "$temp_dir" -name "failed_*.log" 2>/dev/null | wc -l)

	echo "=== Conversion Summary ==="
	echo "Total files: $total"
	echo "Successful: $success_count"
	echo "Failed: $failed_count"
	echo "End time: $(date)"

	rm -rf "$temp_dir"
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

# tmux
alias t='tmux new-session -s $(basename $(pwd))'

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

. "$HOME/.local/bin/env"

# Smart Suggestion # smart-suggestion
source /Users/agent/.config/smart-suggestion/smart-suggestion.plugin.zsh # smart-suggestion

# opencode
export PATH=/Users/agent/.opencode/bin:$PATH

# Added by Antigravity
export PATH="/Users/agent/.antigravity/antigravity/bin:$PATH"

# bun completions
[ -s "/Users/agent/.bun/_bun" ] && source "/Users/agent/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
