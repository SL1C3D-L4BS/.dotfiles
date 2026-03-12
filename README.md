<p align="center">
  <img src="assets/icons/Logo.svg" alt="SL1C3D-L4BS" width="120" height="120" />
</p>

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

```bash
# Install chezmoi (Arch)
paru -S chezmoi
# Clone this repo into the source directory, then apply
chezmoi init --apply SL1C3D-L4BS/.dotfiles
```

Existing install: `chezmoi apply` from anywhere (source = `~/.local/share/chezmoi`).

---

## Workflow

| Action | Command |
|--------|--------|
| Edit in source | `chezmoi edit ~/.zshrc` |
| Edit + apply | `chezmoi edit --watch ~/.zshrc` |
| Preview | `chezmoi diff` |
| Apply all | `chezmoi apply` |
| Add new file | `chezmoi add ~/.config/foo/bar.conf` |
| Re-add target | `chezmoi re-add ~/.zshrc` |

Alias: `cm` = chezmoi (in `.zshrc`).

---

## Stack

| Layer | Config | Notes |
|-------|--------|--------|
| **WM** | Hyprland | colors, binds, autostart, programs |
| **Bar** | Quickshell | QML bar + branded hub (dev paths, wallpapers, system) |
| **Terminal** | Ghostty | theme `sl1c3d-l4bs`, JetBrains Mono Nerd Font |
| **Prompt** | Starship | `palettes.brand`, pill segments |
| **Launcher** | Fuzzel | tactical bar, brand colors |
| **Notifications** | Mako | criteria, DND, Hypr binds |
| **FM** | Yazi | theme + openers, SL1C3D-L4BS palette |
| **Editor** | NvChad | custom lua, base46 brand, rounded floats |
| **Multiplexer** | Zellij | rounded panes, theme `brand` |
| **Wallpaper** | Waypaper | `~/assets/wallpapers` |

**Elite CLI (2026):** Atuin (history), Fastfetch (system info), Zoxide (`z`), eza/bat/fd/ripgrep, Delta (git pager), btop (Super+B), Lazygit (Super+G). Install: `~/.config/SL1C3D-L4BS/system-config/install-elite-stack.sh`.

**Cursor (powerhouse):** MCP (GitHub, filesystem, Brave Search) in `~/.cursor/mcp.json`; always-on rule in `~/.cursor/rules/sl1c3d-l4bs-stack.mdc`; `AGENTS.md` at project root; SL1C3D-L4BS theme in Cursor settings (workbench colors + JetBrains Mono Nerd Font). **Icons:** install extensions **Material Icon Theme** (PKief) and **Fluent Icons** (miguelsolorio.fluent-icons); settings preconfigure `workbench.iconTheme` / `workbench.productIconTheme` and Material folder color `#5865F2`. Export `GITHUB_PERSONAL_ACCESS_TOKEN` and `BRAVE_API_KEY` for MCP; restart Cursor after editing `mcp.json`.

**Neovim icons:** `lua/plugins/devicons.lua` overrides nvim-web-devicons with SL1C3D-L4BS palette (languages, DBs, config). Ghostty uses JetBrains Mono Nerd Font so icons render; run `:NvimWebDeviconsHiTest` in NvChad to preview.

---

## Source layout

```
README.md                    →  ~/README.md
dot_zshrc, dot_gitconfig     →  ~/.zshrc, ~/.gitconfig
dot_config/                  →  ~/.config/  (hypr, quickshell, starship, ghostty, fuzzel, mako, yazi, zellij, waypaper, nvim, git, chezmoi, SL1C3D-L4BS/system-config, …)
scripts/                     →  ~/scripts/  (validate-configs.sh)
assets/                      →  ~/assets/   (icons, wallpapers)
```

---

## Validation

After changes or apply:

```bash
~/scripts/validate-configs.sh
```

Checks: Yazi (TOML), Fuzzel (ini), Mako (config + reload), Hypr (sourced files, mako integration). All pass = stack consistent.

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
