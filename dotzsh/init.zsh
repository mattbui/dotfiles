# GPG_TTY variable for gpg signing commit
export GPG_TTY=$(tty)

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# export MANPATH="/usr/local/man:$MANPATH"

# Compilation flags
# export ARCHFLAGS="-arch x86_64"
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if command -v nvim > /dev/null 2>&1; then
    export VISUAL='nvim'
else
    export VISUAL='vim'
fi
export EDITOR=$VISUAL

export MANPAGER='cat'

# Plugins flags
# zsh auto complete
autoload -U compinit && compinit

# zsh auto suggestion color
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=246,underline'

# bat flags
export BAT_THEME='ansi'

for keymap in emacs viins; do
    bindkey -M "$keymap" -s '^o' 'ycd\n'
done

[[ ! -f $HOME/.config/zsh/aliases.zsh ]] || source $HOME/.config/zsh/aliases.zsh  # my custom aliases

if [[ $(uname -s) == Linux* && -f "${HOME}/.config/zsh/start_ssh_agent.zsh" ]]; then
    source "${HOME}/.config/zsh/start_ssh_agent.zsh"
fi

# Add ssh keys
GITKEY="$HOME/.ssh/github.key"
if [[ $(uname -s) == Linux* && -f $GITKEY ]]; then
    GITKEY_FPRINT=$(ssh-keygen -lf $GITKEY)
    LIST_KEYS=$(ssh-add -l)

    # Add git key if not available
    if [[ $LIST_KEYS != *$GITKEY_FPRINT* ]]; then
        ssh-add $GITKEY 2> /dev/null
    fi
fi

GITKEY="$HOME/.ssh/glimpse"
if [[ $(uname -s) == Linux* && -f $GITKEY ]]; then
    GITKEY_FPRINT=$(ssh-keygen -lf $GITKEY)
    LIST_KEYS=$(ssh-add -l)

    # Add git key if not available
    if [[ $LIST_KEYS != *$GITKEY_FPRINT* ]]; then
        ssh-add $GITKEY 2> /dev/null
    fi
fi

[[ ! -f $HOME/.config/zsh/plugins.zsh ]] || source $HOME/.config/zsh/plugins.zsh  # load plugins

# Force a steady beam cursor in interactive zsh prompts, except in SSH sessions.
if [[ -z ${SSH_CONNECTION}${SSH_CLIENT}${SSH_TTY} ]]; then
    _force_beam_cursor() {
        printf '\e[6 q'
    }
    precmd_functions+=(_force_beam_cursor)
    preexec_functions+=(_force_beam_cursor)
    zle-line-init() { _force_beam_cursor }
    zle-keymap-select() { _force_beam_cursor }
    zle -N zle-line-init
    zle -N zle-keymap-select
fi

# Redo in the zsh command-line editor (Ctrl-X Ctrl-R, or Ctrl-X then r).
# compinit/.zcompdump can rebind Ctrl-X Ctrl-R to _read_comp, so re-apply this
# before each prompt.
_bind_redo_keys() {
    bindkey '^X^R' redo
    bindkey '^Xr' redo
    bindkey -M viins '^X^R' redo
    bindkey -M viins '^Xr' redo
}
_bind_redo_keys
precmd_functions+=(_bind_redo_keys)

# Make Ctrl-U, including Alacritty's Cmd-Backspace mapping, delete only back to
# the start of the line instead of killing the whole command line.
bindkey '^U' backward-kill-line
bindkey -M viins '^U' backward-kill-line

# Load machine-local secrets kept outside the dotfiles repository.
[[ -r "$HOME/.config/zsh-secrets.zsh" ]] && source "$HOME/.config/zsh-secrets.zsh"

source <(fzf --zsh)
[[ ! -f $HOME/.config/zsh/fzf_configs.zsh ]] || source $HOME/.config/zsh/fzf_configs.zsh

eval "$(direnv hook zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

# Replace fixed STARSHIP_JOBS_COUNT with background jobs count so job counts updated whenever new prompt render.
PROMPT=${PROMPT/'$STARSHIP_JOBS_COUNT'/'${#jobstates[*]}'}
# Detect background job notification based on job count change and add a blank line to separate it from the prompt.
PROMPT=${PROMPT/#'$('/'$(if (( ${#jobstates[*]} != STARSHIP_JOBS_COUNT )); then printf "\n"; fi; '}

# After both substitutions above, the generated prompt roughly becomes:
# PROMPT='$(if (( ${#jobstates[*]} != STARSHIP_JOBS_COUNT )); then
#     printf "\n"
# fi
#
# starship prompt ... --jobs="${#jobstates[*]}")'

# Render a footer when a command finish to show its status, completion time, and optionally duration.
# this uses status and duration from starship and renders them with precmd hooks.
# The footer is rendered as part of the new prompt.

# Skip the command footer when it's a clear command.
_starship_cmd_start() {
    local -a command_words
    local command_name token
    command_words=(${(z)2})
    command_name=${command_words[1]:t}

    unset _STARSHIP_SKIP_CMD_FOOTER

    for token in "${command_words[@]}"; do
        case $token in
            '&&'|'||'|';'|'&'|'&!'|'&|'|'|'|'|&') return 0 ;;
        esac
    done

    case $command_name in
        clear|reset)
            _STARSHIP_SKIP_CMD_FOOTER=1
            ;;
        tput)
            if [[ $command_words[2] == clear || $command_words[2] == reset ]]; then
                _STARSHIP_SKIP_CMD_FOOTER=1
            fi
            ;;
    esac
}
add-zsh-hook preexec _starship_cmd_start

_starship_cmd_end() {
    if (( ${+_STARSHIP_SKIP_CMD_FOOTER} )); then
        unset STARSHIP_DURATION STARSHIP_CMD_OK STARSHIP_CMD_ERR
    elif (( ${+STARSHIP_DURATION} )); then
        local cmd_duration=$STARSHIP_DURATION
        local cmd_end footer
        strftime -s cmd_end '%H:%M:%S'

        if (( STARSHIP_CMD_STATUS == 0 )); then
            export STARSHIP_CMD_OK=$cmd_end
            unset STARSHIP_CMD_ERR
        else
            export STARSHIP_CMD_ERR=$cmd_end
            unset STARSHIP_CMD_OK
        fi

        footer=$(starship prompt --profile cmd-footer --cmd-duration "$cmd_duration")
        print -Pn -- "$footer"
        printf '\n\n'

        unset STARSHIP_DURATION STARSHIP_CMD_OK STARSHIP_CMD_ERR
    else
        unset STARSHIP_CMD_OK STARSHIP_CMD_ERR
    fi

    unset _STARSHIP_SKIP_CMD_FOOTER
}
add-zsh-hook precmd _starship_cmd_end
