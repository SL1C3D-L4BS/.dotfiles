# SL1C3D-L4BS dotfiles via Chezmoi (2026)

Dotfiles and system config are managed by [chezmoi](https://www.chezmoi.io). Source state lives in `~/.local/share/chezmoi` (git repo). No bare-repo symlinks—chezmoi copies or templates files into `$HOME` on `chezmoi apply`.

## Build chezmoi from source

1. Install Go: `paru -S go`
2. Either:
   - **Make (recommended):** clone, build, install to `~/.local/bin`:
     ```bash
     bash ~/.local/share/chezmoi/build-chezmoi-from-source.sh
     ```
   - **go install:** `go install github.com/twpayne/chezmoi/v2@latest` (binary in `$HOME/go/bin`; add to `PATH`).
3. Ensure `~/.local/bin` (or `$HOME/go/bin`) is in your `PATH` (already in `.zshrc`).
4. Or use the Arch package: `paru -S chezmoi`

## First-time migration (existing dotfiles → chezmoi)

1. Install chezmoi (see above).
2. Run the migration script (adds current `$HOME` dotfiles into the source):
   ```bash
   bash ~/.config/chezmoi/migrate-to-chezmoi.sh
   ```
3. Review: `chezmoi diff`
4. Apply: `chezmoi apply`
5. Optional: make the source a git repo and push:
   ```bash
   cd $(chezmoi source-path)
   git remote add origin git@github.com:USER/dotfiles.git
   git push -u origin main
   ```

## Daily workflow

| Task | Command |
|------|--------|
| Edit a dotfile (in source) | `chezmoi edit ~/.zshrc` |
| Edit and apply in one go | `chezmoi edit --watch ~/.zshrc` |
| See changes before applying | `chezmoi diff` |
| Apply all | `chezmoi apply` |
| Add a new file | `chezmoi add ~/.config/foo/bar.conf` |
| Re-add after editing target | `chezmoi re-add ~/.zshrc` |
| Update from remote | `chezmoi update` |

## Design: Floating pills + brand (SL1C3D-L4BS)

One coherent look across the stack: **floating pill / slightly rounded rectangles** and **brand colors** (bg `#0d0d0d`, surface `#1a1a1a`, border `#2d2d2d`, fg `#f8f8f2`, accent `#5865F2`, error `#ff5555`).

| Layer | What's applied |
|-------|----------------|
| **Quickshell** | PanelWindow margins (bar floats from screen edges); single rounded pill bar (radius 12); modules as rectangles with radius 8; subtle shadow. |
| **Starship** | Segment/pill format with `bg:surface` / `bg:accent` etc.; all styles use `palettes.brand`. |
| **Zellij** | `ui.pane_frames.rounded_corners true`; theme `brand` (same palette). |
| **Ghostty** | Theme `sl1c3d-l4bs` (full 16 ANSI + cursor/selection); `JetBrainsMono Nerd Font`; window padding. |
| **NvChad** | Rounded float borders (diagnostics, LSP hover/signature); hl_override for WinSeparator, TabLine, FloatTitle; base46 = brand. |

After `chezmoi apply`, restart quickshell/terminal/nvim as needed so changes take effect.

## Source layout (after migration)

- `dot_zshrc` → `~/.zshrc`
- `dot_gitconfig` → `~/.gitconfig`
- `dot_config/` → `~/.config/` (hypr, zellij, quickshell, starship, ghostty, git, chezmoi, nvim custom)

## Symlinks (optional)

By default chezmoi **copies** files. To use **symlinks** for specific targets (e.g. so edits in source reflect immediately), use the `symlink_` prefix and a template for the target path, e.g. in source: `symlink_zshrc.tmpl` with content `{{ .chezmoi.sourceDir }}/dot_zshrc`. See [source state attributes](https://www.chezmoi.io/reference/source-state-attributes/).

## Retiring the old bare repo

After migration and a successful `chezmoi apply`, you can remove the `dot` alias from `.zshrc` and stop using `~/.dotfiles`. The new source of truth is `~/.local/share/chezmoi`. You can keep `~/.dotfiles` as a backup or repurpose it as the remote for the chezmoi source: `cd $(chezmoi source-path) && git remote add origin ~/.dotfiles && git push -u origin main`.
