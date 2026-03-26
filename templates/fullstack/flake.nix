{
  description = "Full-stack project — SL1C3D-L4BS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Frontend
            nodejs_22
            pnpm
            bun
            typescript
            nodePackages.typescript-language-server
            nodePackages.prettier
            nodePackages.eslint
            # Backend (Python)
            python314
            uv
            ruff
            pyright
            # Database
            postgresql_16
            duckdb
            # Infra
            docker-compose
            kubectl
            terraform
          ];
          shellHook = ''
            echo "🚀 Full-stack | Node $(node --version) + Python $(python --version | cut -d' ' -f2) + Postgres + Docker"
            [ ! -d .venv ] && uv venv .venv
            source .venv/bin/activate 2>/dev/null || true
          '';
        };
      });
}
