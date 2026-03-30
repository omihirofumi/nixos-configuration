{ ... }:
{
  programs.tmux = {
    enable = true;
    prefix = "C-j";
    mouse = true;
    extraConfig = ''
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
    '';
  };
}
