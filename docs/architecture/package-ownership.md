## Package Ownership — Classes and Migration Rules

This document is grounded in:

- Phase 0 inventory (installed tools and installers): `docs/inventory/phase0-inventory.md`
- Phase 0 decisions (ambiguous package-source decisions): `docs/inventory/phase0-decisions.md`
- Phase 0 contradictions (Nix readiness): `docs/inventory/phase0-contradictions.md`

At Phase 1, all installed packages remain Arch-hosted; this file defines how classes and migrations will work when Phase 8 is executed.

---

### 1. Package Classes

Per the Masterclass plan, the stack is partitioned into six classes:

1. **Session-core**  
   - Examples: Hyprland, UWSM, PipeWire, WirePlumber, XDG Portals, dbus-broker, login/display-manager components closely tied to the desktop session.

2. **UI-support**  
   - Examples: Quickshell, swaync, AGS, Ghostty, Yazi, Fuzzel, Mako, Waypaper, wallpaper tools, theme engines, session-adjacent GUIs.

3. **Toolchain**  
   - Examples: ripgrep, fd, eza, bat, fzf, zoxide, git-related tools, build tools, compilers where not bound to a specific language ecosystem.

4. **Language/runtime**  
   - Examples: Node.js, npm, Python, pip, Go, Rust toolchain (rustup), Java, etc.

5. **Operator/diagnostic**  
   - Examples: fastfetch, btop, Lazygit, Atuin, monitoring tools, backup CLIs where used for operator tasks.

6. **Theme/asset tooling**  
   - Examples: matugen or equivalent theme generators, image tools used for wallpaper and icons, any dedicated theme compilation tooling.

---

### 2. Phase 0 Baseline — Owner = Arch

From the Phase 0 decisions:

- All classes above are **currently installed via Arch (pacman/AUR)**.  
- No package is owned by Nix at Phase 1.  
- This is the binding baseline for future migrations:
  - **Owner(Phase 0) = Arch packages** for every package in scope.

---

### 3. Target Ownership Policy (Post-Phase 8)

This section defines the **direction of travel** for each class once Nix Mode A is introduced:

- **Session-core:**  
  - Default owner: **Arch**.  
  - Rationale: close coupling to the host OS and desktop stack; better alignment with vendor documentation and wiki guidance.  
  - Nix may be used for experiments, but the canonical production path remains Arch.

- **UI-support:**  
  - Default owner: **Arch**, with optional Nix ownership for development shells.  
  - Quickshell, swaync, and AGS binaries remain Arch by default; configs remain in chezmoi.

- **Toolchain:**  
  - Default owner: **Nix-preferred** after Phase 8.  
  - Rationale: reproducible dev environments; per-project shells; clear rollbacks.  
  - Arch packages can remain installed for bootstrapping or as fallbacks, but PATH precedence must be documented.

- **Language/runtime:**  
  - Default owner: **Nix-preferred** after Phase 8, where tooling permits.  
  - Runtimes may also be installed via language-native tools (e.g. `rustup`) when this provides better ergonomics, but Nix-based flows should be primary for reproducible setups.

- **Operator/diagnostic:**  
  - Default owner: **either**, with explicit choice per package.  
  - Each operator tool (e.g. fastfetch) must have a documented owner and rollback path in this file and in the migration ledger.

- **Theme/asset tooling:**  
  - Default owner: negotiated per-tool; initial owner remains Arch.  
  - Nix may host these tools for reproducibility, but only after Phase 4 has stabilized the theme pipeline.

No change is enacted at Phase 1; this is policy only.

---

### 4. Migration Rules (Arch ↔ Nix)

These rules apply **per package** and must be accompanied by entries in `docs/architecture/migration-ledger.md`:

- **Arch → Nix:**
  - Decide the package class and confirm that the target owner for that class allows Nix ownership.
  - Add the package to the appropriate flake output (e.g. user profile or devShell).
  - Remove or downgrade the Arch package according to the class policy (e.g. uninstall completely for pure Nix ownership, or keep for fallback with documented PATH precedence).
  - Record the move in the migration ledger with rollback commands.

- **Nix → Arch:**
  - Remove the package from the relevant flake outputs or Nix profiles.
  - Install the package via pacman or AUR helper.
  - Update the migration ledger entry to show rollback completion.

---

### 5. PATH Precedence and Duplicate Binaries

When both Arch and Nix provide the same binary:

- **PATH precedence (binding):** When Nix is the intended owner for a package class, ensure the Nix profile path (e.g. `~/.nix-profile/bin` or the flake profile) appears **before** `/usr/bin` in `PATH`. Document in bootstrap and shell config. When Arch is the owner, do not prepend Nix profile for that binary or mask the Arch binary.
- **Duplicate binary conflict rule:** One owner per binary at runtime. If both Arch and Nix provide the same command (e.g. `bat`), the migration ledger and package-ownership must record which source is canonical; the other is uninstalled or not on PATH for that command.
- Document for each such binary: current PATH resolution, intended owner, and steps to revert (change PATH or uninstall Nix package per rollback below).

---

### 5.1. Operational Package Migration Rules (Phase 8)

**Arch → Nix (migrate a package to Nix):**

1. Confirm package class and that target owner policy allows Nix (see §3).
2. Add package to flake (e.g. `nix/home/default.nix` or flake `packages` output).
3. Uninstall from Arch: `pacman -Rsn <pkg>` or AUR equivalent; document in ledger.
4. Install from Nix: `nix profile install .#<attr>` (or flake reference).
5. Record in migration-ledger: artifact ID, current path (Arch), target path (Nix), rollback commands (below).

**Nix → Arch (revert to Arch):**

1. Remove from Nix: `nix profile uninstall <attr>` or remove from flake and `nix profile install` again.
2. Install via Arch: `pacman -S <pkg>` or AUR helper.
3. Update migration ledger entry; confirm PATH no longer resolves to Nix binary.

**Rollback rule per package class:**

- **Session-core / UI-support:** Rollback = reinstall Arch package; disable or remove Nix profile entry; no Nix in PATH for that binary.
- **Toolchain / Language/runtime:** Rollback = `nix profile uninstall` the attribute; reinstall Arch (or language-native installer); update shell PATH if needed.
- **Operator/diagnostic / Theme:** Same as toolchain; per-package rollback commands in ledger.

---

### 6. No-Placeholder Guarantee

At Phase 1:

- No package has been moved to or from Nix.  
- All concrete package ownership remains **Arch-only**, matching Phase 0.  
- This document does not contain tentative package lists or “TBD” placeholders; it defines the **policy and rules** for future migrations without asserting that any have already happened.

When Phase 8 executes migrations, this document and the migration ledger must be updated together.

