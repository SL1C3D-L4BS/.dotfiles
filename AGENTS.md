# SL1C3D-L4BS · Agent instructions

## AI stack (OpenClaw + Ollama)

- **OpenClaw + Ollama**: Multi-agent team (PM, Researcher, Engineer, Ops). Use OpenClaw for sidebar chat (Super+Shift+A) and agent team; use Cursor for in-repo edits and MCP.
- After Hypr/config changes, run `~/scripts/validate-configs.sh`.

## Code and config style

- Prefer existing patterns; match SL1C3D-L4BS brand (colors, rounded pills, JetBrains Mono Nerd Font).
- Config: `~/.config/`; dotfiles managed by chezmoi (source `~/.local/share/chezmoi`). Use `chezmoi edit <path>` or edit in source then `chezmoi apply`.
- No extra READMEs; one root README. No redundant scripts; keep install scripts in `~/.config/SL1C3D-L4BS/system-config/`.

## Commands

- Apply dotfiles: `chezmoi apply`
- Validate stack: `~/scripts/validate-configs.sh`
- Sync and push: `chezmoi apply` then from `$(chezmoi source-path)`: `git add -A && git commit -m "..." && git push`

## MCP (Cursor)

If GitHub or Brave Search MCP is used, export before starting Cursor:

- `GITHUB_PERSONAL_ACCESS_TOKEN` (GitHub MCP)
- `BRAVE_API_KEY` (Brave Search MCP)

Optional: add to `~/.zshrc` or use a keyring so Cursor inherits them.

## Icons (Cursor + Neovim)

- **Cursor:** Install extensions **Material Icon Theme** (PKief.material-icon-theme) and **Fluent Icons** (miguelsolorio.fluent-icons). Settings already set `workbench.iconTheme` and `workbench.productIconTheme` plus Material folder color.
- **Neovim:** Devicons overrides in `~/.config/nvim/lua/plugins/devicons.lua`; terminal (Ghostty) must use a Nerd Font. Verify with `:NvimWebDeviconsHiTest`.
