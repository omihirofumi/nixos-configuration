{ pkgs, ... }:
let
  toml = pkgs.formats.toml { };

  hxNgserverNix = pkgs.writeShellScriptBin "hx-ngserver-nix" ''
    set -euo pipefail
    ts_probe="${pkgs.nodePackages.typescript}/lib/node_modules"
    ng_probe="${pkgs.angular-language-server}/lib/node_modules"
    if [ ! -d "$ng_probe" ]; then
      ng_probe="."
    fi

    exec ${pkgs.angular-language-server}/bin/ngserver \
      --stdio \
      --tsProbeLocations "$ts_probe" \
      --ngProbeLocations "$ng_probe" \
      "$@"
  '';

  hxTslsNix = pkgs.writeShellScriptBin "hx-typescript-language-server-nix" ''
    set -euo pipefail
    export NODE_PATH="${pkgs.nodePackages.typescript}/lib/node_modules''${NODE_PATH:+:$NODE_PATH}"
    exec ${pkgs.typescript-language-server}/bin/typescript-language-server --stdio "$@"
  '';

  helixLanguages = toml.generate "helix-languages.toml" {
    "language-server" = {
      "angular-ls" = {
        command = "hx-ngserver-nix";
        "required-root-patterns" = [ "angular.json" "project.json" ];
      };

      "typescript-language-server" = {
        command = "hx-typescript-language-server-nix";
        "required-root-patterns" = [ "package.json" "tsconfig.json" "jsconfig.json" ];
      };

      "vscode-html-languageservice" = {
        command = "vscode-html-language-server";
        args = [ "--stdio" ];
      };

      kakehashi = {
        command = "kakehashi";
      };
    };

    language = [
      {
        name = "typescript";
        "language-servers" = [ "angular-ls" "typescript-language-server" ];
      }
      {
        name = "html";
        "language-servers" = [ "angular-ls" "vscode-html-languageservice" ];
      }
      {
        name = "markdown";
        "language-servers" = [ "kakehashi" ];
      }
    ];
  };
in
{
  home.packages = with pkgs; [
    angular-language-server
    typescript-language-server
    vscode-langservers-extracted
    nodePackages.typescript
    hxNgserverNix
    hxTslsNix
  ];

  xdg.configFile."helix/config.toml".source = ./helix/config.toml;
  xdg.configFile."helix/languages.toml".source = helixLanguages;
}
