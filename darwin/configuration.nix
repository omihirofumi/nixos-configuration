{ pkgs, USERNAME, HOSTNAME, ... }:

{
  nix.settings.extra-experimental-features = [ "nix-command" "flakes" ];
  system.primaryUser = USERNAME;
  nix.enable = false;

  users.users.${USERNAME} = {
    home = "/Users/${USERNAME}";
    shell = pkgs.zsh;
  };

  system.defaults = {
    dock.autohide = true;
    dock.show-recents = false;
    dock.mru-spaces = false;

    finder.AppleShowAllExtensions = true;
    finder.ShowPathbar = true;
    finder.ShowStatusBar = true;
    finder.FXPreferredViewStyle = "Nlsv";

    NSGlobalDomain = {
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      ApplePressAndHoldEnabled = false;
      "com.apple.trackpad.scaling" = 3.0;
      AppleShowAllExtensions = true;
    };

    CustomUserPreferences = {
      "com.mitchellh.ghostty" = {
        NSUserKeyEquivalents = {
          "Hide Ghostty" = "@~$h";
        };
      };
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };
    casks = [
      "deskpad" "ghostty" "homerow" "linear-linear" "raindropio"
      "raycast" "karabiner-elements" "google-chrome" "chatgpt"
    ];
    taps = [ "k1low/tap" ];
    brews = [ "k1low/tap/mo" ];
  };

  environment.systemPackages = with pkgs; [
    _1password-cli
    _1password-gui
    jetbrains-toolbox
    dbeaver-bin
    notion-app
    alt-tab-macos
    rancher
  ];

  home-manager.backupFileExtension = "bak";
  system.stateVersion = 5;
}
