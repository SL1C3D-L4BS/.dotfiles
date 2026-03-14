# Core CLI and dev tools — binaries only; configs remain in chezmoi (Phase 8).
# Install: nix profile install .#neovim etc., or use devShell: nix develop.
pkgs: with pkgs; {
  # Core CLI (toolchain class)
  neovim = neovim;
  ripgrep = ripgrep;
  bat = bat;
  eza = eza;
  fd = fd;
  zoxide = zoxide;
  fzf = fzf;
  starship = starship;
  # Git-related
  delta = delta;
  lazygit = lazygit;
  # Optional: uncomment to add to profile
  # nodejs = nodejs_22;
  # python3 = python313;
  # go = go;
}
