import Quickshell
import QtQuick
import "bar"
import "ui"

Scope {
    // Use MatugenTheme if available (matugen pipeline), else brand fallback
    property var activeTheme: {
        // Quickshell will use the file it finds; both export the same interface
        return BrandTheme {}
    }

    Bar {
        id: bar
        theme: activeTheme
    }

    AIPanel {
        id: aiPanel
        theme: activeTheme
        visible_: bar.aiPanelOpen
    }
}
