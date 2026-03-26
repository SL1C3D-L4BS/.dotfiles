{
  description = "Go project — SL1C3D-L4BS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            go
            gopls
            golangci-lint
            delve
            air
            gotools
          ];
          shellHook = ''
            echo "🔵 Go $(go version | cut -d' ' -f3) | gopls + golangci-lint + delve + air"
          '';
        };
      });
}
