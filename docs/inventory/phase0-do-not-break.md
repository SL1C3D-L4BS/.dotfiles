## Phase 0 — Do-Not-Break List

This list captures behaviors that **must remain working** through all subsequent phases unless explicitly superseded and documented with migration + rollback plans. It is based on the current validated configuration and observed workflow.

---

### 1. Core Session & Access

- **Hyprland graphical login succeeds** and reaches a usable desktop on all configured monitors.
- **Quickshell bar**:
  - Appears on all monitors after login.
  - Provides workspace, system, and AI access as currently configured.
- **Wayland session stability**:
  - No regressions that prevent opening terminals, browsers, or primary applications.

---

### 2. Navigation & Workflow

- **Keybinds help:** `Super+/` opens the keybinds helper script.
- **Launcher:** `Super+Space` opens Fuzzel.
- **Terminal:** `Super+Return` opens the configured terminal (Ghostty).
- **File manager:** `Super+F` opens the configured file manager.
- **Workspace navigation:**
  - `Super+1..0` → switch workspaces 1–10.
  - `Super+Shift+1..0` → move windows to workspaces 1–10.
- **Scratchpads:**
  - Scratchpad workspaces (`magic`, `scratchterm`) continue to work (HJKL scratchpad behaviors, btop/yazi/nvim/nmtui/lazygit/other scratchpads).

---

### 3. Notifications & Clipboard

- **Notifications:**
  - `swaync` starts automatically with the session.
  - Keybinds for dismissing notifications, toggling DND, and opening the notification panel continue to function.
- **Clipboard history:**
  - Background history via `wl-paste --watch cliphist store` remains active.
  - Clipboard history launcher (`cliphist` via Fuzzel) remains available and functional.

---

### 4. Idle, Lock, and Screen Controls

- **Locking:**
  - `Super+L` locks the screen via `hyprlock`.
  - XF86 lock keybinds continue to invoke `hyprlock`.
- **Idle behavior:**
  - `hypridle` continues to manage idle → lock behavior as configured (no unexpected disablement).
- **Brightness & volume:**
  - XF86 audio and brightness keys continue to adjust sound and display according to current bindings.

---

### 5. Theming & Visual Cohesion

- **Brand theme:** existing BrandTheme / SCSS / Ghostty theme artifacts continue to render correctly:
  - No loss of rounded corners, brand colors, or key styling.
- **Wallpaper:**
  - `swww-daemon` and `waypaper --restore` continue to restore the wallpaper on login.

---

### 6. AI & Operator Surfaces

- **OpenClaw gateway:**
  - `openclaw-gateway.service` remains functional and reachable at the documented URL when enabled.
- **AI sidebar:**
  - The AI sidebar (via Quickshell bar and `openclaw-sidebar.sh`) remains invokable with its current keybind.

---

### 7. Tooling & Validation

- **Config validation:** `~/scripts/validate-configs.sh` continues to:
  - Run without errors.
  - Validate all Hypr, Quickshell, swaync, Ghostty, Yazi, Fuzzel, AGS, and related configs as it does at Phase 0.
- **Core CLI tools:** fastfetch, git, ripgrep, fd, eza, bat, zoxide, zellij, and other “elite CLI” tools remain available and on PATH as they are now.

---

### 8. Constraint

Any future phase that would intentionally alter one of these behaviors **must**:

- Document the change and its rationale.
- Provide a clear rollback path.
- Update this do-not-break list (or explicitly mark the behavior as superseded) and the relevant architecture/operations docs.

