# SL1C3D-L4BS — Copy-paste commands (run in your terminal)

Scripts under `~/scripts`, `~/.config/hypr/scripts`, and `~/.config/SL1C3D-L4BS/system-config/` are now executable. Run the following in order.

**On boot:** OpenClaw gateway starts via Hyprland `exec-once` (full path `~/.openclaw/bin/openclaw gateway start`) and/or systemd user service `openclaw-gateway.service` (enabled). Bar, mako, hypridle, waypaper, quickshell start from `autostart.conf`.

---

## 1. Sync dotfiles (resolve chezmoi prompt)

If chezmoi asked about modified files, either confirm overwrite or force-apply:

```bash
chezmoi apply
```

If it keeps prompting, force-apply then re-add the script so the repo has it executable:

```bash
chezmoi apply --force
cd ~/.local/share/chezmoi
chezmoi re-add .config/SL1C3D-L4BS/system-config/install-openclaw-ollama.sh
git add -A && git status
```

---

## 2. Validate configs

```bash
~/scripts/validate-configs.sh
```

Expect: "Result: all checks passed".

---

## 3. Install hyprlock + hypridle (sudo)

```bash
paru -S hyprlock hypridle
```

Or: `yay -S hyprlock hypridle` or `sudo pacman -S hyprlock hypridle`

---

## 4. Optional: Elite CLI stack (sudo)

```bash
~/.config/SL1C3D-L4BS/system-config/install-elite-stack.sh
```

---

## 5. OpenClaw + Ollama (official: install-cli.sh or npm, no root for OpenClaw)

```bash
~/.config/SL1C3D-L4BS/system-config/install-openclaw-ollama.sh
```

Then add OpenClaw to PATH (e.g. in `~/.zshrc`):

```bash
export PATH="$HOME/.openclaw/bin:$PATH"
```

Optional: pull models (slow):

```bash
~/.config/SL1C3D-L4BS/system-config/install-openclaw-ollama.sh --pull-models
```

---

## 6. OpenClaw workspace (copy templates)

```bash
mkdir -p ~/.openclaw/workspace
cp ~/.config/SL1C3D-L4BS/openclaw-workspace-templates/AGENTS.md \
   ~/.config/SL1C3D-L4BS/openclaw-workspace-templates/SOUL.md \
   ~/.config/SL1C3D-L4BS/openclaw-workspace-templates/USER.md \
   ~/.config/SL1C3D-L4BS/openclaw-workspace-templates/TOOLS.md \
   ~/.openclaw/workspace/
```

---

## 7. Push to GitHub (from chezmoi source)

```bash
cd ~/.local/share/chezmoi
git status
git add -A
git commit -m "chore: sync dotfiles"
git push origin main
```

If nothing to commit, just: `git push origin main`

---

## Scripts made executable (already done)

- `~/get.sh`
- `~/scripts/validate-configs.sh`
- `~/scripts/screenshot-for-readme.sh`
- `~/.config/hypr/scripts/keybinds.sh`
- `~/.config/hypr/scripts/overview.sh`
- `~/.config/hypr/scripts/overview-preview.sh`
- `~/.config/hypr/scripts/openclaw-sidebar.sh`
- `~/.config/hypr/scripts/zellij-branded.sh`
- `~/.config/SL1C3D-L4BS/system-config/install-openclaw-ollama.sh`
- `~/.config/SL1C3D-L4BS/system-config/install-elite-stack.sh`
- `~/.config/SL1C3D-L4BS/system-config/install-dev-stack.sh`
- `~/.config/SL1C3D-L4BS/system-config/install-sysctl.sh`
- `~/.config/SL1C3D-L4BS/system-config/install-pacman-conf.sh`
- `~/.config/SL1C3D-L4BS/system-config/install-getty-autologin.sh`
