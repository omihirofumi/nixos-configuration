{ pkgs, ... }:
let
  zshFunctions = import ./zsh/functions.nix { inherit pkgs; };
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # zinit で入れるので HM 側は無効（重複回避）
    autosuggestion.enable = false;
    syntaxHighlighting.enable = false;

    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
      extended = true;
    };

    shellAliases = {
      g = "git";
      lgit = "lazygit";
      lg = "lazygit";
      cat = "bat";
      ls = "eza -l";
      ll = "eza -la";
    };

    initContent = ''
      ######## PATH ###########
      export PATH="$HOME/.cargo/bin:$PATH"
      ######## core env ########
      export LANG=ja_JP.UTF-8
      export LC_ALL=ja_JP.UTF-8

      export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#808080"
      export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

      export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
      export EDITOR=hx
      export HELIX_RUNTIME=$HOME/ghq/github.com/helix-editor/helix/runtime

      ######## prompt / helpers ########
      eval "$(/opt/homebrew/bin/brew shellenv)"
      # opam (OCaml)
      if command -v opam >/dev/null 2>&1; then
        eval "$(opam env --shell=zsh)"
      fi
      # mise
      eval "$(${pkgs.mise}/bin/mise activate zsh)"

      # oh-my-posh（設定ファイルは home-manager で ~/.config/negligible.omp.json を配布している前提）
      eval "$(${pkgs.oh-my-posh}/bin/oh-my-posh init zsh --config "$HOME/.config/negligible.omp.json")"

      if command -v ww >/dev/null 2>&1; then
        eval "$(ww init zsh)"
      fi

      ######## fzf ########
      source <(${pkgs.fzf}/bin/fzf --zsh)

      ######## key bindings ########
      # ctrl + M for ghostty
      bindkey '\e[109;5u' accept-line

      # emacs keybinds
      bindkey -e

      ######## zinit ########
      # Nix 供給の zinit を使用（自動インストールはしない）
      source "${pkgs.zinit}/share/zinit/zinit.zsh"
      autoload -Uz _zinit
      (( $+_comps )) && _comps[zinit]=_zinit

      # annex（light-mode / turbo なし）
      zinit light-mode for \
        zdharma-continuum/zinit-annex-as-monitor \
        zdharma-continuum/zinit-annex-bin-gem-node \
        zdharma-continuum/zinit-annex-patch-dl \
        zdharma-continuum/zinit-annex-rust

      # async / colors
      zinit light mafredri/zsh-async
      # Defer 256color setup to reduce startup cost.
      zinit ice wait'1' silent
      zinit light chrissicool/zsh-256color

      # completions（compinit 前）
      zinit ice blockf
      zinit light zsh-users/zsh-completions

      # compinit（ここで一度だけ）
      autoload -Uz compinit
      compinit -C

      # fzf-tab（compinit 後）
      zinit light Aloxaf/fzf-tab

      # syntax highlight / history substring / autosuggestions
      zinit light zsh-users/zsh-syntax-highlighting
      zinit light zsh-users/zsh-history-substring-search
      zinit light zsh-users/zsh-autosuggestions

      # emojify（command）
      zinit ice as"command"
      zinit light mrowa44/emojify

      # z
      zinit light agkozak/zsh-z

      # git-fuzzy（command）
      zinit ice as"command" pick"bin/git-fuzzy"
      zinit light bigH/git-fuzzy

      ######## jj completion ########
      # jj がある時だけ
      if command -v jj >/dev/null 2>&1; then
        source <(COMPLETE=zsh jj)
      fi

${zshFunctions}

      # Rancher Desktop（外部が管理するので存在時のみ）
      if [ -d "$HOME/.rd/bin" ]; then
        export PATH="$HOME/.rd/bin:$PATH"
      fi

      # ww completion（存在時のみ）
      if command -v ww >/dev/null 2>&1; then
        eval "$(ww completion zsh)"
      fi

      # Per-machine or untracked local overrides.
      if [ -f "$HOME/.zshrc_local" ]; then
        source "$HOME/.zshrc_local"
      fi
          '';
  };
}
