{
  description = "Python project — SL1C3D-L4BS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            python314
            uv
            ruff
            pyright
            debugpy
          ];
          shellHook = ''
            echo "🐍 Python $(python --version | cut -d' ' -f2) | uv + ruff + pyright"
            [ ! -d .venv ] && uv venv .venv
            source .venv/bin/activate
          '';
        };
      });
}
