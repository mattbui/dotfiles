# GPG_TTY variable for gpg signing commit
export GPG_TTY=$(tty)

# Enable Powerlevel10k instant prompt. Should stay close to the top of $HOME/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

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

# To customize prompt, run `p10k configure` or edit `~/.config/zsh/p10k.zsh`.
[[ ! -f "$HOME/.config/zsh/p10k.zsh" ]] || source "$HOME/.config/zsh/p10k.zsh"

source <(fzf --zsh)
[[ ! -f $HOME/.config/zsh/fzf_configs.zsh ]] || source $HOME/.config/zsh/fzf_configs.zsh

eval "$(direnv hook zsh)"
eval "$(zoxide init zsh)"
