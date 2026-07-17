# fzf flags
if ! command -v fd &> /dev/null; then
  export FZF_DEFAULT_COMMAND='find * -type f'
  export PI_INLINE_FZF_COMMAND='find . \( -path "./.git" -o -path "./.src" -o -path "./.venv" -o -path "./.undodir*" -o -name ".DS_Store" \) -prune -o \( -type f -o -type d \) -print'
else
  export FZF_CTRL_T_COMMAND='fd --hidden --follow --type f --type d'
  export FZF_DEFAULT_COMMAND="$FZF_CTRL_T_COMMAND"
  export PI_INLINE_FZF_COMMAND='fd --hidden --follow --type f --type d'
fi

if command -v rg &> /dev/null; then
  export PI_FZF_RG_COMMAND='rg --column --line-number --no-heading --color=never --hidden --follow "^"'
fi

export FZF_DEFAULT_OPTS="
    --color=dark --input-border=sharp --list-border=sharp --header-border=sharp
    --list-label-pos=2 --input-label-pos=2 --preview-label-pos=2
    --preview-label=' PgUp/PgDn: scroll preview '
    --height 50% --reverse --info=inline-right --preview-window 'right:55%,border-sharp'
"

# TokyoNight Storm colors
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
    --color=fg:#c0caf5,bg:#24283b,hl:#565f89:regular
    --color=fg+:#7aa2f7:regular,bg+:#3b4261,hl+:#bb9af7:regular
    --color=query:#c0caf5:regular,info:#7dcfff,border:#565f89,label:#565f89:regular
    --color=pointer:#bb9af7,marker:#bb9af7,spinner:#e0af68,header:#565f89,prompt:#bb9af7'

# custom keybindings
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
    --bind=tab:down,shift-tab:up
    --bind=shift-down:toggle+down,shift-up:toggle+up
    --bind=page-up:preview-half-page-up,page-down:preview-half-page-down
    --bind=alt-up:half-page-up,alt-down:half-page-down'

# file widget
export FZF_CTRL_T_OPTS="
  --input-label ' Files '
  --preview '
    if [ -d {} ]; then
      command -v tree >/dev/null 2>&1 && tree -C -L 1 --dirsfirst {}
    elif command -v bat >/dev/null 2>&1 && grep -Iq . {} 2>/dev/null; then
      bat --style=numbers --color=always --line-range :500 {}
    fi
  '
"

# cd widget
export FZF_ALT_C_OPTS="
  --input-label ' Change directory '
  --preview '
    command -v tree >/dev/null 2>&1 && tree -C -L 1 --dirsfirst {}
  '
"

# command history widget
export FZF_CTRL_R_OPTS="
  --input-label ' Command history '
  --list-label ' ^y: copy to clipboard '
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
"

export FZF_COMPLETION_TRIGGER='@'

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'command -v tree >/dev/null 2>&1 && tree -C -L 1 --dirsfirst {}' "$@" ;;
    export|unset) fzf --preview "eval 'echo \$'{}"         "$@" ;;
    ssh)          fzf --preview '
                    ssh -G {} 2>/dev/null |
                      awk "
                        /^hostname /     { hostname = \$0 }
                        /^port /         { port = \$0 }
                        /^user /         { user = \$0 }
                        /^proxyjump /    { proxyjump = \$0 }
                        /^identityfile / { identityfiles = identityfiles \$0 ORS }
                        END {
                          if (hostname != \"\") print hostname
                          if (port != \"\") print port
                          if (user != \"\") print user
                          if (proxyjump != \"\") print proxyjump
                          printf \"%s\", identityfiles
                        }
                      "
                  ' "$@" ;;
    *)            fzf --preview '
                    if command -v bat >/dev/null 2>&1 && grep -Iq . {} 2>/dev/null; then
                      bat --style=numbers --color=always --line-range :500 {}
                    fi
                  ' "$@" ;;
  esac
}

for keymap in emacs viins; do
  bindkey -M "$keymap" '^g' fzf-cd-widget
  bindkey -M "$keymap" '^f' fzf-file-widget
done
