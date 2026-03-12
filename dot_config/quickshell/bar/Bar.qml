import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../ui"

Scope {
    id: root
    property var theme: BrandTheme {}
    property string homeDir: (typeof Qt !== "undefined" && Qt.environment && typeof Qt.environment.value === "function" ? Qt.environment.value("HOME") : null) || "/home/the_architect"
    property string phosphorDir: "file://" + homeDir + "/assets/icons/phosphor"

    property string barTimeString: "00:00"
    property string barDateString: "—"
    property string editionName: "base"

    Process {
        id: editionReadProc
        command: ["sh", "-c", "cat \"$HOME/.config/SL1C3D-L4BS/state/edition.json\" 2>/dev/null || true"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: function() {
                try {
                    const obj = JSON.parse((text || "").trim() || "{}")
                    if (obj && obj.edition) root.editionName = String(obj.edition)
                } catch (e) {
                    // Keep last known editionName
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: editionReadProc.running = true
    }
    Component.onCompleted: {
        editionReadProc.running = true
        dateTimeProc.running = true
    }

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

    Process {
        id: dateTimeProc
        command: ["sh", "-c", "date +%H:%M; date '+%b %d, %Y'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: function() {
                const lines = (text && text.trim()) ? text.trim().split("\n") : []
                if (lines.length >= 1) root.barTimeString = lines[0].trim() || "00:00"
                if (lines.length >= 2) root.barDateString = lines[1].trim() || "—"
            }
        }
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: dateTimeProc.running = true
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panelWindow
            required property var modelData
            screen: modelData
            visible: true
            property bool hubOpen: false
            property bool calendarOpen: false

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
            surfaceFormat.opaque: false

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

                        GlassSurface {
                            theme: root.theme
                            anchors.fill: parent
                            radius: root.theme.radiusPill
                            strong: true

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
                        id: timeDatePill
                        height: 24
                        width: timeDate.width + 16
                        radius: 8
                        color: root.theme.surfaceGlassStrong

                        Row {
                            id: timeDate
                            anchors.centerIn: parent
                            spacing: 8

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                source: root.phosphorDir + "/clock.svg"
                                width: 14
                                height: 14
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                            Text {
                                id: timeText
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.barTimeString
                                color: "#5865F2"
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                                width: Math.max(implicitWidth, 48)
                            }
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                source: root.phosphorDir + "/calendar-blank.svg"
                                width: 14
                                height: 14
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                            Text {
                                id: dateText
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.barDateString
                                color: "#b366ff"
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                                width: Math.max(implicitWidth, 88)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panelWindow.calendarOpen = !panelWindow.calendarOpen
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

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                source: root.phosphorDir + "/music-notes.svg"
                                width: 14
                                height: 14
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                source: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing ? root.phosphorDir + "/pause.svg" : root.phosphorDir + "/play.svg"
                                width: 14
                                height: 14
                                fillMode: Image.PreserveAspectFit
                                smooth: true
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

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                source: root.phosphorDir + "/sun-dim.svg"
                                width: 14
                                height: 14
                                fillMode: Image.PreserveAspectFit
                                smooth: true
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
                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: root.phosphorDir + "/network.svg"
                                    width: 14
                                    height: 14
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
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
                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: SystemInfo.batteryCharging ? root.phosphorDir + "/battery-charging.svg" : (SystemInfo.batteryLevelRaw > 20 ? root.phosphorDir + "/battery-high.svg" : root.phosphorDir + "/battery-low.svg")
                                    width: 14
                                    height: 14
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: SystemInfo.batteryLevel
                                    color: sysInfo.batteryColor
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
                implicitHeight: 460
                visible: panelWindow.hubOpen
                color: "transparent"

                onVisibleChanged: if (!visible) panelWindow.hubOpen = false

                GlassSurface {
                    theme: root.theme
                    anchors.fill: parent
                    radius: root.theme.radiusModal
                    strong: false
                    clip: true

                    Process {
                        id: hubLauncher
                        running: false
                    }

                    property string home: (typeof Qt !== "undefined" && Qt.environment && typeof Qt.environment.value === "function" ? Qt.environment.value("HOME") : null) || "/home/the_architect"

                    Flickable {
                        id: hubFlick
                        anchors.fill: parent
                        anchors.margins: 14
                        contentWidth: width
                        contentHeight: hubColumn.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: hubColumn
                            width: hubFlick.width
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

                        Row {
                            spacing: 6
                            Image { source: root.phosphorDir + "/gear.svg"; width: 12; height: 12; fillMode: Image.PreserveAspectFit; smooth: true }
                            Text {
                                text: "CONTROL_PLANE"
                                color: root.theme.textMuted
                                font.pixelSize: 9
                                font.family: "JetBrainsMono Nerd Font"
                                font.letterSpacing: 0.8
                            }
                        }
                        Item { height: 6 }

                        Row {
                            height: 26
                            spacing: 16

                            Row {
                                spacing: 6
                                anchors.verticalCenter: parent.verticalCenter
                                Image { source: root.phosphorDir + "/gear.svg"; width: 10; height: 10; fillMode: Image.PreserveAspectFit; smooth: true }
                                Text {
                                    text: "Edition: " + root.editionName
                                    color: root.theme.textSecondary
                                    font.pixelSize: 10
                                    font.family: root.theme.fontFamily
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Item { width: Math.max(0, parent.width - 240); height: 1 }

                            Text {
                                text: "Validate"
                                color: root.theme.accentPrimary
                                font.pixelSize: 10
                                font.family: root.theme.fontFamily
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hubLauncher.command = ["ghostty", "-e", "bash", "-lc", home + "/scripts/validate-configs.sh; echo; echo 'Press Enter to close'; read"]
                                        hubLauncher.running = true
                                        panelWindow.hubOpen = false
                                    }
                                }
                            }

                            Text {
                                text: "Reload_Hypr"
                                color: root.theme.logoPurple
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hubLauncher.command = ["sh", "-c", "hyprctl reload >/dev/null 2>&1 || true"]
                                        hubLauncher.running = true
                                        panelWindow.hubOpen = false
                                    }
                                }
                            }

                            Text {
                                text: "AI_Gateway"
                                color: root.theme.accentPrimary
                                font.pixelSize: 10
                                font.family: root.theme.fontFamily
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hubLauncher.command = ["sh", "-c", "systemctl --user restart openclaw-gateway.service >/dev/null 2>&1 || true"]
                                        hubLauncher.running = true
                                        panelWindow.hubOpen = false
                                    }
                                }
                            }

                            Text {
                                text: "QuickSettings"
                                color: root.theme.accentPrimary
                                font.pixelSize: 10
                                font.family: root.theme.fontFamily
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hubLauncher.command = ["ghostty", "-e", "bash", "-lc", home + "/.config/SL1C3D-L4BS/bin/sl1c3d-ags doctor; echo; echo 'If OK, run your AGS quicksettings command here.'; read"]
                                        hubLauncher.running = true
                                        panelWindow.hubOpen = false
                                    }
                                }
                            }
                        }

                        Item { height: 16 }

                        Row {
                            spacing: 6
                            Image {
                                source: root.phosphorDir + "/folder-open.svg"
                                width: 12
                                height: 12
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                            Text {
                                text: "DEVELOPER"
                                color: root.theme.textMuted
                                font.pixelSize: 9
                                font.family: "JetBrainsMono Nerd Font"
                                font.letterSpacing: 0.8
                            }
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
                                    Row {
                                        spacing: 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        Image { source: root.phosphorDir + "/folder-open.svg"; width: 10; height: 10; fillMode: Image.PreserveAspectFit; smooth: true }
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
                                                hubLauncher.command = ["ghostty", "-e", "yazi", parent.parent.parent.parent.path]
                                                hubLauncher.running = true
                                                panelWindow.hubOpen = false
                                            }
                                        }
                                        }
                                    }
                                    Row {
                                        spacing: 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        Image { source: root.phosphorDir + "/terminal-window.svg"; width: 10; height: 10; fillMode: Image.PreserveAspectFit; smooth: true }
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
                                                hubLauncher.command = ["ghostty", "-e", "bash", "-c", "cd " + parent.parent.parent.parent.path + " && exec ~/.config/hypr/scripts/zellij-branded.sh"]
                                                hubLauncher.running = true
                                                panelWindow.hubOpen = false
                                            }
                                        }
                                        }
                                    }
                                }
                            }
                        }

                        Item { height: 16 }
                        Row {
                            spacing: 6
                            Image {
                                source: root.phosphorDir + "/images-square.svg"
                                width: 12
                                height: 12
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                            Text {
                                text: "WALLPAPERS"
                                color: root.theme.textMuted
                                font.pixelSize: 9
                                font.family: "JetBrainsMono Nerd Font"
                                font.letterSpacing: 0.8
                            }
                        }
                        Item { height: 6 }

                        Repeater {
                            model: [
                                "sl1c3d-l4bs-01.png", "sl1c3d-l4bs-02.png", "sl1c3d-l4bs-03.png",
                                "sl1c3d-l4bs-04.png", "sl1c3d-l4bs-05.png", "sl1c3d-l4bs-06.png",
                                "sl1c3d-l4bs-07.png", "sl1c3d-l4bs-08.png", "sl1c3d-l4bs-09.png",
                                "sl1c3d-l4bs-10.png", "sl1c3d-l4bs-11.png", "sl1c3d-l4bs-12.png",
                                "sl1c3d-l4bs-13.png", "sl1c3d-l4bs-14.png", "sl1c3d-l4bs-15.png"
                            ]
                            Row {
                                height: 26
                                spacing: 0
                                property string wpPath: hubColumn.parent.home + "/assets/wallpapers/" + modelData
                                Text {
                                    width: 140
                                    text: modelData
                                    color: root.theme.textSecondary
                                    font.pixelSize: 10
                                    font.family: "JetBrainsMono Nerd Font"
                                    elide: Text.ElideMiddle
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "Set"
                                    color: root.theme.accentPrimary
                                    font.pixelSize: 10
                                    font.family: "JetBrainsMono Nerd Font"
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            hubLauncher.command = ["waypaper", "--wallpaper", parent.parent.wpPath, "--fill", "fill", "--monitor", "All", "--backend", "swaybg"]
                                            hubLauncher.running = true
                                            panelWindow.hubOpen = false
                                        }
                                    }
                                }
                            }
                        }

                        Row {
                            height: 26
                            spacing: 12
                            Text {
                                text: "Open folder"
                                color: root.theme.logoPurple
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hubLauncher.command = ["ghostty", "-e", "yazi", hubColumn.parent.home + "/assets/wallpapers"]
                                        hubLauncher.running = true
                                        panelWindow.hubOpen = false
                                    }
                                }
                            }
                            Text {
                                text: "Waypaper GUI"
                                color: root.theme.accentPrimary
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hubLauncher.command = ["waypaper"]
                                        hubLauncher.running = true
                                        panelWindow.hubOpen = false
                                    }
                                }
                            }
                        }

                        Item { height: 16 }
                        Row {
                            spacing: 6
                            Image {
                                source: root.phosphorDir + "/gear.svg"
                                width: 12
                                height: 12
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                            Text {
                                text: "SYSTEM"
                                color: root.theme.textMuted
                                font.pixelSize: 9
                                font.family: "JetBrainsMono Nerd Font"
                                font.letterSpacing: 0.8
                            }
                        }
                        Item { height: 6 }

                        Row {
                            height: 26
                            spacing: 16

                            Row {
                                spacing: 4
                                anchors.verticalCenter: parent.verticalCenter
                                Image { source: root.phosphorDir + "/cursor.svg"; width: 10; height: 10; fillMode: Image.PreserveAspectFit; smooth: true }
                                Text {
                                text: "AI (OpenClaw)"
                                color: root.theme.accentPrimary
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hubLauncher.command = [hubColumn.parent.home + "/.config/hypr/scripts/openclaw-sidebar.sh"]
                                        hubLauncher.running = true
                                        panelWindow.hubOpen = false
                                    }
                                }
                                }
                            }
                            Row {
                                spacing: 4
                                anchors.verticalCenter: parent.verticalCenter
                                Image { source: root.phosphorDir + "/magnifying-glass.svg"; width: 10; height: 10; fillMode: Image.PreserveAspectFit; smooth: true }
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
                            }
                            Row {
                                spacing: 4
                                anchors.verticalCenter: parent.verticalCenter
                                Image { source: root.phosphorDir + "/file-code.svg"; width: 10; height: 10; fillMode: Image.PreserveAspectFit; smooth: true }
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
                            }
                            Row {
                                spacing: 4
                                anchors.verticalCenter: parent.verticalCenter
                                Image { source: root.phosphorDir + "/images-square.svg"; width: 10; height: 10; fillMode: Image.PreserveAspectFit; smooth: true }
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

            PopupWindow {
                anchor.window: panelWindow
                anchor.rect.x: 0
                anchor.rect.y: panelWindow.implicitHeight
                anchor.rect.width: 280
                anchor.rect.height: 320
                implicitWidth: 280
                implicitHeight: 320
                visible: panelWindow.calendarOpen
                color: "transparent"

                onVisibleChanged: if (!visible) panelWindow.calendarOpen = false
                anchor.onAnchoring: {
                    if (timeDatePill && anchor.window) {
                        const p = timeDatePill.mapToItem(anchor.window, 0, timeDatePill.height)
                        anchor.rect = Qt.rect(p.x, p.y + 6, 280, 320)
                    }
                }

                Rectangle {
                    id: calendarContent
                    anchors.fill: parent
                    radius: 12
                    color: root.theme.bgSurface
                    border.width: 1
                    border.color: root.theme.border
                    layer.enabled: true
                    layer.effect: null

                    property int viewYear: new Date().getFullYear()
                    property int viewMonth: new Date().getMonth()
                    property var monthNames: ["January","February","March","April","May","June","July","August","September","October","November","December"]

                    Connections {
                        target: panelWindow
                        function onCalendarOpenChanged() {
                            if (panelWindow.calendarOpen) {
                                var d = new Date()
                                calendarContent.viewYear = d.getFullYear()
                                calendarContent.viewMonth = d.getMonth()
                            }
                        }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Row {
                            width: parent.width
                            height: 32
                            spacing: 0

                            MouseArea {
                                width: 32
                                height: 32
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    calendarContent.viewMonth--
                                    if (calendarContent.viewMonth < 0) {
                                        calendarContent.viewMonth = 11
                                        calendarContent.viewYear--
                                    }
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: parent.pressed ? root.theme.bgBase : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "‹"
                                        color: root.theme.logoPurple
                                        font.pixelSize: 18
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                }
                            }

                            Item { width: 8; height: 1 }

                            Text {
                                text: calendarContent.monthNames[calendarContent.viewMonth] + " " + calendarContent.viewYear
                                color: root.theme.logoPurple
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 32 - 32 - 16
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Item { width: 8; height: 1 }

                            MouseArea {
                                width: 32
                                height: 32
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    calendarContent.viewMonth++
                                    if (calendarContent.viewMonth > 11) {
                                        calendarContent.viewMonth = 0
                                        calendarContent.viewYear++
                                    }
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: parent.pressed ? root.theme.bgBase : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "›"
                                        color: root.theme.logoPurple
                                        font.pixelSize: 18
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                }
                            }
                        }

                        Row {
                            spacing: 2
                            Repeater {
                                model: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
                                Text {
                                    required property string modelData
                                    width: 34
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData
                                    color: root.theme.accentPrimary
                                    font.pixelSize: 10
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }
                        }

                        Grid {
                            id: calendarGrid
                            columns: 7
                            rowSpacing: 4
                            columnSpacing: 2
                            width: 7 * 34 + 6 * 2
                            property int year: calendarContent.viewYear
                            property int month: calendarContent.viewMonth
                            property int firstDay: { var d = new Date(calendarGrid.year, calendarGrid.month, 1); return (d.getDay() + 6) % 7 }
                            property int daysInMonth: new Date(calendarGrid.year, calendarGrid.month + 1, 0).getDate()

                            Repeater {
                                model: 42
                                Rectangle {
                                    required property int index
                                    width: 34
                                    height: 28
                                    radius: 6
                                    color: {
                                        const blank = index < calendarGrid.firstDay || index >= calendarGrid.firstDay + calendarGrid.daysInMonth
                                        const d = index - calendarGrid.firstDay + 1
                                        const today = new Date()
                                        const isToday = !blank && d === today.getDate() && calendarGrid.month === today.getMonth() && calendarGrid.year === today.getFullYear()
                                        if (blank) return "transparent"
                                        if (isToday) return root.theme.logoPurple
                                        return root.theme.bgBase
                                    }
                                    border.width: 0
                                    Text {
                                        anchors.centerIn: parent
                                        text: {
                                            if (index < calendarGrid.firstDay || index >= calendarGrid.firstDay + calendarGrid.daysInMonth) return ""
                                            return index - calendarGrid.firstDay + 1
                                        }
                                        color: {
                                            const blank = index < calendarGrid.firstDay || index >= calendarGrid.firstDay + calendarGrid.daysInMonth
                                            const d = index - calendarGrid.firstDay + 1
                                            const today = new Date()
                                            const isToday = !blank && d === today.getDate() && calendarGrid.month === today.getMonth() && calendarGrid.year === today.getFullYear()
                                            if (blank) return "transparent"
                                            if (isToday) return root.theme.textPrimary
                                            return root.theme.accentPrimary
                                        }
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.weight: {
                                            var d = index - calendarGrid.firstDay + 1
                                            var today = new Date()
                                            return (!(index < calendarGrid.firstDay || index >= calendarGrid.firstDay + calendarGrid.daysInMonth) && d === today.getDate() && calendarGrid.month === today.getMonth() && calendarGrid.year === today.getFullYear()) ? Font.DemiBold : Font.Normal
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width - 28
                            height: 1
                            color: root.theme.border
                            opacity: 0.5
                        }

                        Row {
                            spacing: 12
                            Text {
                                text: root.barTimeString
                                color: root.theme.logoPurple
                                font.pixelSize: 20
                                font.family: "JetBrainsMono Nerd Font"
                                font.weight: Font.Bold
                            }
                            Text {
                                text: root.barDateString
                                color: root.theme.logoPurple
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
}
