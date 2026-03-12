import QtQuick

QtObject {
    id: root

    // Base & surfaces — SL1C3D-L4BS neutrals
    property color bgBase: "#0d0d0d"
    property color bgSurface: "#1a1a1a"
    property color border: "#2d2d2d"
    property color borderDim: "#404040"

    // Glass surfaces (subtle, readability-first)
    // These are deliberately translucent; compositor blur is enabled via Hyprland layerrules.
    property color surfaceGlass: "#961a1a1a"        // ~58% alpha over bg
    property color surfaceGlassStrong: "#bd0d0d0d"  // ~74% alpha over bg
    property color scrim: "#59000000"               // ~35% alpha black
    property color borderGlass: "#385865F2"         // accent with ~22% alpha

    // Foreground
    property color textPrimary: "#f8f8f2"
    property color textSecondary: "#e0e0e0"
    property color textMuted: "#909090"

    // Accent — Discord Blurple
    property color accentPrimary: "#5865F2"
    property color accentDim: "#5865F299"
    property color accentDim2: "#5865F266"
    // Logo / neon purple (bright, still on-brand)
    property color logoPurple: "#b366ff"

    // Status
    property color accentRed: "#ff5555"
    property color accentGreen: "#50fa7b"
    property color accentOrange: "#ffb86c"

    // Battery (alias for Bar)
    property color batteryGood: accentGreen
    property color batteryWarning: accentOrange
    property color batteryCritical: accentRed

    // Typography & layout tokens
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int radiusPill: 8
    property int radiusModal: 12
    property int spacingXs: 4
    property int spacingSm: 8
    property int spacingMd: 12
    property int spacingLg: 16

    // Motion tokens (ms)
    property int motionFastMs: 120
    property int motionBaseMs: 180
    property int motionSlowMs: 240
}
