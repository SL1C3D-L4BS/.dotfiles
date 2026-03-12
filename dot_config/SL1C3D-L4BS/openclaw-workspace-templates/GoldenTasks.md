# SL1C3D-L4BS — Golden tasks (agent regression suite)

Golden tasks are canonical workflows that must remain reliable as the stack evolves.

## How to use
- Pick 3–5 tasks before any substantial change and re-run after.
- If a task fails twice, promote a guardrail into `SOUL.md`, `TOOLS.md`, or a validation script.

## Tasks
### GT-001: “No secrets in chezmoi”
- **Scenario**: A change touches docs/configs.
- **Acceptance**: `~/scripts/audit-secrets.sh` passes.

### GT-002: “One apply, one validate”
- **Scenario**: Update Hypr/Quickshell/Mako/Yazi/Fuzzel configs.
- **Acceptance**: `~/scripts/validate-configs.sh` passes.

### GT-003: “Edition switch is deterministic”
- **Scenario**: Switch edition via `sl1c3d-edition set <edition>`.
- **Acceptance**: `~/.config/hypr/edition.conf` sources the correct overlay; Quickshell shows the edition.

### GT-004: “AI surface launches without secrets in dotfiles”
- **Scenario**: Press Super+Shift+A.
- **Acceptance**: OpenClaw UI opens; script never reads token from synced config. Token can be supplied via env var or local secret file.

### GT-005: “Control plane actions are safe”
- **Scenario**: Use hub buttons (Validate, Reload_Hypr, AI_Gateway).
- **Acceptance**: Actions succeed or fail gracefully; no config corruption.

