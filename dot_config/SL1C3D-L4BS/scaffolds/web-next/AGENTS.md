# Project agents — SL1C3D-L4BS

## Required artifacts
- `Plan.md`, `Design.md`, `ThreatModel.md`, `GoldenTasks.md` (see your global OpenClaw templates)

## Golden gates (minimum)
- `~/scripts/validate-configs.sh` (workstation)
- `~/scripts/audit-secrets.sh` (dotfiles provenance)

## Cursor guidance
- Keep changes small and reviewable
- Never commit secrets; prefer env vars + local secret storage
