{ pkgs }:
''
  ######## functions ########

  # fzf x ghq
  function ghq-dup () {
    local repo src base_dir repo_name

    # 元リポジトリを選択（agentコピーは除外）
    repo=$(ghq list | grep -v -e '-agent[0-9]' | fzf --reverse --prompt="Dup repo: ")
    [ -z "$repo" ] && return

    src=$(ghq list --full-path --exact "$repo")
    base_dir=$(dirname "$src")
    repo_name=$(basename "$src")

    for suffix in agent1 agent2; do
      local dst="''${base_dir}/''${repo_name}-''${suffix}"
      if [ -d "$dst" ]; then
        echo "already exists: $dst"
      else
        echo "cloning → $dst"
        git clone "$src" "$dst"
      fi
    done
  }

  function fzf-src () {
    local repo

    repo=$(ghq list | awk '
      /-agent[0-9]+$/ { printf "\033[33m[agent] %s\033[0m\n", $0; next }
                      { print }
    ' | fzf --reverse --ansi --prompt="repo: ")

    # ラベル除去
    repo=$(echo "$repo" | sed 's/\[agent\] //')

    if [ -n "$repo" ]; then
      repo=$(ghq list --full-path --exact "$repo")
      BUFFER="cd $repo"
      zle accept-line
    fi
    zle clear-screen
  }
  zle -N fzf-src
  bindkey '^g' fzf-src

  # fzf x Development
  function fzf-dev () {
    local selected_dir
    selected_dir=$(find "$HOME/Development" -type d -mindepth 1 -maxdepth 3 \
      -not -path "*/.*" \
      -not -path "*/node_modules*" \
      -not -path "*/target*" \
      -not -path "*/build*" | \
      sed "s|$HOME/||" | \
      ${pkgs.fzf}/bin/fzf --reverse --preview "ls -la ~/{}"
    )
    if [ -n "$selected_dir" ]; then
      BUFFER="cd ~/$selected_dir"
      zle accept-line
    fi
    zle clear-screen
  }
  zle -N fzf-dev
  bindkey '^j' fzf-dev

  # pr [-a] => gh dash
  function pr() {
    if [ "$1" = "-a" ]; then
      (cd "$HOME" && gh dash)
    else
      gh dash "$@"
    fi
  }

  # fzf x favorite directories (~/.config/favdirs)
  function fzf-favdir () {
    local config_file
    config_file="$HOME/.config/favdirs"

    if [ ! -f "$config_file" ]; then
      echo "~/.config/favdirs が見つかりません" >&2
      return 1
    fi

    local selected_dir
    selected_dir=$(cat "$config_file" | ${pkgs.fzf}/bin/fzf --reverse --prompt="Favorite dirs > ")

    if [ -n "$selected_dir" ]; then
      BUFFER="cd $selected_dir"
      zle accept-line
    fi
    zle clear-screen
  }
  zle -N fzf-favdir
  bindkey '^]' fzf-favdir

  function fzf-tmux-session () {
    tmux has-session -t main   2>/dev/null || tmux new -s main   -d
    tmux has-session -t agent1 2>/dev/null || tmux new -s agent1 -d
    tmux has-session -t agent2 2>/dev/null || tmux new -s agent2 -d
    local session
    if [ -z "$TMUX" ]; then
      session=$(tmux ls | fzf --layout=reverse | cut -d: -f1)
      [ -n "$session" ] && BUFFER="tmux attach -t $session"
    else
      session=$(tmux ls | fzf --layout=reverse | cut -d: -f1)
      [ -n "$session" ] && BUFFER="tmux switch -t $session"
    fi
    zle accept-line
  }
  zle -N fzf-tmux-session
  bindkey '^t' fzf-tmux-session

  # Allow Ctrl-z to toggle between suspend and resume
  function Resume {
    fg
    zle push-input
    BUFFER=""
    zle accept-line
  }
  zle -N Resume
  bindkey "^Z" Resume
''
