# nix/shells — devShell definitions

Defines devShells for `nix develop`. Implemented in `default.nix`; wired in `../flake.nix`.

- **default** — Full stack (all packages from `../home/packages.nix`).
- **rust** — Default + rustc, cargo.
- **node** — Default + npm, prettier.
- **python** — Default + pip, black.

Use: `nix develop .#default`, `nix develop .#rust`, etc. (from repo root: `nix develop ./nix#rust`).
