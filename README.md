# .dotfiles — the_architect | 2026 Elite Workstation

Self-evolving developer machine. Compounds skill, output, revenue.

## Stack

| Layer | Tool | Notes |
|-------|------|-------|
| Host | Arch Linux | Minimal — no dev tooling on host |
| WM | i3 | Modular config.d/, gaps, smart_borders |
| Compositor | picom | GLX, blur, fading, shadows |
| Bar | polybar | xrdb colors, AI status, system metrics |
| Launcher | rofi | Matugen-themed, fuzzy matching |
| Terminal | alacritty | Nerd Font, matugen import |
| Shell | zsh | atuin + zoxide + fzf + starship <100ms |
| Editor | NvChad 2.5+ | LSP/Mason/CodeCompanion, <70ms startup |
| Tooling | Nix + home-manager | All dev runtimes isolated in flakes |
| Dotfiles | chezmoi | age-encrypted secrets, templates |
| Theming | matugen | Wallpaper → palette → all components |

## Bootstrap

```bash
git clone <this-repo> ~/dev/.dotfiles
~/dev/.dotfiles/scripts/bootstrap.sh
```

## Structure

```
.dotfiles/
├── docs/MASTER-SPEC.md
├── home/
│   ├── .config/
│   │   ├── i3/             # Modular: config + config.d/00-50
│   │   ├── polybar/        # Bar + launch script
│   │   ├── rofi/           # Launcher + themes/
│   │   ├── alacritty/      # Terminal + theme import
│   │   ├── nvim/           # NvChad 2.5+ + all plugins
│   │   ├── picom/          # GLX compositor
│   │   ├── shell/          # zshrc + starship.toml
│   │   └── theme/          # matugen config + templates
│   └── .local/bin/         # 27 custom CLIs
├── nix/
│   ├── flake.nix
│   └── home.nix
└── scripts/bootstrap.sh    # One-shot install
```

## Custom CLIs (27)

**Agentic Core:** map-set-schema, map-row, map-to-arrow, verify-parquet, discover-dir, discover-ping-db, discover-sql-tables, discover-sql-headers, discover-csv-headers, sample-csv, ollama-list-models, ollama-generate, ollama-map-headers, audit-parquet, keys-read, keys-rotate

**Developer:** project-scaffold, env-switch, resource-profile, macro-record

**Tools:** snippet-manager, file-browser, history-search, resource-monitor, package-browser, update-manager, license-manager, ai-status-bar, theme-apply, theme-switch

All CLIs: JSON output, pipeable, composable.

## i3 Keybindings

`$mod+Return` terminal · `$mod+d` rofi · `$mod+Tab` windows · `$mod+o` file-browser · `$mod+n` nvim · `$mod+h/j/k/l` focus · `$mod+Shift+t` theme · `$mod+Escape` system mode · `$mod+F12/F11` scratchpad · `$mod+grave` float_term
