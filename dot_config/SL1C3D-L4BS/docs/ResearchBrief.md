# SL1C3D-L4BS — Research Brief (Fullstack Glass OS)

This brief distills competitor/UI research into implementable decisions for SL1C3D-L4BS.

## Hyprland glass engine (core mechanism)
Hyprland supports **Layer Rules** that apply to layer-shell surfaces (bars, launchers, shells).

From Hyprland Window/Layer Rules docs (updated 2026-03-09), relevant effects:
- `blur on`
- `blur_popups on`
- `ignore_alpha <0..1>`
- `dim_around on` (use only for true modals)

**Implementable decision**:
- Add layerrules for `match:namespace = quickshell` (confirmed namespace in your session).
- Once AGS is running, discover its namespace(s) via `hyprctl layers` and add matching layerrules.

## Confirmed namespace (your stack)
Your bar surfaces currently show:
- `namespace: quickshell`

This is the exact hook for compositor-level glass blur behind Quickshell.

## ML4W (what to steal)
ML4W’s “premium” feel comes from a **control-plane + variations** model:
- Settings apps (Welcome/Settings/Hyprland Settings) provide UI-driven configuration.
- Theme switching and “variations” enable changing blur/animations/window styling without editing raw configs.
- Quicklinks model: a small data file defines bar shortcuts; UI consumes it.

**Implementable decisions**:
- Add a SL1C3D “variations” system (JSON) to switch glass strength, opacity, animations, and module toggles.
- Make the Control Plane Hub data-driven (JSON → UI), not hard-coded rows.

## Omarchy (workflow UX to steal)
Omarchy’s menu is a dmenu-driven controller (`walker --dmenu`) with a strict pattern:
- Edit a config in terminal editor
- On exit, restart the relevant process automatically

**Implementable decisions**:
- Provide a single “Setup” hub surface (in Quickshell) that launches **edit+restart wrappers**.
- Each wrapper maps a config target → restart command(s) → optional validate.

## AGS (why it’s the right hybrid choice)
AGS excels at:
- Quicksettings panels
- OSD (volume/brightness)
- Powermenu/logout modals
- Unified SCSS tokens and motion

**Implementable decisions**:
- Use AGS strictly for: quicksettings/OSD/powermenu.
- Keep Quickshell as: bar + control-plane hub + lightweight popups.
- Use one shared token set: Quickshell `BrandTheme.qml` + AGS SCSS variables.

## Token system + glass design principles (subtle glass)
To be “subtle but dominant”:
- Use compositor blur + `ignore_alpha` tuned to avoid halo artifacts on rounded corners.
- Prefer **translucent** surfaces (alpha) instead of opaque blocks.
- Use 2–3 elevation levels (E1 bar, E2 popups, E3 modals).
- Keep typography and spacing consistent; motion should be short and calm.

## What we will NOT do
- Run multiple competing shells long-term (no Eww).
- Make everything neon/over-animated (readability-first).
- Store secrets in synced config (strict local-only).

