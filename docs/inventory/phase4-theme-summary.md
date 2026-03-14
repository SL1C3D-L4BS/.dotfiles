# Phase 4 — Theme Source-of-Truth Summary

## Deliverables

1. **Canonical repo theme token source:** `theme.tokens.toml` at repo root (colors, spacing, radius, motion 120/180/260, typography, semantic roles).
2. **Generator pipeline:** `dot_config/SL1C3D-L4BS/theme/generate.sh` + `generate.py`; single authority; invoked only via `sl1c3d theme apply`.
3. **Runtime theme JSON:** Generated to `~/.config/sl1c3d/theme.json`; not canonical; in .gitignore when under repo.
4. **Consumer outputs:** BrandTheme.qml, sl1c3d-tokens.scss, hypr/colors.conf, ghostty/themes/sl1c3d-l4bs — all generated from `theme.tokens.toml`.
5. **Documentation:** `docs/design-system/tokens.md` and `motion.md` updated with file contract and canonical source.

## One Generator Pipeline

Only one authoritative pipeline exists: `sl1c3d theme apply` → `generate.sh` → `generate.py` → reads `theme.tokens.toml`, writes Layer B + Layer C. No matugen or other script is a second authority; matugen may be called from within the pipeline later if needed.

## CI Render-Sanity

All Phase 0 render targets still pass after Phase 4 (hyprland.conf, Quickshell Bar.qml/BrandTheme.qml, AGS theme surface, Starship config, runtime theme.json path).

## Locations Where Theme Constants Previously Existed (Now Generated)

| Location | Previous state | Phase 4 state |
|----------|----------------|---------------|
| `dot_config/quickshell/bar/BrandTheme.qml` | Hand-written; motion slow was 240 ms | Generated; motion slow = 260 ms |
| `dot_config/ags/sl1c3d-tokens.scss` | Hand-written; motion slow was 280 ms | Generated; motion slow = 260 ms |
| `dot_config/hypr/colors.conf` | Hand-written color variables | Generated from theme.tokens.toml |
| `dot_config/ghostty/themes/sl1c3d-l4bs` | Hand-written ANSI palette | Generated from theme.tokens.toml |

No duplicate theme constants remain in these files; they are regenerated from the single canonical source. Other files (e.g. Bar.qml) consume tokens via BrandTheme or SCSS imports and do not define their own color/motion constants.
