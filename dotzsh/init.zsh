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
export VISUAL='nvim'
export EDITOR=$VISUAL

export MANPAGER="$EDITOR -c 'set ft=man ts=8 nomod noma nolist nonumber'"

# Plugins flags
# zsh auto complete
autoload -U compinit && compinit

# zsh auto suggestion color
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=246,underline'

# bat flags
export BAT_THEME='ansi-light'

# Bind interup signal to ctrl+e in cmd mode
# and change back to ctrl+c before command executed
# this enable to bind ctrl+c to esc in zsh vim mode
# _bind_intr_ce() {
#     [[ -t 0 ]] && stty intr ^E
# }
# _bind_intr_cc() {
#     [[ -t 0 ]] && stty intr ^C
# }
# autoload add-zsh-hook
# add-zsh-hook precmd _bind_intr_ce
# add-zsh-hook preexec _bind_intr_cc

# Add this so zsh-vim-mode don't override key biddings
function zvm_after_init() {
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    [[ ! -f $HOME/.config/zsh/fzf_configs.zsh ]] || source $HOME/.config/zsh/fzf_configs.zsh
    [[ ! -f $HOME/.config/lf/lfcd.sh ]] || source $HOME/.config/lf/lfcd.sh
    bindkey -M viins '^[f' forward-word
    bindkey -M viins '^[b' backward-word
}

[[ ! -f $HOME/.config/zsh/gcloud.zsh ]] || source $HOME/.config/zsh/gcloud.zsh  # enable gcloud autocomplete
[[ ! -f $HOME/.config/zsh/aliases.zsh ]] || source $HOME/.config/zsh/aliases.zsh  # my custom aliases
[[ ! -f $HOME/.config/lf/lf_icons.sh ]] || source $HOME/.config/lf/lf_icons.sh  # specify icons of lf

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

# To customize prompt, run `p10k configure` or edit `~/.config/zsh/p10k.zsh`.
[[ ! -f $HOME/.config/zsh/p10k.zsh ]] || source $HOME/.config/zsh/p10k.zsh
