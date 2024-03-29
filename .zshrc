################################################################################
#   tobi's zsh config                                                          #
#                                                                              #
#                                                                              #
################################################################################
#                  Variables and variable-related utils                        #
################################################################################
export GPG_TTY=$(tty) # makes 'git commit -S' work with curses
# editor stuff
# e(1) is a shortcut to find or open a new instance of emacs
function e() {
	# try to find the open one
	/usr/bin/wmctrl -R 'emacs'
	# if there isn't one open, then status code will be >0
	if [ $? -eq 0 ]; then
        # the $# var is like argc for shell scripts
        if [ $# -gt 0 ]; then
            emacsclient -n $1
        fi
	else
		emacs $1 &
	fi
}
export EDITOR=vim

# Prevent tmux from using vi keybindings:
#    http://matija.suklje.name/zsh-vi-and-emacs-modes
bindkey -e


function paths() { echo $PATH | tr ':' '\n' | sort }
alias ls='/bin/ls --color'

if [[ -f ~/etc/local.yaml ]]; then
	export KUBECONFIG=~/etc/local.yaml
fi
if [[ -d ~/bin ]]; then
	export PATH=$PATH:~/bin
fi

################################################################################
#                  ZSH history                                                 #
################################################################################
export HISTFILE=/home/tobi/.zhistory
export HISTSIZE=10000
export SAVEHIST=50000
# Appends every command to the history file once it is executed
setopt inc_append_history
# Reloads the history whenever you use it
setopt share_history


################################################################################
#                  Tab completion                                              #
################################################################################
autoload -U +X compinit && compinit
source <(kubectl completion zsh)
if command which helm &> /dev/null; then
	source <(helm completion zsh)
fi

################################################################################
#                  Git info in the prompt                                      #
################################################################################
# git aliases
alias g=git
# Load version control information
autoload -Uz vcs_info
precmd() {
	# Format the vcs_info_msg_0_ variable
	zstyle ':vcs_info:*' check-for-changes true

	# Only run this if you are actually _in_ a git repo
	if command git rev-parse --is-bare-repository 2> /dev/null > /dev/null; then
		# show first 4 chars of HEAD commit
		head=$(git rev-parse HEAD | cut -c -4)
		git="git($head…)"
		# if there are no uncommitted changes
		if command git diff --quiet HEAD 2> /dev/null; then
			zstyle ':vcs_info:git:*' formats "$git:%b"
		elif [[ $(git status --short | grep '^[M ]M' | wc -l) -gt 0 ]]; then
			# Show red if there are ANY unstanged changes
			zstyle ':vcs_info:git:*' formats "$git:%b%F{red}*%f"
		elif [[ $(git status --short | grep '^\W.' | wc -l) -eq 0 ]]; then
			# If everything is staged, show a green *
			if [[ $(git status --short | grep '^\w.' | wc -l) -gt 0 ]]; then
				zstyle ':vcs_info:git:*' formats "$git:%b%F{green}*%f"
			fi
		fi
	fi
 
	vcs_info
}


################################################################################
#                  The PROMPTS                                                 #
################################################################################
setopt PROMPT_SUBST
#PROMPT="%F{green}%n@%m%f:%F{cyan}%~%f %% "


# https://unix.stackexchange.com/a/273567 (shorten pwd after 4 levels deep)
PROMPT="%F{green}%n@%m%f:%F{cyan}%(4~|.../%3~|%~)%f %% "
#RPROMPT="%F{yellow}\$vcs_info_msg_0_%f"

################################################################################
#                  Hue bulbs                                                   #
################################################################################
hue_day="{\"bri\": 254, \"hue\": 40010, \"sat\": 22}"
hue_api_get() {
	curl -s "http://lights.lehman.house/api/$(cat /etc/hueuser)/lights"
}
hue_lights_ls_on() {
	hue_api_get | jq '.[] | {name: .name, on: .state.on} | select(.on == true)'
}
hue_lights_ls_off() {
	hue_api_get | jq '.[] | {name: .name, on: .state.on} | select(.on == false)'
}
hue_set() {
    light_id=$1
    on=$2
    bri=$3
    hue=$4
    sat=$5
    if [ -z $bri ]; then
	    curl -s -X PUT "http://lights.lehman.house/api/$(cat /etc/hueuser)/lights/$1/state" -d \
             "{\"on\": $on}"
    else
	    curl -s -X PUT "http://lights.lehman.house/api/$(cat /etc/hueuser)/lights/$1/state" -d \
             "{\"on\": $on, \"bri\": $bri, \"hue\": $hue, \"sat\":$sat}"
    fi
}
hue_set_bri_office() {
	for light in $(seq 24 26); do hue_set $light true 254 40010 22; done
}
office_off() {
	for light in $(seq 24 26); do hue_set $light false; done
}
office_on() {
	for light in $(seq 24 26); do hue_set $light true; done
}
office_on() {
	for light in $(seq 24 26); do hue_set $light true; done
}

################################################################################
#                  Buffer shortcuts                                            #
################################################################################
function buffer-insert-date() {
	BUFFER+="$(date +'%Y-%m-%d')"
}
function buffer-insert-datetime() {
	BUFFER+="$(date +'%Y-%m-%d %H:%M:%S')"
}
function buffer-insert-192-168-1() {
	LBUFFER+="192.168.1."
}
function buffer-insert-lehman-house() {
	LBUFFER+="lehman.house"
}
function buffer-accept-line-expand-ls() {
	# type 'lsth' and then <Alt>-l to expand and enter
	if [ "$BUFFER" = "lsth" ]; then
		zle backward-delete-word
		BUFFER+='ls -t | head -4'
		zle accept-line
	else 
		# otherwise insert "lehman.house"
		buffer-insert-lehman-house
	fi
}
# append '-o yaml | yq'
function buffer-append-yaml() {
	BUFFER+='-o yaml | yq'
}
zle -N buffer-insert-date
zle -N buffer-insert-datetime
zle -N buffer-kubectl-get-expand
zle -N buffer-insert-192-168-1
zle -N buffer-accept-line-expand-ls
zle -N buffer-append-yaml
zle -N buffer-insert-harvester-system
#bindkey $'^T' buffer-insert-date
#bindkey $'^[d' buffer-insert-datetime <alt>-d is delete, don't override it
bindkey $'^[k' buffer-kubectl-get-expand
bindkey $'^[9' buffer-insert-192-168-1
bindkey $'^[l' buffer-accept-line-expand-ls
bindkey $'^[y' buffer-append-yaml
bindkey $'^[s' buffer-insert-harvester-system

bindkey '^r' history-incremental-search-backward
