{
  description = "the_architect — 2026 elite workstation flake";

  inputs = {
    nixpkgs.url          = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url                = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-direnv = {
      url                = "github:nix-community/nix-direnv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-direnv, ... }:
    let
      system = "x86_64-linux";
      pkgs   = import nixpkgs { inherit system; config.allowUnfree = true; };
    in
    {
      # Home-manager configuration — apply with:
      #   nix run nixpkgs#home-manager -- switch --flake .#the_architect
      homeConfigurations."the_architect" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit nix-direnv; };
        modules = [ ./home.nix ];
      };

      # Dev shell template — drop into any project as flake.nix
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          # Add project-specific tools here
        ];
      };
    };
}
