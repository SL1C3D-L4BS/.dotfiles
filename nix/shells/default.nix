# SL1C3D-L4BS devShells — default (full stack) + language-specific.
# Use: nix develop .#default, nix develop .#rust, etc.
pkgs: pathList:
let
  mk = name: buildInputs: pkgs.mkShell {
    inherit name buildInputs;
  };
in {
  default = mk "sl1c3d-l4bs" pathList;
  rust = mk "sl1c3d-rust" (pathList ++ [ pkgs.rustc pkgs.cargo ]);
  node = mk "sl1c3d-node" (pathList ++ [ pkgs.nodePackages_latest.npm pkgs.nodePackages_latest.prettier ]);
  python = mk "sl1c3d-python" (pathList ++ [ pkgs.python313Packages.pip pkgs.python313Packages.black ]);
}
