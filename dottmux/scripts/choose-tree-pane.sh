#!/bin/sh

tmux select-pane -T "__choose_tree_split__"
picker_pane="$(tmux display-message -p '#{pane_id}')"

tmux choose-tree -N -t "$picker_pane" -F '#{?window_bell_flag,#[fg=#e0af68][!] #[default],}#[fg=#{?window_active,#bb9af7,#565f89}]#{pane_current_command}#[default] #[fg=#565f89]| #[fg=#{?window_active,#7aa2f7,#565f89}]#{?#{==:#{pane_current_command},ssh},#{pane_title},#{b:pane_current_path}}#[default]' "switch-client -t '%%' ; kill-pane -t '$picker_pane'"

while [ "$(tmux display-message -p -t "$picker_pane" '#{pane_in_mode}' 2>/dev/null)" = "1" ]; do
    sleep 0.1
done

tmux kill-pane -t "$picker_pane" 2>/dev/null
