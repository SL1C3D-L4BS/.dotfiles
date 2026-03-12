import QtQuick

Rectangle {
    id: root

    // Expects parent to pass BrandTheme instance as `theme`
    required property var theme

    property bool strong: false

    radius: theme.radiusModal
    color: strong ? theme.surfaceGlassStrong : theme.surfaceGlass
    border.width: 1
    border.color: theme.border
    clip: true
}

