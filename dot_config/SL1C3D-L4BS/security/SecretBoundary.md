# SL1C3D-L4BS — Secret Boundary Contract (strict local-only)

## Rule 0 (non-negotiable)
**No secret values may exist in chezmoi-managed files** (including documentation, scripts, or templates).

This includes tokens, API keys, private keys, cookies, and session credentials.

## Allowed in dotfiles
- **Mentions** of env var names (e.g. `BRAVE_API_KEY`) for documentation.
- Placeholders like `<set-me>` or `CHANGEME` (must not resemble real secret formats).
- Paths pointing to machine-local secret files (outside chezmoi source).

## Disallowed in dotfiles
- Any real token string (OpenClaw gateway token, GitHub PAT, etc.).
- Any private key material (SSH/GPG).
- Any bearer tokens or Authorization headers with values.

## Approved secret storage locations
These locations are machine-local and must not be in chezmoi source:
- `~/.openclaw/secrets/` (OpenClaw gateway token file, etc.)
- Keyring/pass/age-vault (future extension)

## Enforcement
- `~/scripts/audit-secrets.sh` must pass before shipping changes.
- `.local/share/chezmoi/.secret-audit-allowlist` may include **only** env var names / benign markers (never real values).

