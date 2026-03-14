## Troubleshooting — Common Issues

This guide is backed by:

- Phase 0 inventory (`validate-configs.sh`, session daemons, configs): `docs/inventory/phase0-inventory.md`
- Phase 0 do-not-break list: `docs/inventory/phase0-do-not-break.md`

It focuses on using existing tools (especially `~/scripts/validate-configs.sh`) before future doctor/validate subcommands exist.

---

### 1. Quick Health Check

Run:

```bash
~/scripts/validate-configs.sh
```

Interpretation:

- ✔ entries confirm presence and basic validity.  
- ✘ entries point to missing or invalid configs.  
- SKIP entries document runtime-only checks that are intentionally not enforced.

Use this as the first step before editing configs or rerunning `chezmoi apply`.

---

### 2. Config Drift After Changes

Symptoms:

- Validation reports missing theme files, QML components, or Hyprland configs.  
- Visual regressions in bar, notifications, or AGS.

Actions:

1. Inspect diffs in the chezmoi source:

   ```bash
   cd ~/.local/share/chezmoi
   git status
   git diff
   ```

2. Revert or adjust changes as needed.  
3. Reapply explicitly:

   ```bash
   chezmoi apply
   ```

This process maintains the Phase 0 guarantee that config definitions live in the repo.

---

### 3. Systemd User Services Misbehaving

Before Phase 6, only a subset of services (e.g. `openclaw-gateway.service`, `atuin.service`, `restic-backup.service`, `kanshi.service`) run as user units.

Steps:

```bash
systemctl --user status openclaw-gateway.service
systemctl --user status atuin.service
```

If a service fails:

- Check logs:

  ```bash
  journalctl --user -u openclaw-gateway.service
  ```

- Restart as needed:

  ```bash
  systemctl --user restart openclaw-gateway.service
  ```

Later phases will extend this section to cover the durable-daemon migration set; Phase 1 documents the pattern without anticipating units that do not yet exist.

---

### 4. When to Avoid Automatic Fixes

Until `sl1c3d repair` is implemented in Phase 3:

- Avoid ad-hoc scripts that mutate configs on your behalf.  
- Prefer:
  - Manual adjustments in the chezmoi source.  
  - Explicit `chezmoi apply`.  
  - Validation via `~/scripts/validate-configs.sh`.

This preserves a clean separation between configuration definition (repo) and runtime state (home directory) per the Phase 0 decisions.

