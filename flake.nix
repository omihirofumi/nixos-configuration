{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    jj.url = "github:jj-vcs/jj";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
  let
    envUsername = builtins.getEnv "USERNAME";
    envHostname = builtins.getEnv "HOSTNAME";
    USERNAME = if envUsername != "" then envUsername else "hirofumiomi";
    HOSTNAME = if envHostname != "" then envHostname else "hirofumiomi";
    system = "aarch64-darwin";
  in
  {
    darwinConfigurations.${HOSTNAME} = nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs USERNAME HOSTNAME; };

      modules = [
        ./darwin/configuration.nix
        ./darwin/nixpkgs.nix

        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.extraSpecialArgs = {
            inherit inputs USERNAME;
          };

          home-manager.users.${USERNAME} = import ./home/home.nix;
        }
      ];
    };
  };
}
