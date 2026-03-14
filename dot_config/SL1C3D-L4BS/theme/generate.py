#!/usr/bin/env python3
# SL1C3D-L4BS — Theme generator (Phase 4)
# Single authoritative pipeline. Reads theme.tokens.toml; writes Layer B + Layer C.
# Invoked only via: sl1c3d theme apply

from __future__ import annotations

import json
import os
import sys

try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        raise SystemExit("theme-generator: need Python 3.11+ (tomllib) or pip install tomli")

def load_tokens(source_dir: str) -> dict:
    path = os.path.join(source_dir, "theme.tokens.toml")
    if not os.path.isfile(path):
        raise SystemExit(f"theme-generator: canonical token source not found: {path}")
    with open(path, "rb") as f:
        return tomllib.load(f)

def hex_to_hypr_rgba(hex_val: str) -> str:
    h = hex_val.lstrip("#")
    if len(h) == 8:
        r, g, b, a = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), int(h[6:8], 16)
    else:
        r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
        a = 255
    return f"rgba({r:02x}{g:02x}{b:02x}{a:02x})"

def write_runtime_json(tokens: dict, out_path: str) -> None:
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    flat = {}
    for section, vals in tokens.items():
        if isinstance(vals, dict):
            for k, v in vals.items():
                flat[f"{section}.{k}"] = v
        else:
            flat[section] = vals
    flat["_generator"] = "sl1c3d-theme-generator"
    with open(out_path, "w") as f:
        json.dump(flat, f, indent=2)

def write_brand_theme_qml(tokens: dict, out_path: str) -> None:
    c = tokens.get("colors", {})
    s = tokens.get("spacing", {})
    r = tokens.get("radius", {})
    m = tokens.get("motion", {})
    t = tokens.get("typography", {})
    content = f'''import QtQuick

QtObject {{
    id: root

    // Generated from theme.tokens.toml — do not edit by hand
    property color bgBase: "{c.get("bg", "#0d0d0d")}"
    property color bgSurface: "{c.get("surface", "#1a1a1a")}"
    property color border: "{c.get("border", "#2d2d2d")}"
    property color borderDim: "{c.get("border_dim", "#404040")}"
    property color surfaceGlass: "{c.get("surface_glass", "#961a1a1a")}"
    property color surfaceGlassStrong: "{c.get("surface_glass_strong", "#bd0d0d0d")}"
    property color scrim: "{c.get("scrim", "#59000000")}"
    property color borderGlass: "{c.get("border_glass", "#385865F2")}"
    property color textPrimary: "{c.get("fg", "#f8f8f2")}"
    property color textSecondary: "{c.get("fg_dim", "#e0e0e0")}"
    property color textMuted: "{c.get("fg_muted", "#909090")}"
    property color accentPrimary: "{c.get("accent", "#5865F2")}"
    property color accentDim: "{c.get("accent_dim", "#5865F299")}"
    property color accentDim2: "{c.get("accent_dim2", "#5865F266")}"
    property color logoPurple: "{c.get("logo", "#b366ff")}"
    property color accentRed: "{c.get("error", "#ff5555")}"
    property color accentGreen: "{c.get("success", "#50fa7b")}"
    property color accentOrange: "{c.get("warn", "#ffb86c")}"
    property color batteryGood: accentGreen
    property color batteryWarning: accentOrange
    property color batteryCritical: accentRed
    property string fontFamily: "{t.get("font_family", "JetBrainsMono Nerd Font")}"
    property int radiusPill: {r.get("pill", 8)}
    property int radiusModal: {r.get("modal", 12)}
    property int spacingXs: {s.get("xs", 4)}
    property int spacingSm: {s.get("sm", 8)}
    property int spacingMd: {s.get("md", 12)}
    property int spacingLg: {s.get("lg", 16)}
    property int motionFastMs: {m.get("fast_ms", 120)}
    property int motionBaseMs: {m.get("normal_ms", 180)}
    property int motionSlowMs: {m.get("slow_ms", 260)}
}}
'''
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w") as f:
        f.write(content)

def write_sl1c3d_tokens_scss(tokens: dict, out_path: str) -> None:
    c = tokens.get("colors", {})
    s = tokens.get("spacing", {})
    r = tokens.get("radius", {})
    m = tokens.get("motion", {})
    # Glass as rgba from hex where needed
    content = f'''// ─────────────────────────────────────────────────────────────────────────────
// SL1C3D-L4BS design tokens — generated from theme.tokens.toml (Phase 4)
// Do not edit by hand. Run: sl1c3d theme apply
// ─────────────────────────────────────────────────────────────────────────────

$sl_bg_base:     {c.get("bg", "#0d0d0d")};
$sl_bg_surface:  {c.get("surface", "#1a1a1a")};
$sl_border:      {c.get("border", "#2d2d2d")};
$sl_border_mid:  {c.get("border_dim", "#404040")};
$sl_fg:          {c.get("fg", "#f8f8f2")};
$sl_fg_dim:      {c.get("fg_dim", "#e0e0e0")};
$sl_fg_muted:    {c.get("fg_muted", "#909090")};
$sl_accent:      {c.get("accent", "#5865F2")};
$sl_logo:        {c.get("logo", "#b366ff")};
$sl_error:       {c.get("error", "#ff5555")};
$sl_success:     {c.get("success", "#50fa7b")};
$sl_warn:        {c.get("warn", "#ffb86c")};
$sl_surface_glass:       rgba(26, 26, 26, 0.72);
$sl_surface_glass_strong: rgba(13, 13, 13, 0.86);
$sl_scrim:               rgba(0, 0, 0, 0.45);
$sl_border_glass:        rgba(88, 101, 242, 0.22);
$sl_border_glass_logo:   rgba(179, 102, 255, 0.18);
$sl_radius_pill:  {r.get("pill", 8)}px;
$sl_radius_modal: {r.get("modal", 12)}px;
$sl_radius_card:  {r.get("card", 10)}px;
$sl_spacing_xs: {s.get("xs", 4)}px;
$sl_spacing_sm: {s.get("sm", 8)}px;
$sl_spacing_md: {s.get("md", 12)}px;
$sl_spacing_lg: {s.get("lg", 16)}px;
$sl_spacing_xl: {s.get("xl", 24)}px;
$sl_motion_fast: {m.get("fast_ms", 120)}ms;
$sl_motion_base: {m.get("normal_ms", 180)}ms;
$sl_motion_slow: {m.get("slow_ms", 260)}ms;
'''
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w") as f:
        f.write(content)

