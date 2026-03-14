<p align="center">
  <img src="assets/icons/Logo.svg" alt="SL1C3D-L4BS" width="120" height="120" />
</p>

```
  ██████  ██▓     ██▓ ▄████▄  ▓█████ ▓█████▄  ██▓    ▄▄▄       ▄▄▄▄     ██████ 
▒██    ▒ ▓██▒    ▓██▒▒██▀ ▀█  ▓█   ▀ ▒██▀ ██▌▓██▒   ▒████▄    ▓█████▄ ▒██    ▒ 
░ ▓██▄   ▒██░    ▒██▒▒▓█    ▄ ▒███   ░██   █▌▒██░   ▒██  ▀█▄  ▒██▒ ▄██░ ▓██▄   
  ▒   ██▒▒██░    ░██░▒▓▓▄ ▄██▒▒▓█  ▄ ░▓█▄   ▌▒██░   ░██▄▄▄▄██ ▒██░█▀    ▒   ██▒
▒██████▒▒░██████▒░██░▒ ▓███▀ ░░▒████▒░▒████▓ ░██████▒▓█   ▓██▒░▓█  ▀█▓▒██████▒▒
▒ ▒▓▒ ▒ ░░ ▒░▓  ░░▓  ░ ░▒ ▒  ░░░ ▒░ ░ ▒▒▓  ▒ ░ ▒░▓  ░▒▒   ▓▒█░░▒▓███▀▒▒ ▒▓▒ ▒ ░
░ ░▒  ░ ░░ ░ ▒  ░ ▒ ░  ░  ▒    ░ ░  ░ ░ ▒  ▒ ░ ░ ▒  ░ ▒   ▒▒ ░▒░▒   ░ ░ ░▒  ░ ░
░  ░  ░    ░ ░    ▒ ░░           ░    ░ ░  ░   ░ ░    ░   ▒    ░    ░ ░  ░  ░  
      ░      ░  ░ ░  ░ ░         ░  ░   ░        ░  ░     ░  ░ ░            ░  
                     ░                ░                             ░          
```

# **SL1C3D-L4BS** · Dotfiles

**Arch · Hyprland · Ghostty · Quickshell · Starship · Zellij · NvChad · Fuzzel · Yazi · Mako · Waypaper**

