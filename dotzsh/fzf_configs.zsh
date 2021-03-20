# fzf flags
if ! command -v fd &> /dev/null; then
  export FZF_DEFAULT_COMMAND='find * -type f'
else
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --no-ignore --exclude .git'
fi

export FZF_DEFAULT_OPTS="--color=light --height 40% --layout=reverse --info=inline"
export FZF_COMPLETION_TRIGGER='~~'

# sainnhe/edge color scheme
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' 
--color=fg:#4b505b,bg:#fafafa,hl:#5079be 
--color=fg+:#4b505b,bg+:#fafafa,hl+:#3a8b84 
--color=info:#88909f,prompt:#d05858,pointer:#b05ccc 
--color=marker:#608e32,spinner:#d05858,header:#3a8b84'

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

bindkey -s '^x^o' 'fo\n'  # open file with ctrl+x+o
bindkey -s '^x^f' 'fcd\n' # open folder with ctrl+x+f
bindkey -M viins '^f' fzf-file-widget # search file with ctrl+f
