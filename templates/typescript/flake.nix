{
  description = "TypeScript/Node project — SL1C3D-L4BS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs_22
            pnpm
            bun
            deno
            typescript
            nodePackages.typescript-language-server
            nodePackages.prettier
            nodePackages.eslint
          ];
          shellHook = ''
            echo "⚡ Node $(node --version) | pnpm + bun + deno + ts"
          '';
        };
      });
}
