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
                                font.family: root.theme.fontFamily
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
                                font.family: root.theme.fontFamily
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
                                    font.family: root.theme.fontFamily
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
                                font.family: root.theme.fontFamily
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
                        font.family: root.theme.fontFamily
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
                                font.family: root.theme.fontFamily
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
                                font.family: root.theme.fontFamily
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
                                font.family: root.theme.fontFamily
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
                                    font.family: root.theme.fontFamily
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
                                    font.family: root.theme.fontFamily
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
                id: hubPopup
                anchor.window: panelWindow
                // Premium OS Hub: two-column nav + card-based content (ML4W/Omarchy-style)
                implicitWidth: 560
                implicitHeight: 640
                visible: panelWindow.hubOpen
                color: "transparent"

                onVisibleChanged: if (!visible) panelWindow.hubOpen = false

                anchor.onAnchoring: {
                    if (anchor.window && leftSection) {
                        var window = anchor.window
                        var pillRect = window.contentItem.mapFromItem(
                            leftSection, 0, leftSection.height,
                            leftSection.width, leftSection.height
                        )
                        var x = pillRect.x
                        var y = pillRect.y + 4
                        anchor.rect = Qt.rect(x, y, implicitWidth, implicitHeight)
                    }
                }

                GlassSurface {
                    id: hubCard
                    theme: root.theme
                    strong: false
                    anchors.fill: parent
                    radius: root.theme.radiusModal
                    clip: true

                    scale: panelWindow.hubOpen ? 1 : 0.96
                    opacity: panelWindow.hubOpen ? 1 : 0
                    Behavior on scale { NumberAnimation { duration: root.theme.motionBaseMs } }
                    Behavior on opacity { NumberAnimation { duration: root.theme.motionBaseMs } }

                    Process {
                        id: hubLauncher
                        running: false
                    }

                    property string home: root.homeDir
                    property int hubSection: 0  // 0 Overview, 1 Control, 2 Developer, 3 Wallpapers, 4 System

                    MouseArea {
                        anchors.fill: parent
                        onClicked: { }
                    }

                    Item {
                        anchors.fill: parent
                        focus: panelWindow.hubOpen
                        Keys.onEscapePressed: panelWindow.hubOpen = false

                        Column {
                            anchors.fill: parent
                            anchors.margins: root.theme.spacingLg
                            spacing: 0

                            // ─── Header: logo + title + close ───
                            Row {
                                width: parent.width - 32
                                height: 44
                                spacing: 10
                                Image {
                                    source: "file:///home/the_architect/assets/icons/Logo-bar.svg"
                                    width: 22
                                    height: 22
                                    anchors.verticalCenter: parent.verticalCenter
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                }
                                Text {
                                    text: "OS Hub"
                                    color: root.theme.logoPurple
                                    font.pixelSize: 14
                                    font.family: root.theme.fontFamily
                                    font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Item { width: parent.width - 22 - 80 - closeBtn.width - 20; height: 1 }
                                MouseArea {
                                    id: closeBtn
                                    width: 28
                                    height: 28
                                    anchors.verticalCenter: parent.verticalCenter
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: panelWindow.hubOpen = false
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 6
                                        color: parent.pressed ? root.theme.border : "transparent"
                                        opacity: parent.containsMouse ? 0.6 : 0
                                        Behavior on opacity { NumberAnimation { duration: root.theme.motionFastMs } }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"
                                        color: root.theme.textMuted
                                        font.pixelSize: 16
                                        font.family: root.theme.fontFamily
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width - 32
                                height: 1
                                color: root.theme.border
                                opacity: 0.5
                            }
                            Item { height: 12 }

                            // ─── Two-column: Nav rail | Content ───
                            Row {
                                width: parent.width - 32
                                height: parent.height - 44 - 1 - 12 - 12
                                spacing: 16

                                // Left: Nav rail (ML4W-style sidebar)
                                Column {
                                    width: 132
                                    height: parent.height
                                    spacing: 2

                                    Repeater {
                                        model: [
                                            { id: 0, label: "Overview", icon: "house" },
                                            { id: 1, label: "Control Plane", icon: "gear" },
                                            { id: 2, label: "Developer", icon: "folder-open" },
                                            { id: 3, label: "Wallpapers", icon: "images-square" },
                                            { id: 4, label: "System", icon: "cursor" }
                                        ]
                                        delegate: MouseArea {
                                            required property var modelData
                                            width: 132
                                            height: 36
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: hubCard.hubSection = modelData.id

                                            Rectangle {
                                                anchors.fill: parent
                                                anchors.margins: 2
                                                radius: root.theme.radiusPill
                                                color: hubCard.hubSection === modelData.id ? root.theme.accentDim2 : (navHover.containsMouse ? root.theme.border : "transparent")
                                                opacity: hubCard.hubSection === modelData.id ? 1 : (navHover.containsMouse ? 0.5 : 0)
                                                Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                            }
                                            Row {
                                                anchors.fill: parent
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 12
                                                spacing: 8
                                                Image {
                                                    width: 16
                                                    height: 16
                                                    source: root.phosphorDir + "/" + modelData.icon + ".svg"
                                                    fillMode: Image.PreserveAspectFit
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                                Text {
                                                    text: modelData.label
                                                    color: hubCard.hubSection === modelData.id ? root.theme.accentPrimary : root.theme.textSecondary
                                                    font.pixelSize: 11
                                                    font.family: root.theme.fontFamily
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                            MouseArea {
                                                id: navHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                propagateComposedEvents: true
                                            }
                                        }
                                    }
                                }

                                // Right: Content stack (card-based panels)
                                Item {
                                    width: parent.width - 132 - 16
                                    height: parent.height
                                    clip: true

                                    StackLayout {
                                        anchors.fill: parent
                                        currentIndex: hubCard.hubSection

                                        // ─── Overview ───
                                        Flickable {
                                            id: contentOverviewFlick
                                            contentWidth: contentOverview.width
                                            contentHeight: contentOverview.height
                                            clip: true
                                            Column {
                                                id: contentOverview
                                                width: contentOverviewFlick.width
                                                spacing: 12
                                                Text {
                                                    text: "Quick access"
                                                    color: root.theme.textMuted
                                                    font.pixelSize: 10
                                                    font.family: root.theme.fontFamily
                                                    font.letterSpacing: 0.8
                                                }
                                                Row {
                                                    spacing: 8
                                                    Repeater {
                                                        model: [
                                                            { label: "Validate configs", cmd: ["ghostty", "-e", "bash", "-lc", hubCard.home + "/scripts/validate-configs.sh; echo; echo 'Press Enter to close'; read"] },
                                                            { label: "Reload Hypr", cmd: ["sh", "-c", "hyprctl reload >/dev/null 2>&1 || true"] },
                                                            { label: "Open AI", cmd: [hubCard.home + "/.config/hypr/scripts/openclaw-sidebar.sh"] }
                                                        ]
                                                        delegate: Rectangle {
                                                            required property var modelData
                                                            height: 32
                                                            width: labelText.width + 20
                                                            radius: root.theme.radiusPill
                                                            color: overviewPill.containsMouse ? root.theme.accentDim2 : root.theme.bgBase
                                                            border.width: 1
                                                            border.color: root.theme.border
                                                            MouseArea {
                                                                id: overviewPill
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    hubLauncher.command = modelData.cmd
                                                                    hubLauncher.running = true
                                                                    panelWindow.hubOpen = false
                                                                }
                                                            }
                                                            Text {
                                                                id: labelText
                                                                anchors.centerIn: parent
                                                                text: modelData.label
                                                                color: root.theme.textPrimary
                                                                font.pixelSize: 11
                                                                font.family: root.theme.fontFamily
                                                            }
                                                        }
                                                    }
                                                }
                                                Item { height: 8 }
                                                Text {
                                                    text: "Edition: " + root.editionName
                                                    color: root.theme.textMuted
                                                    font.pixelSize: 10
                                                    font.family: root.theme.fontFamily
                                                }
                                            }
                                        }

                                        // ─── Control Plane ───
                                        Flickable {
                                            id: contentControlFlick
                                            contentWidth: contentControl.width
                                            contentHeight: contentControl.height
                                            clip: true
                                            Column {
                                                id: contentControl
                                                width: contentControlFlick.width
                                                spacing: 12
                                                HubCard {
                                                    theme: root.theme
                                                    phosphorDir: root.phosphorDir
                                                    title: "Control Plane"
                                                    description: "Validate configs, reload Hyprland, restart services."
                                                    actions: [
                                                        { label: "Validate configs", icon: "gear", command: ["ghostty", "-e", "bash", "-lc", hubCard.home + "/scripts/validate-configs.sh; echo; echo 'Press Enter to close'; read"] },
                                                        { label: "Reload Hypr", icon: "gear", command: ["sh", "-c", "hyprctl reload >/dev/null 2>&1 || true"] },
                                                        { label: "AI Gateway (restart)", icon: "gear", command: ["sh", "-c", "systemctl --user restart openclaw-gateway.service >/dev/null 2>&1 || true"] },
                                                        { label: "QuickSettings (AGS)", icon: "gear", command: ["ghostty", "-e", "bash", "-lc", hubCard.home + "/.config/SL1C3D-L4BS/bin/sl1c3d-ags doctor; read"] }
                                                    ]
                                                    launcher: hubLauncher
                                                    onRun: { hubLauncher.command = cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                }
                                            }
                                        }

                                        // ─── Developer ───
                                        Flickable {
                                            id: contentDeveloperFlick
                                            contentWidth: contentDeveloper.width
                                            contentHeight: contentDeveloper.height
                                            clip: true
                                            Column {
                                                id: contentDeveloper
                                                width: contentDeveloperFlick.width
                                                spacing: 12
                                                HubCard {
                                                    theme: root.theme
                                                    phosphorDir: root.phosphorDir
                                                    title: "Developer"
                                                    description: "Open paths in Yazi or terminal (Zellij)."
                                                    pathRows: [
                                                        { path: "~/dev", label: "dev" },
                                                        { path: "~/.config", label: "config" },
                                                        { path: "~/assets", label: "assets" }
                                                    ]
                                                    home: hubCard.home
                                                    launcher: hubLauncher
                                                    onRun: { hubLauncher.command = cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                }
                                            }
                                        }

                                        // ─── Wallpapers ───
                                        Flickable {
                                            id: contentWallpapersFlick
                                            contentWidth: contentWallpapers.width
                                            contentHeight: contentWallpapers.height
                                            clip: true
                                            Column {
                                                id: contentWallpapers
                                                width: contentWallpapersFlick.width
                                                spacing: 12
                                                HubCard {
                                                    theme: root.theme
                                                    phosphorDir: root.phosphorDir
                                                    title: "Wallpapers"
                                                    description: "Set wallpaper or open Waypaper."
                                                    home: hubCard.home
                                                    launcher: hubLauncher
                                                    wallpaperNames: ["sl1c3d-l4bs-01.png","sl1c3d-l4bs-02.png","sl1c3d-l4bs-03.png","sl1c3d-l4bs-04.png","sl1c3d-l4bs-05.png","sl1c3d-l4bs-06.png","sl1c3d-l4bs-07.png","sl1c3d-l4bs-08.png","sl1c3d-l4bs-09.png","sl1c3d-l4bs-10.png","sl1c3d-l4bs-11.png","sl1c3d-l4bs-12.png","sl1c3d-l4bs-13.png","sl1c3d-l4bs-14.png","sl1c3d-l4bs-15.png"]
                                                    onRun: { hubLauncher.command = cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                }
                                            }
                                        }

                                        // ─── System ───
                                        Flickable {
                                            id: contentSystemFlick
                                            contentWidth: contentSystem.width
                                            contentHeight: contentSystem.height
                                            clip: true
                                            Column {
                                                id: contentSystem
                                                width: contentSystemFlick.width
                                                spacing: 12
                                                HubCard {
                                                    theme: root.theme
                                                    phosphorDir: root.phosphorDir
                                                    title: "System"
                                                    description: "Launcher, AI, config editor."
                                                    actions: [
                                                        { label: "AI (OpenClaw)", icon: "cursor", command: [hubCard.home + "/.config/hypr/scripts/openclaw-sidebar.sh"] },
                                                        { label: "Fuzzel", icon: "magnifying-glass", command: ["fuzzel"] },
                                                        { label: "Hypr config (nvim)", icon: "file-code", command: ["ghostty", "-e", "nvim", hubCard.home + "/.config/hypr"] },
                                                        { label: "Waypaper restore", icon: "images-square", command: ["waypaper", "--restore"] }
                                                    ]
                                                    launcher: hubLauncher
                                                    onRun: { hubLauncher.command = cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
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
                                        font.family: root.theme.fontFamily
                                    }
                                }
                            }

                            Item { width: 8; height: 1 }

                            Text {
                                text: calendarContent.monthNames[calendarContent.viewMonth] + " " + calendarContent.viewYear
                                color: root.theme.logoPurple
                                font.pixelSize: 14
                                font.family: root.theme.fontFamily
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
                                        font.family: root.theme.fontFamily
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
                                    font.family: root.theme.fontFamily
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
                                        font.family: root.theme.fontFamily
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
                                font.family: root.theme.fontFamily
                                font.weight: Font.Bold
                            }
                            Text {
                                text: root.barDateString
                                color: root.theme.logoPurple
                                font.pixelSize: 12
                                font.family: root.theme.fontFamily
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
