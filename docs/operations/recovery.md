## Recovery — Restoring a Working Session

This guide uses:

- Phase 0 inventory (session, configs, units): `docs/inventory/phase0-inventory.md`
- Phase 0 do-not-break list: `docs/inventory/phase0-do-not-break.md`
- Phase 0 contradictions (session model gaps): `docs/inventory/phase0-contradictions.md`

It focuses on **operator steps**, not automated repair.

---

### 1. If Hyprland Fails to Start

1. **Check logs** from a TTY:

   ```bash
   journalctl --user -b | grep -i hypr
   ```

2. **Validate Hyprland configs**:

   ```bash
   ~/scripts/validate-configs.sh
   ```

3. If validation reports missing or invalid Hyprland files:
   - Use `chezmoi diff` to inspect differences.  
   - Reapply from source with an explicit `chezmoi apply` only after confirming the changes.

Rollback is limited to reverting config changes; bootstrap and session architecture remain as defined by the current phase.

---

### 2. If the Bar or Notifications Are Missing

Phase 6: Quickshell and swaync run as systemd user units bound to `graphical-session.target`.

Steps:

1. **Check unit status**:

   ```bash
   systemctl --user status quickshell.service swaync.service
   ```

2. If inactive or failed, reload and start:

   ```bash
   systemctl --user daemon-reload
   systemctl --user enable --now quickshell.service swaync.service
   ```

3. As a fallback, run manually (session-only):

   ```bash
   quickshell &
   swaync &
   ```

4. Re-run `~/scripts/validate-configs.sh` to confirm configs and that unit files are present and enabled.

---

### 3. If AI or Clipboard Flows Fail

- **OpenClaw / AI sidebar:**  
  - Check `openclaw-gateway.service` status:

    ```bash
    systemctl --user status openclaw-gateway.service
    ```

  - Restart if needed:

    ```bash
    systemctl --user restart openclaw-gateway.service
    ```

- **Clipboard history (cliphist):**  
  - Confirm `wl-paste --watch cliphist store` is running.  
  - If not, re-run the Hyprland autostart command from Phase 0 inventory or restart the session.

These steps adhere to the Phase 0 do-not-break list without altering session architecture.

---

### 4. Config Rollback

If recent configuration changes cause regressions:

1. Inspect pending changes:

   ```bash
   chezmoi diff
   ```

2. Use your VCS history in `~/.local/share/chezmoi` to revert commits introducing the issue.  
3. Reapply:

   ```bash
   chezmoi apply
   ```

Recovery at Phase 1 does not attempt to change package owners or introduce new session concepts; it uses the Phase 0 state as the known-good baseline.

