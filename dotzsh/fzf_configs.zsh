# fzf flags
if ! command -v fd &> /dev/null; then
  export FZF_DEFAULT_COMMAND='find * -type f'
  export PI_INLINE_FZF_COMMAND='find . \( -path "./.git" -o -path "./.src" -o -path "./.venv" -o -path "./.undodir*" -o -name ".DS_Store" \) -prune -o \( -type f -o -type d \) -print'
else
  export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --no-ignore --exclude .src --exclude .venv --exclude .git --exclude .DS_Store --exclude .undodir'
  export FZF_DEFAULT_COMMAND="$FZF_CTRL_T_COMMAND"
  export PI_INLINE_FZF_COMMAND='fd --hidden --follow --type f --type d --exclude .git --exclude .DS_Store --exclude .src --exclude .venv --exclude ".undodir*"'
fi

if command -v rg &> /dev/null; then
  export PI_INLINE_RG_COMMAND='rg --column --line-number --no-heading --color=always --smart-case --hidden --follow --glob "!.git" --glob "!.src" --glob "!.venv" --glob "!.DS_Store" --glob "!.undodir*"'
fi

export FZF_COMPLETION_TRIGGER='~~'

export FZF_DEFAULT_OPTS="--color=dark --border --height 40% --reverse --info=inline"

# sainnhe/edge color scheme
# export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' 
# --color=fg:#4b505b,bg:#fafafa,hl:#5079be 
# --color=fg+:#4b505b,bg+:#eef1f4,hl+:#3a8b84 
# --color=info:#88909f,prompt:#d05858,pointer:#b05ccc 
# --color=marker:#608e32,spinner:#d05858,header:#3a8b84'

# nord colors
# export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
#     --color=fg:#e5e9f0,bg:#3b4252,hl:#81a1c1
#     --color=fg+:#e5e9f0,bg+:#3b4252,hl+:#81a1c1
#     --color=info:#eacb8a,prompt:#bf6069,pointer:#b48dac
#     --color=marker:#a3be8b,spinner:#b48dac,header:#a3be8b'

# TokyoNight Storm colors
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
    --color=fg:#c0caf5,bg:#24283b,hl:#565f89
    --color=fg+:#c0caf5,bg+:#2f3549,hl+:#bb9af7
    --color=info:#7dcfff,border:#565f89,prompt:#bb9af7
    --color=pointer:#bb9af7,marker:#bb9af7,spinner:#e0af68,header:#565f89'

# custom keybindings
# export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
# --bind="tab:down,shift-tab:up,J:toggle+down,K:toggle+up"'

export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
--bind="tab:down,shift-tab:up,>:select+down,<:deselect+up"'

fcd() {
  local dir
  if ! command -v fd &> /dev/null; then
    dir=$(find ${1:-.} -path '*/\.*' -prune \
                    -o -type d -print 2> /dev/null | fzf +m) &&
    cd "$dir"
  else
    dir=$(fd --type d --hidden --follow --no-ignore --exclude .src --exclude .venv --exclude .git --exclude .DS_Store --exclude .undodir 2> /dev/null | fzf +m) &&
    cd "$dir"
  fi
}

fo() {
  IFS=$'\n' out=("$(fzf-tmux --query="$1" --exit-0 --expect=ctrl-o,ctrl-e)")
  key=$(head -1 <<< "$out")
  file=$(head -2 <<< "$out" | tail -1)
  if [ -n "$file" ]; then
    # if in vim, open it with floaterm command
    [ "$key" = ctrl-o ] && open "$file" || [ -z $VIMRUNTIME ] && $EDITOR  "$file" || floaterm "$file"
  fi
}

for keymap in emacs viins; do
  bindkey -M "$keymap" -s '^g' 'fcd\n' # go to directory with ctrl+g
  bindkey -M "$keymap" '^f' fzf-file-widget # ctrl+f for file
done
