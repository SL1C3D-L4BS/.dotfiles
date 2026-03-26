{
  description = "C/C++ project — SL1C3D-L4BS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            gcc
            clang
            clang-tools
            cmake
            ninja
            gdb
            lldb
            pkg-config
            valgrind
            ccache
          ];
          shellHook = ''
            echo "⚙ C/C++ | GCC $(gcc --version | head -1 | grep -oP '\d+\.\d+\.\d+') + Clang + CMake + GDB"
          '';
        };
      });
}
