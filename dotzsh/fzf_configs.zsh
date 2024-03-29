# fzf flags
if ! command -v fd &> /dev/null; then
  export FZF_DEFAULT_COMMAND='find * -type f'
else
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --no-ignore --exclude "{.git,.DS_Store,.undodir*}"'
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

# custom keybindings
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
--bind="tab:down,shift-tab:up,J:toggle+down,K:toggle+up"'

fcd() {
  local dir
  if ! command -v fd &> /dev/null; then
    dir=$(find ${1:-.} -path '*/\.*' -prune \
                    -o -type d -print 2> /dev/null | fzf +m) &&
    cd "$dir"
  else
    dir=$(fd --type d --hidden --follow --no-ignore --exclude .git 2> /dev/null | fzf +m) &&
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

bindkey -s '^g' 'fcd\n' # go to directory with ctrl+g
bindkey -M viins '^f' fzf-file-widget # ctrl+f for file
