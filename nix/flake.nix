# SL1C3D-L4BS Nix Mode A (Phase 8). Flakes + packages + devShells only; no Home Manager.
# Configs remain in chezmoi. Install: nix profile install .#<attr> or nix develop.
{
  description = "SL1C3D-L4BS Nix packages and devShells";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    homePackages = import ./home/packages.nix pkgs;
    pathList = pkgs.lib.attrValues homePackages;
  in {
    packages.${system} = homePackages // {
      default = pkgs.buildEnv {
        name = "sl1c3d-cli";
        paths = pathList;
      };
    };
    devShells.${system}.default = pkgs.mkShell {
      name = "sl1c3d-l4bs";
      buildInputs = pathList;
    };
  };
}
