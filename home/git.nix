{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name  = "omihirofumi";
        email = "99390907+omihirofumi@users.noreply.github.com";
      };

      core = {
        excludesFile = "${config.home.homeDirectory}/.config/git/ignore";
        pager = "delta";
      };

      interactive = {
        diffFilter = "delta --color-only";
      };

      delta = {
        navigate = true;
        dark = true;
      };

      merge = {
        conflictStyle = "zdiff3";
      };

      rebase = {
        autoSquash = true;
      };

      url = {
        "git@github.com:" = {
          pushInsteadOf = "https://github.com/";
        };
      };

      ghq = {
        root = "~/hobby";

        "https://github.com/alpdr/" = {
          root = "~/work";
        };
      };
    };
  };

  xdg.configFile."git/ignore".source = ./git/ignore;

  home.packages = with pkgs; [
    delta
  ];
}