Single source of truth for a principled Linux workstation. Managed with [chezmoi](https://www.chezmoi.io); one apply, one stack, one brand.

---

## Brand

| Token   | Hex       | Use            |
|--------|-----------|----------------|
| **bg** | `#0d0d0d` | Background     |
| **surface** | `#1a1a1a` | Panels, floats |
| **border**  | `#2d2d2d` | Dividers       |
| **fg** | `#f8f8f2` | Text           |
| **accent**  | `#5865F2` | Primary UI     |
| **logo**    | `#b366ff` | Brand purple   |
| **error**   | `#ff5555` | Alerts         |

UI/UX: floating pills, rounded corners (radius 8–12), JetBrains Mono Nerd Font, minimal chrome.

---

## Quick start

**One-command install:** (replace `REPO_URL` with your repo, e.g. `https://github.com/you/SL1C3D-L4BS-dotfiles`)

```bash
bash <(curl -sL https://raw.githubusercontent.com/OWNER/REPO/main/get.sh) REPO_URL
```

Manual:

```bash
# Install chezmoi (Arch)
paru -S chezmoi
# Clone this repo into the source directory, then apply
chezmoi init --apply SL1C3D-L4BS/.dotfiles
```

Existing install: `chezmoi apply` from anywhere (source = `~/.local/share/chezmoi`).

### After install / First run

1. Select **Hyprland** at login.
2. Run `~/scripts/validate-configs.sh`.
3. Open the **hub** (click the bar logo) for dev paths, wallpapers, system.
4. Press **Super+/** for keybinds.

---

## Keybinds

| Action | Key |
|--------|-----|
| Terminal | Super+Return |
| Close window | Super+Q |
| Exit / shutdown | Super+M |
| File manager | Super+F |
| btop | Super+B |
| Lazygit | Super+G |
| Toggle float | Super+V |
| Launcher | Super+Space |
| Toggle split | Super+J |
| Workspaces 1–10 | Super+1..0 |
| Move window to workspace | Super+Shift+1..0 |
| Scratchpad (toggle / move) | Super+S / Super+Shift+S |
| Focus direction | Super+Arrow |
| Lock screen | Super+L |
| AI sidebar (OpenClaw) | Super+Shift+A |
| Window overview | Super+A |
| Window overview (preview) | Super+Tab |
| Keybinds help | Super+/ |
| Notifications (dismiss / DND) | Super+N / Super+D |

---

## Workflow

| Action | Command |
|--------|--------|
| Edit in source | `chezmoi edit ~/.zshrc` |
| Preview | `chezmoi diff` |
| Apply all | `chezmoi apply` (run explicitly when you are ready) |
| Add new file | `chezmoi add ~/.config/foo/bar.conf` |
| Re-add target | `chezmoi re-add ~/.zshrc` |

Alias: `cm` = chezmoi (in `.zshrc`).

**Customization:** To add personal Hyprland keybinds or settings without editing the repo, edit `~/.config/hypr/custom.conf` (sourced last). To keep your edits across `chezmoi apply`, run `chezmoi forget ~/.config/hypr/custom.conf` after editing. One-command install uses `get.sh` from the repo; document your repo URL in the one-liner for new users.

---

## Operator CLI (sl1c3d)

The `sl1c3d` CLI is the workstation operator surface for SL1C3D-L4BS:

- `sl1c3d doctor` — environment and dependency health (severity: fatal / degraded / informational).
- `sl1c3d validate` — runs `~/scripts/validate-configs.sh` for config contract checks.
- `sl1c3d repair` — default non-destructive repair with explicit `--apply` mode.
- `sl1c3d benchmark` — benchmark entrypoint (Phase 5).
- `sl1c3d theme` — theme apply/inspect entrypoint (Phase 4).
- `sl1c3d edition` — delegates to `sl1c3d-edition` (set/get/list/apply).
- `sl1c3d bootstrap` — first-time workstation setup (Nix, chezmoi, host bootstrap).
- `sl1c3d session` — optional helpers around systemd user units.

`sl1c3d` installs under `~/.config/SL1C3D-L4BS/bin/` and is exposed on `PATH` by the shell configuration managed in this repo.

---

## Stack

| Layer | Config | Notes |
|-------|--------|--------|
| **WM** | Hyprland | colors, binds, autostart, programs; lock (Super+L), idle (hypridle) |
| **Bar** | Quickshell | QML bar + branded hub (dev paths, wallpapers, system) |
| **Terminal** | Ghostty | theme `sl1c3d-l4bs`, JetBrains Mono Nerd Font |
| **Prompt** | Starship | `palettes.brand`, pill segments |
| **Launcher** | Fuzzel | tactical bar, brand colors |
| **Notifications** | Mako | criteria, DND, Hypr binds |
| **FM** | Yazi | theme + openers, SL1C3D-L4BS palette |
| **Editor** | NvChad | custom lua, base46 brand, rounded floats |
| **Multiplexer** | Zellij | rounded panes, theme `brand` |
| **Wallpaper** | Waypaper | `~/assets/wallpapers` |

**Lock & idle:** hyprlock (Super+L) and hypridle (auto-lock after 5 min, optional dim/suspend). Config: `~/.config/hypr/hyprlock.conf`, `~/.config/hypr/hypridle.conf`. Install: `paru -S hyprlock hypridle`.

**AI (OpenClaw + Ollama):** Sidebar at Super+Shift+A (or hub → AI (OpenClaw)); gateway http://127.0.0.1:18789/. Multi-agent team: PM, Researcher, Engineer, Ops. Install: `~/.config/SL1C3D-L4BS/system-config/install-openclaw-ollama.sh`. Requires Node 22+, Ollama, then `npm install -g openclaw@latest`. Copy workspace templates from `~/.config/SL1C3D-L4BS/openclaw-workspace-templates/` to `~/.openclaw/workspace/`. Pull models: `ollama pull qwen2.5-coder:7b`, `ollama pull deepseek-r1:7b`. Plugins and hooks: `~/.openclaw/plugins/`; see `~/.config/SL1C3D-L4BS/OPENCLAW-PLUGINS.md`. [OpenClaw docs](https://docs.openclaw.ai), [Ollama](https://ollama.com).

**Developer workstation (notes, streaming, API, DB):** Run `bash ~/.config/SL1C3D-L4BS/system-config/install-developer-workstation.sh` to add Obsidian, OBS Studio, Bruno, DBeaver, Beekeeper, fnm, bun, k9s, postgresql, redis, aichat, etc. Do **not** paste multi-line install blocks into zsh — you may see `command not found: #` or `unknown file attribute: i`; use the script instead.

**Elite CLI (2026):** Atuin (history), **Fastfetch** (system info; Linux ASCII logo from [fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch) in `~/.config/fastfetch/logo.txt`, full SL1C3D-L4BS colors in `config.jsonc` — accent `#5865F2`, logo `#b366ff`, fg `#f8f8f2`), Zoxide (`z`), eza/bat/fd/ripgrep, Delta (git pager), btop (Super+B), Lazygit (Super+G). Install: `~/.config/SL1C3D-L4BS/system-config/install-elite-stack.sh`.

**Cursor (powerhouse):** MCP (GitHub, filesystem, Brave Search) in `~/.cursor/mcp.json`; always-on rule in `~/.cursor/rules/sl1c3d-l4bs-stack.mdc`; `AGENTS.md` at project root; SL1C3D-L4BS theme in Cursor settings (workbench colors + JetBrains Mono Nerd Font). **Icons:** install extensions **Material Icon Theme** (PKief) and **Fluent Icons** (miguelsolorio.fluent-icons); settings preconfigure `workbench.iconTheme` / `workbench.productIconTheme` and Material folder color `#5865F2`. Export `GITHUB_PERSONAL_ACCESS_TOKEN` and `BRAVE_API_KEY` for MCP; restart Cursor after editing `mcp.json`.

**Neovim icons:** `lua/plugins/devicons.lua` overrides nvim-web-devicons with SL1C3D-L4BS palette (languages, DBs, config). Ghostty uses JetBrains Mono Nerd Font so icons render; run `:NvimWebDeviconsHiTest` in NvChad to preview.

---

## Screenshots

Screenshots for the repo live in `assets/screenshots/`. Capture with:

```bash
~/scripts/screenshot-for-readme.sh bar.png
```

Requires `grim` and `slurp` (e.g. `paru -S grim slurp`). Run from a Wayland session; select a region or Cancel for full screen.

---

## Source layout

```
README.md                    →  ~/README.md
dot_zshrc, dot_gitconfig     →  ~/.zshrc, ~/.gitconfig
dot_config/                  →  ~/.config/  (hypr, quickshell, starship, ghostty, fastfetch, fuzzel, mako, yazi, zellij, waypaper, nvim, git, chezmoi, SL1C3D-L4BS/system-config, openclaw-workspace-templates, …)
scripts/                     →  ~/scripts/  (validate-configs.sh, screenshot-for-readme.sh)
assets/                      →  ~/assets/   (icons, wallpapers, screenshots)
```

---

## Validation

After changes or apply:

```bash
~/scripts/validate-configs.sh
```

Checks: Yazi (TOML), Fuzzel (ini), Mako (config + reload), Hypr (all 9 sourced files, mako integration). All pass = stack consistent.

---

## Design system (floating pills)

One coherent look: **rounded rectangles** and **brand palette** across the stack.

- **Quickshell** — Bar floats from edges; pill radius 12; hub modules radius 8.
- **Starship** — Segment pills; `palettes.brand`.
- **Zellij** — Rounded pane frames; theme `brand`.
- **Ghostty** — Full 16 ANSI + cursor/selection; window padding.
- **NvChad** — Rounded float borders; WinSeparator, TabLine, FloatTitle; base46 brand.

Restart quickshell/terminal/nvim after apply as needed.

---

## License & attribution

Dotfiles and brand **SL1C3D-L4BS** — 2026. NvChad and other upstream projects retain their respective licenses.
