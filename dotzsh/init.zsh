if [[ $(uname -s) == Linux* && -f "${HOME}/.config/zsh/start_ssh_agent.zsh" ]]; then
    source "${HOME}/.config/zsh/start_ssh_agent.zsh"
fi

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

# zsh auto suggestion color
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=246,underline"

# zsh auto complete configs
autoload -U compinit && compinit
_comp_options+=(globdots)  # include hidden files

# export MANPATH="/usr/local/man:$MANPATH"

export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
export VISUAL='nvim'
export EDITOR=$VISUAL

export FZF_DEFAULT_OPTS='--color=light'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"
[[ ! -f $HOME/.config/zsh/plugins.zsh ]] || source $HOME/.config/zsh/plugins.zsh
[[ ! -f $HOME/.config/zsh/aliases.zsh ]] || source $HOME/.config/zsh/aliases.zsh

# Add ssh github key
GITKEY="$HOME/.ssh/github.key"
if [[ $(uname -s) == Linux* && -f $GITKEY ]]; then
    GITKEY_FPRINT=$(ssh-keygen -lf $GITKEY)
    LIST_KEYS=$(ssh-add -l)

    # Add git key if not available
    if [[ $LIST_KEYS != *$GITKEY_FPRINT* ]]; then
        ssh-add $GITKEY 2> /dev/null
    fi
fi

# To customize prompt, run `p10k configure` and copy `.p10k.zsh` to `~/.config/zsh/p10k.zsh`.
[[ ! -f $HOME/.config/zsh/p10k.zsh ]] || source $HOME/.config/zsh/p10k.zsh
