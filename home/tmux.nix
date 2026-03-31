{ ... }:
{
  programs.tmux = {
    enable = true;
    prefix = "C-j";
    # mouse = true;
    extraConfig = ''
      # plugin
      set -g @plugin 'tmux-plugins/tpm'
      set -g @plugin 'tmux-plugins/tmux-resurrect'
      set -g @plugin 'tmux-plugins/tmux-continuum'

      # session auto save/restore disk
      set -g @continuum-restore 'on'

      # ウィンドウ名の自動変更を無効化
      set-option -g allow-rename off

      # ペイン移動をhjklに
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # with current directory
      bind % split-window -h -c "#{pane_current_path}"
      bind '"' split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # アクティブペインのボーダーを緑に
      set -g pane-active-border-style fg=green
      set -g pane-border-style fg=#444444

      # ESCキーの遅延をなくす
      set -g escape-time 0

      # viキーバインドでコピーモード操作
      set -g mode-keys vi
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-selection

      # ghosttyの透過背景をtmuxでも反映
      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",*:Tc"
      set -g window-style "bg=default"
      set -g window-active-style "bg=default"

      set -g display-panes-time 3000

      # for ai agent(ref: https://boristane.com/blog/how-i-use-claude-code/)
      bind-key e display-panes "send-keys -t %% \"I added a few notes to the document, address all the notes and update the document accordingly. don't implement yet\" Enter"
      bind-key i display-panes "send-keys -t %% \"implement it all. when you're done with a task or phase, mark it as completed in the plan document. do not stop until all tasks and phases are completed.\" Enter"

      # 最後に記述(MUST)
      run '~/.tmux/plugins/tpm/tpm'
    '';
  };
}
