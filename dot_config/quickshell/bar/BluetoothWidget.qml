// ─────────────────────────────────────────────────────────────────────────────
// BluetoothWidget.qml — SL1C3D-L4BS Quickshell bar bluetooth indicator
// Shows powered/connected state; click opens bluetui scratchpad
// ─────────────────────────────────────────────────────────────────────────────

import Quickshell
import Quickshell.Io
import QtQuick
import "."

Item {
    id: root
    required property var theme
    implicitWidth: btPill.implicitWidth
    implicitHeight: btPill.implicitHeight

    property bool btPowered:   false
    property bool btConnected: false
    property string btDevice:  ""

    // ── Poll bluetoothctl every 5 seconds ────────────────────────────────────
    Process {
        id: btProc
        command: ["sh", "-c",
            "bluetoothctl show 2>/dev/null | grep -E 'Powered:|Connected:'; " +
            "bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: function() {
                const lines = (text || "").trim().split("\n")
                root.btPowered   = lines.some(l => l.includes("Powered: yes"))
                root.btConnected = lines.some(l => l.includes("Connected: yes"))
                const devLine    = lines.find(l => !l.includes("Powered") && !l.includes("Connected") && l.trim())
                root.btDevice    = devLine ? devLine.trim() : ""
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: btProc.running = true
    }
    Component.onCompleted: btProc.running = true

    // ── Open bluetui scratchpad ───────────────────────────────────────────────
    Process {
        id: launchBt
        running: false
        command: ["sh", "-c",
            "~/.config/hypr/scripts/scratch-toggle.sh bluetooth bluetui-scratch " +
            "'ghostty --class=bluetui-scratch -e bluetui'"]
    }

    // ── Pill visual ──────────────────────────────────────────────────────────
    Rectangle {
        id: btPill
        implicitWidth: btRow.implicitWidth + 16
        implicitHeight: 26
        color: btHover.containsMouse
            ? Qt.rgba(root.theme.accentPrimary.r,
                      root.theme.accentPrimary.g,
                      root.theme.accentPrimary.b, 0.15)
            : "transparent"
        border.color: root.btPowered ? root.theme.accentPrimary : root.theme.border
        border.width: 1
        radius: root.theme.radiusPill

        Row {
            id: btRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: root.btConnected ? "󰂯" : (root.btPowered ? "󰂯" : "󰂲")
                color: root.btConnected
                    ? root.theme.accentPrimary
                    : (root.btPowered ? root.theme.textSecondary : root.theme.textMuted)
                font.family: root.theme.fontFamily
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                visible: root.btDevice !== ""
                text: root.btDevice.length > 12
                    ? root.btDevice.substring(0, 12) + "…"
                    : root.btDevice
                color: root.theme.textSecondary
                font.family: root.theme.fontFamily
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        ToolTip.visible: btHover.containsMouse
        ToolTip.text: root.btConnected
            ? "Connected: " + (root.btDevice || "device")
            : (root.btPowered ? "Bluetooth on — no device" : "Bluetooth off")
        ToolTip.delay: 600

        MouseArea {
            id: btHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: launchBt.running = true
        }
    }
}
