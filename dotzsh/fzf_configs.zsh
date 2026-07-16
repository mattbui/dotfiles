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

export FZF_COMPLETION_TRIGGER='~~'

export FZF_DEFAULT_OPTS="--color=dark --border=sharp --height 40% --reverse --info=inline"

export FZF_CTRL_T_OPTS="
  --preview 'if [ -d {} ]; then tree -C -L 1 --dirsfirst {}; elif grep -Iq . {} 2>/dev/null; then bat --style=numbers --color=always --line-range :500 {}; fi'
  --preview-window 'right:55%,border-sharp'"

# TokyoNight Storm colors
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
    --color=fg:#c0caf5,bg:#24283b,hl:#565f89
    --color=fg+:#7aa2f7:regular,bg+:#3b4261,hl+:#bb9af7
    --color=info:#7dcfff,border:#565f89,prompt:#bb9af7
    --color=pointer:#bb9af7,marker:#bb9af7,spinner:#e0af68,header:#565f89'

# custom keybindings
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
--bind="tab:down,shift-tab:up,shift-down:toggle+down,shift-up:toggle+up"'

fcd() {
  local dir
  if ! command -v fd &> /dev/null; then
    dir=$(find ${1:-.} -path '*/\.*' -prune \
                    -o -type d -print 2> /dev/null | fzf +m) &&
    cd "$dir"
  else
    dir=$(fd --type d --hidden --follow 2> /dev/null | fzf +m) &&
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