def write_hypr_colors(tokens: dict, out_path: str) -> None:
    c = tokens.get("colors", {})
    accent = c.get("accent", "#5865F2").lstrip("#")
    content = f'''# ─────────────────────────────────────────────────────────────────────────────
# Brand colors — generated from theme.tokens.toml (Phase 4). Do not edit by hand.
# Run: sl1c3d theme apply
# ─────────────────────────────────────────────────────────────────────────────

$accent       = rgba({accent}ff)
$accentDim    = rgba({accent}99)
$accentDim2   = rgba({accent}66)
$bg           = rgba(0d0d0dff)
$bgElevated   = rgba(1a1a1aff)
$bgSurface    = rgba(282a36ff)
$border       = rgba(2d2d2dff)
$borderDim    = rgba(40404099)
$fg           = rgba(f8f8f2ff)
$fgDim        = rgba(e0e0e0ff)
$fgMuted      = rgba(909090ff)
$shadow       = rgba(00000099)
'''
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w") as f:
        f.write(content)

def write_ghostty_theme(tokens: dict, out_path: str) -> None:
    c = tokens.get("colors", {})
    bg = c.get("bg", "#0d0d0d").lstrip("#")
    fg = c.get("fg", "#f8f8f2").lstrip("#")
    accent = c.get("accent", "#5865F2").lstrip("#")
    border = c.get("border", "#2d2d2d").lstrip("#")
    err = c.get("error", "#ff5555").lstrip("#")
    success = c.get("success", "#50fa7b").lstrip("#")
    warn = c.get("warn", "#ffb86c").lstrip("#")
    fgdim = c.get("fg_dim", "#e0e0e0").lstrip("#")
    content = f"""# SL1C3D-L4BS brand theme — generated from theme.tokens.toml (Phase 4). Do not edit by hand.
# Run: sl1c3d theme apply

palette = 0=#{bg}
palette = 1=#{err}
palette = 2=#{success}
palette = 3=#{warn}
palette = 4=#{accent}
palette = 5=#{accent}
palette = 6=#{fgdim}
palette = 7=#{fg}
palette = 8=#{border}
palette = 9=#{err}
palette = 10=#{success}
palette = 11=#{warn}
palette = 12=#{accent}
palette = 13=#{accent}
palette = 14=#{fgdim}
palette = 15=#{fg}

background = {c.get("bg", "#0d0d0d")}
foreground = {c.get("fg", "#f8f8f2")}
cursor-color = {c.get("accent", "#5865F2")}
selection-background = {c.get("border", "#2d2d2d")}
selection-foreground = {c.get("fg", "#f8f8f2")}
"""
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w") as f:
        f.write(content)

def main() -> None:
    source_dir = os.environ.get("SL1C3D_SOURCE_DIR", os.environ.get("CHEZMOI_SOURCE_DIR", ""))
    if not source_dir and len(sys.argv) > 1:
        source_dir = sys.argv[1]
    if not source_dir:
        source_dir = os.path.expanduser("~/.local/share/chezmoi")
    home = os.environ.get("HOME", os.path.expanduser("~"))
    xdg_config = os.environ.get("XDG_CONFIG_HOME", os.path.join(home, ".config"))
    runtime_json_path = os.path.join(xdg_config, "sl1c3d", "theme.json")

    tokens = load_tokens(source_dir)
    dot_config = os.path.join(source_dir, "dot_config")

    write_runtime_json(tokens, runtime_json_path)
    write_brand_theme_qml(tokens, os.path.join(dot_config, "quickshell", "bar", "BrandTheme.qml"))
    write_sl1c3d_tokens_scss(tokens, os.path.join(dot_config, "ags", "sl1c3d-tokens.scss"))
    write_hypr_colors(tokens, os.path.join(dot_config, "hypr", "colors.conf"))
    write_ghostty_theme(tokens, os.path.join(dot_config, "ghostty", "themes", "sl1c3d-l4bs"))

    print("theme-generator: wrote", runtime_json_path)
    print("theme-generator: wrote", os.path.join(dot_config, "quickshell", "bar", "BrandTheme.qml"))
    print("theme-generator: wrote", os.path.join(dot_config, "ags", "sl1c3d-tokens.scss"))
    print("theme-generator: wrote", os.path.join(dot_config, "hypr", "colors.conf"))
    print("theme-generator: wrote", os.path.join(dot_config, "ghostty", "themes", "sl1c3d-l4bs"))

if __name__ == "__main__":
    main()
