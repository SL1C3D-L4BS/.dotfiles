# Package Inventory — Per-Package Map and Migration Ledger

This document is the **single reference** for every package/tool in the SL1C3D-L4BS stack: doc class, current owner, target owner (per Phase 8 policy), config paths, where it is invoked, and rollback commands. It extends the contract in `migration-ledger.md` with a full package-level table.

**Related:** `package-ownership.md` (classes and policy), `migration-ledger.md` (ledger contract and example entries).

---

## 1. Scope and conventions

- **Current owner:** `Arch` (pacman/AUR via install scripts or manual) or `Nix` (in flake and installed via `nix profile install`).
- **Target owner:** From `package-ownership.md` — Arch (session-core, UI-support), Nix-preferred (toolchain, language/runtime), either (operator/diagnostic), negotiated (theme).
- **Config paths:** Under chezmoi source (`~/.local/share/chezmoi` or repo root); all config is chezmoi-owned.
- **Status:** `Arch` (only Arch today), `Nix` (in flake; may or may not be default on PATH), `planned` (candidate for migration, not yet in flake or not yet migrated).

---

## 2. Full per-package table

### 2.1 Session-core (target owner: Arch)

| Artifact ID | Package | Current owner | Target owner | Config paths | Invoked (key) | Status |
|-------------|---------|---------------|--------------|--------------|---------------|--------|
| pkg-hyprland | hyprland | Arch | Arch | dot_config/hypr/** | WM, validate, sl1c3d doctor | Arch |
| pkg-hyprlock | hyprlock | Arch | Arch | dot_config/hypr | binds Super+L, XF86Lock | Arch |
| pkg-hypridle | hypridle | Arch | Arch | dot_config/hypr | hypridle.service, autostart | Arch |
| pkg-hyprpolkitagent | hyprpolkitagent | Arch (AUR) | Arch | — | autostart.conf exec-once | Arch |
| pkg-gnome-keyring | gnome-keyring | Arch | Arch | — | autostart exec-once | Arch |
| pkg-kanshi | kanshi | Arch | Arch | dot_config/kanshi/config | kanshi.service, validate | Arch |
| pkg-xdg-portals | xdg-desktop-portal* | Arch/system | Arch | — | autostart | Arch |

### 2.2 UI-support (target owner: Arch; optional Nix for devShells)

| Artifact ID | Package | Current owner | Target owner | Config paths | Invoked (key) | Status |
|-------------|---------|---------------|--------------|--------------|---------------|--------|
| pkg-quickshell | quickshell | Arch | Arch | dot_config/quickshell/** | quickshell.service, programs (indirect), Bar.qml | Arch |
| pkg-swaync | swaync | Arch | Arch | dot_config/swaync/** | swaync.service, binds swaync-client, validate | Arch |
| pkg-ags | ags | Arch (AUR) | Arch | dot_config/ags/** | ags.service, QuickSettings.tsx, validate | Arch |
| pkg-ghostty | ghostty | Arch | Arch | dot_config/ghostty/** | programs $terminal, all scratchpads, validate | Arch |
| pkg-yazi | yazi | Arch | Arch | dot_config/yazi/** | programs $fileManager, binds, scratchpad, validate | Arch |
| pkg-fuzzel | fuzzel | Arch | Arch | dot_config/fuzzel/fuzzel.ini | programs $menu, binds, keybinds, power-menu, rbw-picker, overview, validate | Arch |
| pkg-waypaper | waypaper | Arch (AUR) | Arch | dot_config/waypaper/config.ini | wallpaper-restore.service, windowrules, validate | Arch |
| pkg-swww | swww | Arch | Arch | waypaper backend | swww.service, autostart Phase 6 | Arch |
| pkg-cliphist | cliphist | Arch (AUR) | Arch | — | clipboard-history.service, binds Super+;, AGS | Arch |
| pkg-wl-clipboard | wl-paste, wl-copy | Arch | Arch | — | clipboard-history, binds, rbw-picker, screenshot, ocr | Arch |

### 2.3 Toolchain (target owner: Nix-preferred)

| Artifact ID | Package | Current owner | Target owner | Config paths | Invoked (key) | Status |
|-------------|---------|---------------|--------------|--------------|---------------|--------|
| pkg-neovim | neovim | Arch + Nix (flake) | Nix-preferred | dot_config/nvim/**, env.conf EDITOR, yazi | binds $EDITOR, Super+Shift+N scratchpad, validate | Nix (in flake) |
| pkg-ripgrep | ripgrep (rg) | Arch + Nix | Nix-preferred | — | scripts/audit-secrets.sh | Nix |
| pkg-bat | bat | Arch + Nix | Nix-preferred | — | elite CLI | Nix |
| pkg-eza | eza | Arch + Nix | Nix-preferred | — | elite CLI | Nix |
| pkg-fd | fd | Arch + Nix | Nix-preferred | — | elite CLI | Nix |
| pkg-zoxide | zoxide | Arch + Nix | Nix-preferred | — | elite CLI | Nix |
| pkg-fzf | fzf | Nix only | Nix-preferred | — | validate theme template list | Nix |
| pkg-starship | starship | Nix only | Nix-preferred | dot_config/starship.toml, matugen | validate, ci/render-sanity | Nix |
| pkg-delta | delta (git-delta) | Arch + Nix | Nix-preferred | dot_config/git/delta.conf | git pager | Nix |
| pkg-lazygit | lazygit | Arch + Nix | Nix-preferred | — | binds Super+G, Super+Shift+G scratchpad | Nix |

### 2.4 Language/runtime (target owner: Nix-preferred)

| Artifact ID | Package | Current owner | Target owner | Config paths | Invoked (key) | Status |
|-------------|---------|---------------|--------------|--------------|---------------|--------|
| pkg-python3 | python3 | Arch (dev-stack, tesseract) | Nix-preferred | theme/generate.py, theme executable_generate.sh | theme generator, validate (TOML/JSON), scratchpad Super+Shift+P, dev-timer | Arch (Nix commented in flake) |
| pkg-nodejs | node, npm | Arch | Nix-preferred | — | openclaw install, ci/render-sanity | Arch (Nix commented in flake) |
| pkg-go | go | — | Nix-preferred | — | — | Nix commented in flake only |

### 2.5 Operator/diagnostic (target owner: either; per-package choice)

| Artifact ID | Package | Current owner | Target owner | Config paths | Invoked (key) | Status |
|-------------|---------|---------------|--------------|--------------|---------------|--------|
| pkg-fastfetch | fastfetch | Arch | either | dot_config/fastfetch/config.jsonc | validate | Arch |
| pkg-btop | btop | Arch | either | — | binds /usr/bin/btop, Super+Shift+B scratchpad, validate | Arch |
| pkg-atuin | atuin | Arch | either | dot_config/atuin/config.toml, themes/sl1c3d.toml | atuin.service, validate, backup | Arch |
| pkg-restic | restic | Arch | either | — | restic-backup.service/timer, backup.sh, validate | Arch |
| pkg-lazydocker | lazydocker | Arch (AUR) | either | — | binds Super+Shift+K scratchpad, validate | Arch |

### 2.6 Theme/asset (target owner: negotiated; initial Arch)

| Artifact ID | Package | Current owner | Target owner | Config paths | Invoked (key) | Status |
|-------------|---------|---------------|--------------|--------------|---------------|--------|
| pkg-matugen | matugen | Arch (AUR) | negotiated | dot_config/matugen/** | theme-propagation → sl1c3d theme apply, waypaper post_command, validate | Arch |

### 2.7 Other (media, security, recording; no Nix migration in scope by default)

| Artifact ID | Package | Current owner | Target owner | Config paths | Invoked (key) | Status |
|-------------|---------|---------------|--------------|--------------|---------------|--------|
| pkg-satty | satty | Arch | Arch | — | screenshot.sh, validate | Arch |
| pkg-hyprsunset | hyprsunset | Arch | Arch | dot_config/hypr/hyprsunset.conf | autostart, binds F10, validate | Arch |
| pkg-wf-recorder | wf-recorder | Arch | Arch | — | record-toggle.sh, validate | Arch |
| pkg-hyprpicker | hyprpicker | Arch | Arch | — | binds Super+Shift+C, validate | Arch |
| pkg-rbw | rbw | Arch | Arch | dot_config/rbw/config.json | rbw-picker.sh, binds Super+Shift+;, validate | Arch |
| pkg-grim | grim | Arch | Arch | — | screenshot, ocr-screen, screenshot-for-readme | Arch |
| pkg-slurp | slurp | Arch | Arch | — | screenshot, ocr, record-toggle | Arch |
| pkg-mpv | mpv | Arch | Arch | — | validate | Arch |
| pkg-cava | cava | Arch | Arch | — | binds Super+Shift+V scratchpad, validate | Arch |
| pkg-tesseract | tesseract | Arch | Arch | — | ocr-screen.sh, validate | Arch |
| pkg-bluetui | bluetui | Arch (AUR) | Arch | — | binds Super+Shift+X scratchpad, validate | Arch |
| pkg-openclaw | openclaw | script/node or install-cli | — | dot_config/openclaw-workspace-templates | openclaw-gateway.service, binds Super+Shift+A | other |
| pkg-ollama | ollama | Arch (AUR) | — | — | OpenClaw backend | Arch |
| pkg-chezmoi | chezmoi | Arch (paru/yay) or manual | — | .chezmoi.toml.tmpl | get.sh, deploy, validate, sl1c3d doctor | Arch/other |

---

## 3. Rollback commands (Phase 8 — Nix ↔ Arch)

For each package **currently in the Nix flake** (`nix/home/packages.nix`), the following rollback applies when reverting to Arch as the sole owner.

| Artifact ID | Rollback (Nix → Arch) |
|-------------|------------------------|
| pkg-neovim | `nix profile uninstall .#neovim` (or remove from flake and reinstall profile). Install Arch: `sudo pacman -S neovim` or AUR. Ensure `nvim` and `EDITOR` resolve to Arch binary. |
| pkg-ripgrep | `nix profile uninstall .#ripgrep`. Install: `sudo pacman -S ripgrep`. |
| pkg-bat | `nix profile uninstall .#bat`. Install: `sudo pacman -S bat`. |
| pkg-eza | `nix profile uninstall .#eza`. Install: `sudo pacman -S eza`. |
| pkg-fd | `nix profile uninstall .#fd`. Install: `sudo pacman -S fd`. |
| pkg-zoxide | `nix profile uninstall .#zoxide`. Install: `sudo pacman -S zoxide`. |
| pkg-fzf | `nix profile uninstall .#fzf`. Install: `sudo pacman -S fzf`. |
| pkg-starship | `nix profile uninstall .#starship`. Install: `sudo pacman -S starship`. |
| pkg-delta | `nix profile uninstall .#delta`. Install: `sudo pacman -S git-delta` or AUR. |
| pkg-lazygit | `nix profile uninstall .#lazygit`. Install: `sudo pacman -S lazygit` or via elite-stack script. |

**PATH:** When Nix is owner, Nix profile must be before `/usr/bin` in PATH. When reverting to Arch, remove or reorder Nix profile so the Arch binary is used; document in bootstrap and shell config per `package-ownership.md`.

---

## 4. Hardcoded paths and Nix

| Location | Current value | Note |
|----------|----------------|------|
| dot_config/hypr/binds.conf | `exec, /usr/bin/btop` | Super+B. If btop is ever provided by Nix, change to `exec, btop` so PATH decides, or keep Arch-only for this bind. |
| dot_config/systemd/user/*.service | `ExecStart=/usr/bin/<binary>` | Session/UI units (quickshell, swaync, swww, hypridle, kanshi, atuin, waypaper, wl-paste) use absolute paths; leave as Arch for session daemons per package-ownership. |

---

## 5. Install script reference

| Script | Packages (summary) |
|--------|---------------------|
| executable_install-elite-stack.sh | atuin, fastfetch, btop, git-delta, zoxide, eza, bat, fd, ripgrep, lazygit |
| executable_install-dev-stack.sh | npm, python-pip, python-pipx, deno, docker, docker-compose, kubectl, terraform, dotnet-sdk, jdk17-openjdk, php, ruby, zig, uv, base-devel, gcc, clang, cmake, ollama-bin |
| install-2026-masterclass.sh | age, swaync, matugen-bin, satty, kanshi, hyprsunset, wf-recorder, hyprpicker, hyprpolkitagent, mpv, swayimg, zathura, cava, tesseract, restic, ncspot, lazydocker-bin, rbw, bluez, bluetui, zen-browser, nwg-look, gnome-keyring, noto-fonts, adw-gtk-theme, qt6ct, etc. |
| nix/home/packages.nix | neovim, ripgrep, bat, eza, fd, zoxide, fzf, starship, delta, lazygit (optional: nodejs, python3, go) |

---

## 6. Ledger entries for Nix flake packages

When Phase 8 executes or updates migrations, each package in the flake should have a corresponding entry in `migration-ledger.md` (or this inventory) with status `planned`, `in-progress`, or `completed`. The table in §2 and the rollback table in §3 provide the artifact IDs, current/target owners, and rollback commands; ledger entries can reference this document for the full map.

**Example ledger entry (reference):**

```text
Artifact ID: pkg-neovim
Current path: Arch package (pacman/AUR) or Nix profile
Target path: Nix flake (nix/home/packages.nix) — already present
Current owner: Arch packages (or Nix if migrated)
Target owner: Nix packages (Nix-preferred per package-ownership)
Config paths: dot_config/nvim/**, dot_config/hypr/env.conf (EDITOR), dot_config/yazi (open action)
Rollback: See docs/architecture/package-inventory.md §3.
Status: in flake; migration status (Arch vs Nix on PATH) per environment
```
