import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

Scope {
    id: root
    property var theme: BrandTheme {}

    property var activePlayer: {
        const players = Mpris.players.values
        if (!players || players.length === 0) return null
        for (const p of players) {
            if (p.playbackState === MprisPlaybackState.Playing) return p
        }
        return players[0]
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property real brightnessValue: 0
    property real brightnessMax: 1

    FileView {
        id: brightnessFile
        path: ""
        watchChanges: true
        onFileChanged: brightnessReadProc.running = true
    }

    Process {
        id: brightnessReadProc
        command: ["brightnessctl", "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: function() {
                const val = parseInt(text.trim())
                if (!isNaN(val) && root.brightnessMax > 0)
                    root.brightnessValue = val / root.brightnessMax
            }
        }
    }

    Process {
        id: brightnessSetProc
        running: false
    }

    Process {
        id: backlightDiscovery
        command: ["sh", "-c", "p=$(ls -d /sys/class/backlight/*/brightness 2>/dev/null | head -1); [ -n \"$p\" ] && echo \"$p\" && cat \"${p%brightness}max_brightness\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: function() {
                const lines = text.trim().split("\n")
                if (lines.length >= 2) {
                    const max = parseInt(lines[1])
                    if (!isNaN(max) && max > 0) root.brightnessMax = max
                    brightnessFile.path = lines[0]
                    brightnessReadProc.running = true
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panelWindow
            required property var modelData
            screen: modelData
            visible: true
            property bool hubOpen: false

            anchors.top: true
            anchors.left: true
            anchors.right: true

            margins {
                left: 16
                right: 16
                top: 12
                bottom: 0
            }

            implicitHeight: 44
            color: "transparent"

            Item {
                anchors.fill: parent
                anchors.leftMargin: 0
                anchors.rightMargin: 0
                anchors.topMargin: 0
                anchors.bottomMargin: 0

                Rectangle {
                    id: barPill
                    anchors.fill: parent
                    anchors.leftMargin: 0
                    anchors.rightMargin: 0
                    anchors.topMargin: 0
                    radius: 12
                    color: root.theme.bgSurface
                    layer.effect: null
                }

                Rectangle {
                    anchors.fill: barPill
                    anchors.margins: -4
                    anchors.topMargin: 2
                    z: -1
                    radius: 14
                    color: "#20000000"
                }

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                Row {
                    id: leftSection
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    MouseArea {
                        width: 36
                        height: 24
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panelWindow.hubOpen = true

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: root.theme.bgBase

                            Image {
                                anchors.centerIn: parent
                                source: "file:///home/the_architect/assets/icons/Logo-bar.svg"
                                width: 20
                                height: 20
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }
                        }
                    }

                    Rectangle {
                        height: 24
                        width: timeDate.width + 16
                        radius: 8
                        color: root.theme.bgBase

                        Row {
                            id: timeDate
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Time.timeString
                                color: root.theme.accentPrimary
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Time.dateString
                                color: root.theme.textSecondary
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }
                    }

                    Row {
                        spacing: 4
                        Repeater {
                            model: Hyprland.workspaces

                            Rectangle {
                                id: wsPill
                                required property var modelData
                                property bool urgentBlink: false

                                Accessible.role: Accessible.Button
                                Accessible.name: "Workspace " + modelData.id + (modelData.focused ? ", active" : "") + (modelData.urgent ? ", urgent" : "")

                                width: modelData.focused ? 32 : 24
                                height: 24
                                radius: 8
                                color: modelData.focused ? root.theme.accentPrimary :
                                    (modelData.urgent && urgentBlink ? root.theme.accentRed : root.theme.bgBase)

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }

                                SequentialAnimation {
                                    loops: Animation.Infinite
                                    running: wsPill.modelData.urgent && !wsPill.modelData.focused
                                    PropertyAction { target: wsPill; property: "urgentBlink"; value: true }
                                    PauseAnimation { duration: 500 }
                                    PropertyAction { target: wsPill; property: "urgentBlink"; value: false }
                                    PauseAnimation { duration: 500 }
                                    onStopped: wsPill.urgentBlink = false
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: wsPill.modelData.id
                                    color: wsPill.modelData.focused ? root.theme.bgBase : root.theme.textPrimary
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.bold: wsPill.modelData.focused
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: wsPill.modelData.activate()
                                }

                                Behavior on width {
                                    NumberAnimation { duration: 150 }
                                }
                            }
                        }
                    }

                    Rectangle {
                        height: 24
                        width: nowPlayingContent.width + 16
                        radius: 8
                        color: root.theme.bgBase
                        visible: root.activePlayer !== null

                        Accessible.role: Accessible.Button
                        Accessible.name: {
                            if (!root.activePlayer) return "No media"
                            const artist = root.activePlayer.trackArtist || ""
                            const title = root.activePlayer.trackTitle || ""
                            return "Now playing: " + (artist ? artist + " - " : "") + title
                        }

                        Row {
                            id: nowPlayingContent
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing ? "󰐊" : "󰏤"
                                color: root.theme.accentPrimary
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    if (!root.activePlayer) return ""
                                    const artist = root.activePlayer.trackArtist || ""
                                    const title = root.activePlayer.trackTitle || ""
                                    return artist ? artist + " - " + title : title
                                }
                                color: root.theme.textPrimary
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                                elide: Text.ElideRight
                                width: Math.min(implicitWidth, 200)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activePlayer && root.activePlayer.togglePlaying()
                        }
                    }
                }

                Item {
                    anchors.centerIn: parent
                    height: parent.height
                    width: Math.max(0, parent.width - leftSection.width - rightSection.width - 32)

                    Text {
                        Accessible.role: Accessible.StaticText
                        Accessible.name: "Active window: " + text
                        text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                        color: root.theme.textPrimary
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, parent.width)
                        anchors.centerIn: parent
                    }
                }

                Row {
                    id: rightSection
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        height: 24
                        width: volContent.width + 12
                        radius: 8
                        color: root.theme.bgBase

                        Accessible.role: Accessible.StaticText
                        Accessible.name: {
                            const sink = Pipewire.defaultAudioSink
                            if (!sink || !sink.audio) return "Volume"
                            if (sink.audio.muted) return "Volume: muted"
                            return "Volume: " + Math.round(sink.audio.volume * 100) + "%"
                        }

                        Row {
                            id: volContent
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    const sink = Pipewire.defaultAudioSink
                                    if (!sink || !sink.audio || sink.audio.muted || sink.audio.volume <= 0) return "󰖁"
                                    if (sink.audio.volume < 0.33) return "󰕿"
                                    if (sink.audio.volume < 0.66) return "󰖀"
                                    return "󰕾"
                                }
                                color: {
                                    const sink = Pipewire.defaultAudioSink
                                    if (!sink || !sink.audio || sink.audio.muted) return root.theme.textMuted
                                    return root.theme.accentPrimary
                                }
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    const sink = Pipewire.defaultAudioSink
                                    if (!sink || !sink.audio) return "–"
                                    if (sink.audio.muted) return "Mute"
                                    return Math.round(sink.audio.volume * 100) + "%"
                                }
                                color: root.theme.textPrimary
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton
                            onClicked: {
                                const sink = Pipewire.defaultAudioSink
                                if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
                            }
                            onWheel: function(wheel) {
                                const sink = Pipewire.defaultAudioSink
                                if (!sink || !sink.audio) return
                                const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                                sink.audio.volume = Math.max(0, Math.min(1.5, sink.audio.volume + delta))
                            }
                        }
                    }

                    Rectangle {
                        height: 24
                        width: brightContent.width + 12
                        radius: 8
                        color: root.theme.bgBase
                        visible: brightnessFile.path !== ""

                        Accessible.role: Accessible.StaticText
                        Accessible.name: "Brightness: " + Math.round(root.brightnessValue * 100) + "%"

                        Row {
                            id: brightContent
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰃠"
                                color: root.theme.accentOrange
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round(root.brightnessValue * 100) + "%"
                                color: root.theme.textPrimary
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onWheel: function(wheel) {
                                brightnessSetProc.command = wheel.angleDelta.y > 0
                                    ? ["brightnessctl", "set", "5%+"]
                                    : ["brightnessctl", "set", "5%-"]
                                brightnessSetProc.running = true
                            }
                        }
                    }

                    Row {
                        id: sysInfo
                        readonly property color batteryColor: {
                            if (SystemInfo.batteryCharging) return root.theme.accentGreen
                            if (SystemInfo.batteryLevelRaw > 20) return root.theme.batteryGood
                            if (SystemInfo.batteryLevelRaw > 10) return root.theme.batteryWarning
                            return root.theme.batteryCritical
                        }
                        spacing: 4

                        Rectangle {
                            height: 24
                            width: netContent.width + 12
                            radius: 8
                            color: root.theme.bgBase
                            Accessible.role: Accessible.StaticText
                            Accessible.name: "Network: " + SystemInfo.networkInfo

                            Row {
                                id: netContent
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰛳"
                                    color: root.theme.accentGreen
                                    font.pixelSize: 14
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: SystemInfo.networkInfo
                                    color: root.theme.textPrimary
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }
                        }

                        Rectangle {
                            height: 24
                            width: battContent.width + 12
                            radius: 8
                            color: root.theme.bgBase
                            visible: SystemInfo.batteryIcon !== ""
                            Accessible.role: Accessible.StaticText
                            Accessible.name: "Battery: " + SystemInfo.batteryLevel

                            Row {
                                id: battContent
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: SystemInfo.batteryCharging
                                    text: "󱐋"
                                    color: root.theme.accentGreen
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: SystemInfo.batteryIcon
                                    color: sysInfo.batteryColor
                                    font.pixelSize: 14
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: SystemInfo.batteryLevel
                                    color: root.theme.textPrimary
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }
                        }
                    }

                    Rectangle {
                        implicitHeight: 24
                        implicitWidth: trayIcons.implicitWidth + 4
                        radius: 8
                        color: root.theme.bgBase

                        RowLayout {
                            id: trayIcons
                            anchors.centerIn: parent
                            spacing: 2

                            Repeater {
                                model: SystemTray.items

                                MouseArea {
                                    id: trayDelegate
                                    required property SystemTrayItem modelData

                                    Accessible.role: Accessible.Button
                                    Accessible.name: modelData.tooltipTitle || modelData.title || "System tray item"

                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24

                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.LeftButton) {
                                            modelData.activate()
                                        } else if (mouse.button === Qt.RightButton) {
                                            if (modelData.hasMenu) {
                                                menuAnchor.open()
                                            }
                                        } else if (mouse.button === Qt.MiddleButton) {
                                            modelData.secondaryActivate()
                                        }
                                    }

                                    IconImage {
                                        anchors.centerIn: parent
                                        source: trayDelegate.modelData.icon
                                        implicitSize: 16
                                    }

                                    QsMenuAnchor {
                                        id: menuAnchor
                                        menu: trayDelegate.modelData.menu
                                        anchor.window: trayDelegate.QsWindow.window
                                        anchor.adjustment: PopupAdjustment.Flip
                                        anchor.onAnchoring: {
                                            const window = trayDelegate.QsWindow.window
                                            const widgetRect = window.contentItem.mapFromItem(
                                                trayDelegate, 0, trayDelegate.height,
                                                trayDelegate.width, trayDelegate.height)
                                            menuAnchor.anchor.rect = widgetRect
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            PopupWindow {
                anchor.window: panelWindow
                anchor.rect.x: 0
                anchor.rect.y: panelWindow.implicitHeight
                implicitWidth: 300
                implicitHeight: 360
                visible: panelWindow.hubOpen
                color: "transparent"

                onVisibleChanged: if (!visible) panelWindow.hubOpen = false

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: root.theme.bgSurface
                    border.width: 1
                    border.color: root.theme.border
                    clip: true

                    Process {
                        id: hubLauncher
                        running: false
                    }

                    property string home: (typeof Qt !== "undefined" && Qt.environment && typeof Qt.environment.value === "function" ? Qt.environment.value("HOME") : null) || "/home/the_architect"

                    Column {
                        id: hubColumn
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 0

                        Row {
                            id: hubHeaderRow
                            height: 40
                            spacing: 0
                            width: parent.width

                            Row {
                                id: hubHeaderLeft
                                spacing: 8
                                height: parent.height

                                Image {
                                    source: "file:///home/the_architect/assets/icons/Logo-bar.svg"
                                    width: 18
                                    height: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                }
                                Text {
                                    text: "SL1C3D-L4BS"
                                    color: root.theme.logoPurple
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Item { width: hubHeaderRow.width - hubHeaderLeft.width - 32; height: 1 }
                            MouseArea {
                                width: 32
                                height: 32
                                anchors.verticalCenter: parent.verticalCenter
                                cursorShape: Qt.PointingHandCursor
                                onClicked: panelWindow.hubOpen = false
                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: root.theme.textMuted
                                    font.pixelSize: 18
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: root.theme.border
                            opacity: 0.6
                        }

                        Item { height: 14 }

                        Text {
                            text: "DEVELOPER"
                            color: root.theme.textMuted
                            font.pixelSize: 9
                            font.family: "JetBrainsMono Nerd Font"
                            font.letterSpacing: 0.8
                        }
                        Item { height: 6 }

                        Repeater {
                            model: [
                                { label: "~/dev", path: hubColumn.parent.home + "/dev" },
                                { label: "~/.config", path: hubColumn.parent.home + "/.config" },
                                { label: "~/assets", path: hubColumn.parent.home + "/assets" }
                            ]

                            Row {
                                height: 26
                                spacing: 0
                                property string path: modelData.path

                                Text {
                                    width: 100
                                    text: modelData.label
                                    color: root.theme.textSecondary
                                    font.pixelSize: 10
                                    font.family: "JetBrainsMono Nerd Font"
                                    elide: Text.ElideMiddle
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Row {
                                    spacing: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "Yazi"
                                        color: root.theme.accentPrimary
                                        font.pixelSize: 10
                                        font.family: "JetBrainsMono Nerd Font"
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                hubLauncher.command = ["ghostty", "-e", "yazi", parent.parent.parent.path]
                                                hubLauncher.running = true
                                                panelWindow.hubOpen = false
                                            }
                                        }
                                    }
                                    Text {
                                        text: "Terminal"
                                        color: root.theme.accentPrimary
                                        font.pixelSize: 10
                                        font.family: "JetBrainsMono Nerd Font"
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                hubLauncher.command = ["ghostty", "-e", "bash", "-c", "cd " + parent.parent.parent.path + " && exec ~/.config/hypr/scripts/zellij-branded.sh"]
                                                hubLauncher.running = true
                                                panelWindow.hubOpen = false
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { height: 16 }
                        Text {
                            text: "SYSTEM"
                            color: root.theme.textMuted
                            font.pixelSize: 9
                            font.family: "JetBrainsMono Nerd Font"
                            font.letterSpacing: 0.8
                        }
                        Item { height: 6 }

                        Row {
                            height: 26
                            spacing: 16

                            Text {
                                text: "Fuzzel"
                                color: root.theme.accentPrimary
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hubLauncher.command = ["fuzzel"]
                                        hubLauncher.running = true
                                        panelWindow.hubOpen = false
                                    }
                                }
                            }
                            Text {
                                text: "Hypr config"
                                color: root.theme.accentPrimary
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hubLauncher.command = ["ghostty", "-e", "nvim", hubColumn.parent.home + "/.config/hypr"]
                                        hubLauncher.running = true
                                        panelWindow.hubOpen = false
                                    }
                                }
                            }
                            Text {
                                text: "Waypaper"
                                color: root.theme.accentPrimary
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hubLauncher.command = ["waypaper", "--restore"]
                                        hubLauncher.running = true
                                        panelWindow.hubOpen = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
}
