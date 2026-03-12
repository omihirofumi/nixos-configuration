{ pkgs }:
''
  ######## functions ########

  function _workspace_clone_suffix () {
    printf '%s' "$1" | LC_ALL=C sed -E \
      -e 's|/|__|g' \
      -e 's|[^A-Za-z0-9._-]+|_|g' \
      -e 's|_+|_|g' \
      -e 's|^_||' \
      -e 's|_$||'
  }

  function _jclone_scope_prefix () {
    local repo_root rel_path

    repo_root=$(jj root 2>/dev/null) || return 0
    rel_path=$(realpath --relative-to="$repo_root" "$PWD" 2>/dev/null || true)

    if [ -n "$rel_path" ] && [ "$rel_path" != "." ]; then
      _workspace_clone_suffix "$rel_path"
    fi
  }

  function _jclone_base_name () {
    local repo_root repo_name

    repo_root=$(jj root 2>/dev/null) || return 1
    repo_name=$(basename "$repo_root")
    printf '%s\n' "$(printf '%s' "$repo_name" | sed 's/__clone__.*$//')"
  }

  function _jclone_base_dir () {
    local repo_root repo_parent base_name

    repo_root=$(jj root 2>/dev/null) || return 1
    repo_parent=$(dirname "$repo_root")
    base_name=$(_jclone_base_name) || return 1
    printf '%s\n' "$repo_parent/$base_name"
  }

  function _jclone_clone_dirs () {
    local base_dir repo_parent base_name

    base_dir=$(_jclone_base_dir) || return 1
    repo_parent=$(dirname "$base_dir")
    base_name=$(basename "$base_dir")

    find "$repo_parent" -mindepth 1 -maxdepth 1 -type d -name "$base_name""__clone__*" | sort
  }

  function _jclone_apply_scope () {
    local base_name scope_prefix

    base_name="$1"
    scope_prefix=$(_jclone_scope_prefix)

    if [ -n "$scope_prefix" ]; then
      printf '%s\n' "$scope_prefix""__""$base_name"
    else
      printf '%s\n' "$base_name"
    fi
  }

  function _jclone_unscoped_name () {
    local raw_name scope_prefix prefix

    raw_name="$1"
    scope_prefix=$(_jclone_scope_prefix)
    prefix="$scope_prefix""__"

    case "$raw_name" in
      "$prefix"*)
        printf '%s\n' "$(printf '%s' "$raw_name" | sed "s/^$prefix//")"
        ;;
      *)
        printf '%s\n' "$raw_name"
        ;;
    esac
  }

  function _jclone_default_name () {
    local bookmark_name

    bookmark_name=$(jj bookmark list -r @ 2>/dev/null | sed -E 's/:.*$//' | sed -n '1p')
    if [ -n "$bookmark_name" ]; then
      _jclone_apply_scope "$bookmark_name"
      return 0
    fi
  }

  function _jclone_candidates () {
    local scope_prefix
    scope_prefix=$(_jclone_scope_prefix)

    {
      _jclone_default_name
      jj bookmark list 2>/dev/null | sed -E 's/:.*$//'
    } | awk 'NF && !seen[$0]++'
    if [ -n "$scope_prefix" ]; then
      {
        jj bookmark list 2>/dev/null | sed -E 's/:.*$//'
      } | awk 'NF && !seen[$0]++' | while IFS= read -r line; do
        _jclone_apply_scope "$line"
      done | awk 'NF && !seen[$0]++'
    fi
  }

  function jclone () {
    local repo_root source_git_root repo_parent repo_name raw_name suffix dest_dir origin_url clone_branch clone_source

    repo_root=$(jj root 2>/dev/null) || {
      echo "jj リポジトリの中で実行してください" >&2
      return 1
    }
    source_git_root=$(jj git root 2>/dev/null) || {
      echo "Git backend の jj repo で実行してください" >&2
      return 1
    }

    raw_name="$*"
    if [ -z "$raw_name" ]; then
      raw_name=$(_jclone_default_name)
    fi
    if [ -z "$raw_name" ]; then
      echo "suffix を指定してください: jclone <feature-name>" >&2
      return 1
    fi

    suffix=$(_workspace_clone_suffix "$raw_name")
    if [ -z "$suffix" ]; then
      echo "feature 名をディレクトリ名に変換できませんでした: $raw_name" >&2
      return 1
    fi

    repo_parent=$(dirname "$repo_root")
    repo_name=$(basename "$repo_root")
    dest_dir="$repo_parent/$repo_name""__clone__""$suffix"

    if [ -e "$dest_dir" ]; then
      echo "既に存在します: $dest_dir" >&2
      return 1
    fi

    origin_url=$(git --git-dir="$source_git_root" config --get remote.origin.url 2>/dev/null || true)
    clone_source="$origin_url"
    if [ -z "$clone_source" ]; then
      clone_source="$repo_root"
    fi

    clone_branch=$(jj bookmark list -- "$raw_name" 2>/dev/null | sed -E 's/:.*$//' | sed -n '1p')
    if [ -z "$clone_branch" ]; then
      clone_branch=$(jj bookmark list -- "$(_jclone_unscoped_name "$raw_name")" 2>/dev/null | sed -E 's/:.*$//' | sed -n '1p')
    fi

    if [ -n "$clone_branch" ]; then
      git clone --single-branch --branch "$clone_branch" --no-tags --filter=blob:none "$clone_source" "$dest_dir" || return 1
    else
      git clone --single-branch --no-tags --filter=blob:none "$clone_source" "$dest_dir" || return 1
    fi

    jj git init --git-repo "$dest_dir/.git" "$dest_dir" >/dev/null || return 1

    cd "$dest_dir" || return 1
    pwd
  }

  function jclone-fzf () {
    local current_name selected_name

    jj root >/dev/null 2>&1 || {
      echo "jj リポジトリの中で実行してください" >&2
      return 1
    }

    current_name=$(_jclone_default_name)
    selected_name=$(
      _jclone_candidates | ${pkgs.fzf}/bin/fzf --reverse \
        --prompt="jclone > " \
        --query "$current_name" \
        --header="Enter で clone / 任意名は jclone <name>"
    )

    [ -n "$selected_name" ] || return 1
    jclone "$selected_name"
  }

  function jclone-fxf () {
    jclone-fzf "$@"
  }

  function jclone-name () {
    local clone_name

    clone_name="$*"
    if [ -z "$clone_name" ]; then
      printf 'jclone name > '
      read -r clone_name
    fi

    [ -n "$clone_name" ] || return 1
    jclone "$clone_name"
  }

  function jmain () {
    local base_dir

    base_dir=$(_jclone_base_dir) || {
      echo "jj リポジトリの中で実行してください" >&2
      return 1
    }

    if [ ! -d "$base_dir" ]; then
      echo "base repo が見つかりません: $base_dir" >&2
      return 1
    fi

    cd "$base_dir" || return 1
    pwd
  }

  function jclone-gc () {
    local base_dir selected_dirs current_pwd reply dir

    base_dir=$(_jclone_base_dir) || {
      echo "jj リポジトリの中で実行してください" >&2
      return 1
    }

    selected_dirs=$(
      _jclone_clone_dirs | ${pkgs.fzf}/bin/fzf --multi --reverse \
        --prompt="jclone gc > " \
        --header="Tab で複数選択 / Enter で削除候補" \
        --preview 'printf "%s\n\n" {}; git -C {} status --short --branch 2>/dev/null | head -80'
    )

    [ -n "$selected_dirs" ] || return 1

    printf '%s\n' "$selected_dirs"
    printf 'Delete selected clone directories? [y/N] '
    read -r reply
    case "$reply" in
      [Yy]|[Yy][Ee][Ss])
        ;;
      *)
        return 1
        ;;
    esac

    current_pwd="$PWD"
    while IFS= read -r dir; do
      [ -n "$dir" ] || continue
      case "$current_pwd/" in
        "$dir/"*)
          cd "$base_dir" || return 1
          current_pwd="$PWD"
          ;;
      esac
      rm -rf -- "$dir"
      printf 'removed %s\n' "$dir"
    done <<EOF
$selected_dirs
EOF
  }

  function jclone-fzf-widget () {
    zle -I
    jclone-fzf
    zle reset-prompt
  }
  zle -N jclone-fzf-widget
  bindkey '^X^J' jclone-fzf-widget

  function jclone-name-widget () {
    zle -I
    jclone-name
    zle reset-prompt
  }
  zle -N jclone-name-widget
  bindkey '^X^C' jclone-name-widget

  function jmain-widget () {
    zle -I
    jmain
    zle reset-prompt
  }
  zle -N jmain-widget
  bindkey '^X^X' jmain-widget

  function jclone-gc-widget () {
    zle -I
    jclone-gc
    zle reset-prompt
  }
  zle -N jclone-gc-widget
  bindkey '^X^D' jclone-gc-widget

  # fzf x ghq
  function fzf-src () {
    local selected_dir
    selected_dir=$(${pkgs.ghq}/bin/ghq list -p | ${pkgs.fzf}/bin/fzf --reverse)
    if [ -n "$selected_dir" ]; then
      BUFFER="cd $selected_dir"
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
