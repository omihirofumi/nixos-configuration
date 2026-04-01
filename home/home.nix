{ config, pkgs, inputs, USERNAME, ... }:
{
  home.username = USERNAME;

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    fzf
    zinit
    mise
    oh-my-posh
    git
    gh
    lazygit
    bat
    eza
    ripgrep
    fd
    jq
    ghq
    inputs.jj.packages.${pkgs.system}.jujutsu
    pet
    bat
    rustup
    docker
    docker-buildx
    docker-compose
    docker-credential-helpers
    jjui
    ni
    sops
    tig
    tldr
    nb
    difftastic
    zls
    zellij
  ];

  imports = [
    ./zsh.nix
    ./git.nix
    ./helix.nix
    ./tmux.nix
    ./claude.nix
  ];

  home.file.".config/negligible.omp.json".source = ./negligible.omp.json;
  home.file.".ideavimrc".source = ./.ideavimrc;

  xdg.configFile."karabiner" = {
    source = ./karabiner;
    recursive = true;
  };

  xdg.configFile."ghostty" = {
    source = ./ghostty;
    recursive = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      global = {
        hide_env_diff = true;
      };
    };
  };

  xdg.configFile."jj" = {
    source = ./jj;
    recursive = true;
  };

  xdg.configFile."jjui" = {
    source = ./jjui;
    recursive = true;
  };

  home.activation.ensureFavdirs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
  mkdir -p "$HOME/.config"
  if [ ! -e "$HOME/.config/favdirs" ]; then
    : > "$HOME/.config/favdirs"
  fi
'';
}
