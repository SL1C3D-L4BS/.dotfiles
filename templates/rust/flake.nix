{
  description = "Rust project — SL1C3D-L4BS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        rust = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = [ rust pkgs.pkg-config pkgs.openssl ];
          RUST_BACKTRACE = 1;
          shellHook = ''
            echo "🦀 Rust $(rustc --version | cut -d' ' -f2) | cargo + clippy + rust-analyzer"
          '';
        };
      });
}
