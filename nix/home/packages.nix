# SL1C3D-L4BS — Nix packages (toolchain, languages, LSPs, formatters, linters).
# Configs remain in chezmoi. Install: nix profile install .#default or .#<attr>.
# PATH: Nix profile must be before /usr/bin (set in shell config).
pkgs: with pkgs; {
  # ─── Toolchain ─────────────────────────────────────────────────────────────
  neovim = neovim;
  ripgrep = ripgrep;
  bat = bat;
  eza = eza;
  fd = fd;
  zoxide = zoxide;
  fzf = fzf;
  starship = starship;
  delta = delta;
  lazygit = lazygit;

  # ─── Languages ─────────────────────────────────────────────────────────────
  nodejs = nodejs_22;
  python3 = python313;
  go = go;

  # ─── LSPs ──────────────────────────────────────────────────────────────────
  nil = nil;                           # Nix LSP
  lua-language-server = lua-language-server;

  # ─── Formatters ───────────────────────────────────────────────────────────
  stylua = stylua;
  shfmt = shfmt;
  nixfmt = nixfmt-rfc-style;

  # ─── Linters ──────────────────────────────────────────────────────────────
  shellcheck = shellcheck;
  luacheck = pkgs.lua52Packages.luacheck;
}
