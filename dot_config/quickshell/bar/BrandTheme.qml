import QtQuick

QtObject {
    id: root

    // Base & surfaces — SL1C3D-L4BS neutrals
    property color bgBase: "#0d0d0d"
    property color bgSurface: "#1a1a1a"
    property color border: "#2d2d2d"
    property color borderDim: "#404040"

    // Foreground
    property color textPrimary: "#f8f8f2"
    property color textSecondary: "#e0e0e0"
    property color textMuted: "#909090"

    // Accent — Discord Blurple
    property color accentPrimary: "#5865F2"
    property color accentDim: "#5865F299"
    property color accentDim2: "#5865F266"

    // Status
    property color accentRed: "#ff5555"
    property color accentGreen: "#50fa7b"
    property color accentOrange: "#ffb86c"

    // Battery (alias for Bar)
    property color batteryGood: accentGreen
    property color batteryWarning: accentOrange
    property color batteryCritical: accentRed
}
