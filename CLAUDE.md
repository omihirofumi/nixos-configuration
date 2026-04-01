# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Nix flake-based dotfiles/system configuration for macOS (aarch64-darwin), using **nix-darwin** for system settings and **home-manager** for user-level config.

## Key Commands

```sh
# Apply all configuration changes (requires sudo)
./bin/switch.sh

# Manual apply with custom user/host
USERNAME="user" HOSTNAME="host" darwin-rebuild switch --flake ".#host" --impure
```

The `--impure` flag is required because `flake.nix` reads `USERNAME` and `HOSTNAME` from environment variables via `builtins.getEnv`.

## Architecture

- **`flake.nix`** — Entry point. Defines a single `darwinConfigurations` output that composes nix-darwin + home-manager. USERNAME/HOSTNAME are read from env vars with defaults.
- **`darwin/`** — System-level nix-darwin config:
  - `configuration.nix` — macOS defaults (dock, finder, keyboard), Homebrew casks/brews, system packages
  - `nixpkgs.nix` — Unfree package allowlist
- **`home/`** — User-level home-manager config:
  - `home.nix` — Root home-manager module; declares packages, imports sub-modules, manages dotfile symlinks (ghostty, karabiner, jj, ideavimrc, oh-my-posh theme)
  - `zsh.nix` / `zsh/functions.nix` — Shell configuration and custom functions
  - `git.nix` — Git config
  - `helix.nix` — Helix editor config
  - `tmux.nix` — tmux config
- **`bin/`** — Helper scripts (`switch.sh`)

## Nix Conventions

- All flake inputs pin to nixpkgs-unstable. jujutsu (jj) is pulled from its own flake input.
- Unfree packages must be explicitly allowlisted in `darwin/nixpkgs.nix`.
- Home-manager uses `useGlobalPkgs` and `useUserPackages` (packages come from the system nixpkgs, not a separate one).
