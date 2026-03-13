import Quickshell
import QtQuick
import "bar"
import "ui"

Scope {
    BrandTheme {
        id: activeTheme
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
