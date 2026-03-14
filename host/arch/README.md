# host/arch — Architecture-facing source (Phase 7)

Single path of record for Arch-host configuration. **No empty directories:** each subdir contains either a real artifact or a migration note pointing to the current live artifact.

- **packages/** — Package lists / install scripts. See migration notes.
- **boot/** — Boot and getty config. See `dot_config/SL1C3D-L4BS/system-config/getty@tty1.service.d/` until migrated.
- **sysctl/** — Sysctl tuning. See `dot_config/SL1C3D-L4BS/system-config/sysctl.d/` until migrated.
- **systemd/** — System (not user) units if any. Currently none; user units live in `dot_config/systemd/user/`.
- **bootstrap/** — Host bootstrap scripts. See `dot_config/SL1C3D-L4BS/system-config/executable_bootstrap.sh` and installers until migrated.

Ledger: `docs/architecture/migration-ledger.md`.
