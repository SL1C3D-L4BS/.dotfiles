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
            property bool powerMenuOpen: false

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

                    Row {
                        id: timeDateSection
                        spacing: 6
                        height: 24

                        Rectangle {
                            id: timePill
                            height: 24
                            width: timePillRow.width + 14
                            radius: root.theme.radiusPill
                            color: root.theme.surfaceGlassStrong
                            Row {
                                id: timePillRow
                                anchors.centerIn: parent
                                spacing: 6
                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: root.phosphorDir + "/clock.svg"
                                    width: 12
                                    height: 12
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.barTimeString
                                    color: root.theme.accentPrimary
                                    font.pixelSize: 12
                                    font.family: root.theme.fontFamily
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: panelWindow.calendarOpen = !panelWindow.calendarOpen
                            }
                        }

                        Rectangle {
                            id: timeDatePill
                            height: 24
                            width: datePillRow.width + 14
                            radius: root.theme.radiusPill
                            color: root.theme.surfaceGlassStrong
                            Row {
                                id: datePillRow
                                anchors.centerIn: parent
                                spacing: 6
                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: root.phosphorDir + "/calendar-blank.svg"
                                    width: 12
                                    height: 12
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.barDateString
                                    color: root.theme.logoPurple
                                    font.pixelSize: 11
                                    font.family: root.theme.fontFamily
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: panelWindow.calendarOpen = !panelWindow.calendarOpen
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

                // ─── Center: 10 fixed floating workspace pills ─────────────
                Item {
                    anchors.centerIn: parent
                    height: parent.height
                    width: centerWsRow.width

                    Row {
                        id: centerWsRow
                        anchors.centerIn: parent
                        spacing: 5

                        Repeater {
                            model: 10

                            Item {
                                id: wsFixed
                                required property int modelData
                                property int wsId: modelData + 1
                                property bool urgentBlink: false

                                // Live workspace lookup — null when workspace doesn't exist yet
                                property var wsData: {
                                    const all = Hyprland.workspaces.values
                                    for (const w of all) {
                                        if (w.id === wsId) return w
                                    }
                                    return null
                                }

                                property bool isActive: {
                                    const mon = Hyprland.focusedMonitor
                                    return mon !== null
                                        && mon.activeWorkspace !== null
                                        && mon.activeWorkspace.id === wsId
                                }
                                property bool isOccupied: wsData !== null
                                property bool isUrgent:   wsData !== null && wsData.urgent

                                // active=36  occupied=26  empty=18
                                width:  isActive ? 36 : (isOccupied ? 26 : 18)
                                height: 24

                                Behavior on width {
                                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                                }

                                // Urgent blink animation
                                SequentialAnimation {
                                    loops: Animation.Infinite
                                    running: wsFixed.isUrgent && !wsFixed.isActive
                                    PropertyAction { target: wsFixed; property: "urgentBlink"; value: true }
                                    PauseAnimation  { duration: 480 }
                                    PropertyAction { target: wsFixed; property: "urgentBlink"; value: false }
                                    PauseAnimation  { duration: 480 }
                                    onStopped: wsFixed.urgentBlink = false
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: wsFixed.isUrgent && wsFixed.urgentBlink
                                               ? root.theme.accentRed
                                           : wsFixed.isActive
                                               ? root.theme.accentPrimary
                                           : wsFixed.isOccupied
                                               ? root.theme.bgBase
                                           : "#141414"

                                    border.width: wsFixed.isOccupied && !wsFixed.isActive ? 1 : 0
                                    border.color: root.theme.border

                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    // Occupied dot (shown when not active)
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width:  wsFixed.isOccupied ? 5 : 4
                                        height: wsFixed.isOccupied ? 5 : 4
                                        radius: 3
                                        color:  wsFixed.isOccupied
                                                    ? root.theme.accentPrimary
                                                    : root.theme.textMuted
                                        opacity: wsFixed.isOccupied ? 0.80 : 0.18
                                        visible: !wsFixed.isActive
                                    }

                                    // Workspace number — active only
                                    Text {
                                        anchors.centerIn: parent
                                        text: wsFixed.wsId
                                        color: root.theme.bgBase
                                        font.pixelSize: 11
                                        font.family: root.theme.fontFamily
                                        font.bold: true
                                        visible: wsFixed.isActive
                                    }

                                    Accessible.role: Accessible.Button
                                    Accessible.name: "Workspace " + wsFixed.wsId
                                        + (wsFixed.isActive   ? ", active"   : "")
                                        + (wsFixed.isOccupied ? ", occupied" : "")
                                        + (wsFixed.isUrgent   ? ", urgent"   : "")
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (wsFixed.wsData) {
                                            wsFixed.wsData.activate()
                                        } else {
                                            Hyprland.dispatch("workspace " + wsFixed.wsId)
                                        }
                                    }
                                }
                            }
                        }
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

                    // ─── CPU + RAM pill — SVG icons, color-coded, click→btop ─
                    Rectangle {
                        id: cpuRamPill
                        height: 24
                        width: cpuRamContent.width + 14
                        radius: 8
                        color: root.theme.bgBase
                        visible: SystemInfo.cpuUsage !== "0%"

                        Accessible.role: Accessible.Button
                        Accessible.name: "CPU: " + SystemInfo.cpuUsage + ", RAM: " + SystemInfo.memoryUsage + ". Click to open btop."

                        // Dynamic color based on load level
                        readonly property real cpuNum: parseFloat(SystemInfo.cpuUsage) || 0
                        readonly property real ramNum: parseFloat(SystemInfo.memoryUsage) || 0
                        readonly property color cpuColor: cpuNum > 80 ? root.theme.accentRed
                                                        : cpuNum > 50 ? root.theme.accentOrange
                                                        :               root.theme.accentGreen
                        readonly property color ramColor: ramNum > 80 ? root.theme.accentRed
                                                        : ramNum > 50 ? root.theme.accentOrange
                                                        :               root.theme.logoPurple

                        Row {
                            id: cpuRamContent
                            anchors.centerIn: parent
                            spacing: 5

                            // CPU icon (blurple chip SVG)
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                source: root.phosphorDir + "/cpu.svg"
                                width: 13
                                height: 13
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: SystemInfo.cpuUsage
                                color: cpuRamPill.cpuColor
                                font.pixelSize: 11
                                font.family: root.theme.fontFamily
                                Behavior on color { ColorAnimation { duration: root.theme.motionBaseMs } }
                            }

                            // Divider
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 1
                                height: 12
                                color: root.theme.border
                                opacity: 0.6
                            }

                            // RAM icon (purple memory SVG)
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                source: root.phosphorDir + "/memory.svg"
                                width: 13
                                height: 13
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: SystemInfo.memoryUsage
                                color: cpuRamPill.ramColor
                                font.pixelSize: 11
                                font.family: root.theme.fontFamily
                                Behavior on color { ColorAnimation { duration: root.theme.motionBaseMs } }
                            }
                        }

                        // Hover highlight
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: btopMouseArea.containsMouse ? "#18ffffff" : "transparent"
                            Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                        }

                        MouseArea {
                            id: btopMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                hubLauncher.command = [
                                    "bash", "-c",
                                    root.homeDir + "/.config/hypr/scripts/scratch-toggle.sh " +
                                    "btop btop-scratch " +
                                    "'ghostty --class=btop-scratch -e btop'"
                                ]
                                hubLauncher.running = true
                            }
                        }
                    }

                    // ─── Power menu pill ──────────────────────────────────────
                    Rectangle {
                        id: powerPill
                        height: 24
                        width: 28
                        radius: 8
                        color: panelWindow.powerMenuOpen
                            ? root.theme.accentDim2
                            : (powerPillHover.containsMouse ? root.theme.bgBase : root.theme.bgBase)
                        border.width: 1
                        border.color: panelWindow.powerMenuOpen
                            ? root.theme.accentPrimary
                            : root.theme.border
                        opacity: powerPillHover.containsMouse ? 1.0 : 0.85

                        Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                        Behavior on opacity      { NumberAnimation  { duration: root.theme.motionFastMs } }

                        Accessible.role: Accessible.Button
                        Accessible.name: "Power menu"

                        Text {
                            anchors.centerIn: parent
                            text: "⏻"
                            color: panelWindow.powerMenuOpen
                                ? root.theme.accentPrimary
                                : root.theme.textMuted
                            font.pixelSize: 13
                            font.family: root.theme.fontFamily
                            Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                        }

                        MouseArea {
                            id: powerPillHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panelWindow.powerMenuOpen = !panelWindow.powerMenuOpen
                        }
                    }
                }
            }

            // ─── Power menu dropdown popup ────────────────────────────────────
            PopupWindow {
                id: powerMenuPopup
                anchor.window: panelWindow
                implicitWidth: 220
                implicitHeight: powerMenuCol.implicitHeight + 24
                visible: panelWindow.powerMenuOpen
                color: "transparent"

                onVisibleChanged: if (!visible) panelWindow.powerMenuOpen = false

                anchor.onAnchoring: {
                    if (!anchor.window) return
                    const win = anchor.window
                    const pr = win.contentItem.mapFromItem(
                        powerPill, 0, powerPill.height, powerPill.width, powerPill.height)
                    // align right edge of popup with right edge of pill
                    const x = pr.x + powerPill.width - implicitWidth
                    anchor.rect = Qt.rect(x, pr.y + 6, implicitWidth, implicitHeight)
                }

                GlassSurface {
                    id: powerCard
                    theme: root.theme
                    strong: true
                    anchors.fill: parent
                    radius: root.theme.radiusModal
                    clip: true

                    scale:   panelWindow.powerMenuOpen ? 1.0 : 0.94
                    opacity: panelWindow.powerMenuOpen ? 1.0 : 0.0
                    Behavior on scale   { NumberAnimation { duration: root.theme.motionBaseMs; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: root.theme.motionBaseMs } }

                    Keys.onEscapePressed: panelWindow.powerMenuOpen = false
                    focus: panelWindow.powerMenuOpen

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    Column {
                        id: powerMenuCol
                        anchors {
                            top: parent.top; left: parent.left; right: parent.right
                            margins: 10
                        }
                        spacing: 2

                        // ── Header ──────────────────────────────────────────────
                        Item {
                            width: parent.width
                            height: 36

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Power"
                                color: root.theme.logoPurple
                                font.pixelSize: 13
                                font.family: root.theme.fontFamily
                                font.weight: Font.DemiBold
                            }

                            // Close ×
                            MouseArea {
                                id: pwrClose
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 24; height: 24
                                cursorShape: Qt.PointingHandCursor
                                onClicked: panelWindow.powerMenuOpen = false
                                Rectangle {
                                    anchors.fill: parent; radius: 6
                                    color: pwrClose.containsMouse ? root.theme.border : "transparent"
                                    Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "×"; color: root.theme.textMuted
                                    font.pixelSize: 16; font.family: root.theme.fontFamily
                                }
                            }
                        }

                        // ── Divider ──────────────────────────────────────────────
                        Rectangle {
                            width: parent.width; height: 1
                            color: root.theme.border; opacity: 0.5
                        }
                        Item { width: 1; height: 4 }

                        // ── Power actions ────────────────────────────────────────
                        Repeater {
                            model: [
                                { label: "Lock",     icon: "⏾", sub: "Lock screen",          accent: root.theme.textMuted,    cmd: ["loginctl", "lock-session"] },
                                { label: "Suspend",  icon: "󰒲", sub: "Sleep mode",            accent: root.theme.accentPrimary, cmd: ["systemctl", "suspend"] },
                                { label: "Logout",   icon: "󰗽", sub: "End session",           accent: root.theme.accentPrimary, cmd: ["sh", "-c", "hyprctl dispatch exit"] },
                                { label: "Reboot",   icon: "󰑓", sub: "Restart system",        accent: root.theme.accentOrange,  cmd: ["systemctl", "reboot"] },
                                { label: "Shutdown", icon: "⏻", sub: "Power off",             accent: root.theme.accentRed,     cmd: ["systemctl", "poweroff"] }
                            ]

                            delegate: MouseArea {
                                required property var modelData
                                id: pwrRow
                                width: powerMenuCol.width
                                height: 44
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: {
                                    panelWindow.powerMenuOpen = false
                                    hubLauncher.command = modelData.cmd
                                    hubLauncher.running = true
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: root.theme.radiusPill
                                    color: pwrRow.containsMouse ? root.theme.accentDim2 : "transparent"
                                    Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                }

                                Row {
                                    anchors {
                                        left: parent.left; right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 10; rightMargin: 10
                                    }
                                    spacing: 12

                                    // Colored icon glyph
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: pwrRow.modelData.icon
                                        color: pwrRow.modelData.accent
                                        font.pixelSize: 16
                                        font.family: root.theme.fontFamily
                                        width: 20
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    // Label + sub
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1
                                        Text {
                                            text: pwrRow.modelData.label
                                            color: root.theme.textPrimary
                                            font.pixelSize: 12
                                            font.family: root.theme.fontFamily
                                            font.weight: Font.Medium
                                        }
                                        Text {
                                            text: pwrRow.modelData.sub
                                            color: root.theme.textMuted
                                            font.pixelSize: 10
                                            font.family: root.theme.fontFamily
                                        }
                                    }

                                    // Hover arrow
                                    Item { width: parent.width - 20 - 12 - 100; height: 1 }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "›"
                                        color: pwrRow.containsMouse
                                            ? pwrRow.modelData.accent
                                            : root.theme.border
                                        font.pixelSize: 16
                                        font.family: root.theme.fontFamily
                                        Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                    }
                                }
                            }
                        }

                        Item { width: 1; height: 4 }
                    }
                }
            }

            PopupWindow {
                id: hubPopup
                anchor.window: panelWindow
                // SL1C3D HUB: two-column nav + card-based content (ML4W/Omarchy-style), thinner modal
                implicitWidth: 440
                implicitHeight: 580
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
                                    text: "SL1C3D HUB"
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

                                // Left: Nav rail (ML4W-style sidebar), narrower for thinner modal
                                Column {
                                    width: 108
                                    height: parent.height
                                    spacing: 2

                                    Repeater {
                                        model: [
                                            { id: 0, label: "Overview", icon: "folder-open" },
                                            { id: 1, label: "Control Plane", icon: "gear" },
                                            { id: 2, label: "Developer", icon: "folder-open" },
                                            { id: 3, label: "Wallpapers", icon: "images-square" },
                                            { id: 4, label: "System", icon: "gear" }
                                        ]
                                        delegate: MouseArea {
                                            required property var modelData
                                            width: 108
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
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 6
                                                Image {
                                                    width: 14
                                                    height: 14
                                                    source: root.phosphorDir + "/" + modelData.icon + ".svg"
                                                    fillMode: Image.PreserveAspectFit
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                                Text {
                                                    text: modelData.label
                                                    color: hubCard.hubSection === modelData.id ? root.theme.accentPrimary : root.theme.textSecondary
                                                    font.pixelSize: 10
                                                    font.family: root.theme.fontFamily
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    elide: Text.ElideRight
                                                    width: 108 - 10 - 10 - 14 - 6
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
                                    width: parent.width - 108 - 16
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

                                        // ─── Control Plane (2026-style: grouped sections, icons, hierarchy) ───
                                        Flickable {
                                            id: contentControlFlick
                                            contentWidth: contentControl.width
                                            contentHeight: contentControl.height
                                            clip: true
                                            Column {
                                                id: contentControl
                                                width: contentControlFlick.width
                                                spacing: 16
                                                property string phosphorDir: root.phosphorDir

                                                Text {
                                                    text: "Control Plane"
                                                    color: root.theme.logoPurple
                                                    font.pixelSize: 13
                                                    font.family: root.theme.fontFamily
                                                    font.weight: Font.DemiBold
                                                }
                                                Text {
                                                    text: "Validate configs, reload Hyprland, restart services."
                                                    color: root.theme.textMuted
                                                    font.pixelSize: 10
                                                    font.family: root.theme.fontFamily
                                                    wrapMode: Text.WordWrap
                                                    width: contentControl.width
                                                }

                                                Item { height: 4 }
                                                Text {
                                                    text: "VALIDATION & RELOAD"
                                                    color: root.theme.textMuted
                                                    font.pixelSize: 9
                                                    font.family: root.theme.fontFamily
                                                    font.letterSpacing: 0.8
                                                }
                                                Repeater {
                                                    model: [
                                                        { label: "Validate configs", sub: "Run validation script", icon: "gear", cmd: ["ghostty", "-e", "bash", "-lc", hubCard.home + "/scripts/validate-configs.sh; echo; echo 'Press Enter to close'; read"] },
                                                        { label: "Reload Hypr", sub: "Apply config changes", icon: "gear", cmd: ["sh", "-c", "hyprctl reload >/dev/null 2>&1 || true"] }
                                                    ]
                                                    delegate: HubActionRow {
                                                        width: contentControl.width
                                                        theme: root.theme
                                                        phosphorDir: contentControl.phosphorDir
                                                        labelText: modelData.label
                                                        subText: modelData.sub
                                                        iconName: modelData.icon
                                                        onClicked: { hubLauncher.command = modelData.cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                    }
                                                }

                                                Item { height: 8 }
                                                Text {
                                                    text: "SERVICES"
                                                    color: root.theme.textMuted
                                                    font.pixelSize: 9
                                                    font.family: root.theme.fontFamily
                                                    font.letterSpacing: 0.8
                                                }
                                                Repeater {
                                                    model: [
                                                        { label: "AI Gateway (restart)", sub: "OpenClaw gateway", icon: "gear", cmd: ["sh", "-c", "systemctl --user restart openclaw-gateway.service >/dev/null 2>&1 || true"] },
                                                        { label: "QuickSettings (AGS)", sub: "AGS doctor", icon: "gear", cmd: ["ghostty", "-e", "bash", "-lc", hubCard.home + "/.config/SL1C3D-L4BS/bin/sl1c3d-ags doctor; read"] }
                                                    ]
                                                    delegate: HubActionRow {
                                                        width: contentControl.width
                                                        theme: root.theme
                                                        phosphorDir: contentControl.phosphorDir
                                                        labelText: modelData.label
                                                        subText: modelData.sub
                                                        iconName: modelData.icon
                                                        onClicked: { hubLauncher.command = modelData.cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                    }
                                                }
                                            }
                                        }

                                        // ─── Developer (2026-style: card path rows, Yazi/Terminal pills) ───
                                        Flickable {
                                            id: contentDeveloperFlick
                                            contentWidth: contentDeveloper.width
                                            contentHeight: contentDeveloper.height
                                            clip: true
                                            Column {
                                                id: contentDeveloper
                                                width: contentDeveloperFlick.width
                                                spacing: 16
                                                property string phosphorDir: root.phosphorDir

                                                Text {
                                                    text: "Developer"
                                                    color: root.theme.logoPurple
                                                    font.pixelSize: 13
                                                    font.family: root.theme.fontFamily
                                                    font.weight: Font.DemiBold
                                                }
                                                Text {
                                                    text: "Open workspace paths in Yazi or Zellij terminal."
                                                    color: root.theme.textMuted
                                                    font.pixelSize: 10
                                                    font.family: root.theme.fontFamily
                                                    wrapMode: Text.WordWrap
                                                    width: contentDeveloper.width
                                                }

                                                Item { height: 4 }
                                                Text {
                                                    text: "WORKSPACE PATHS"
                                                    color: root.theme.textMuted
                                                    font.pixelSize: 9
                                                    font.family: root.theme.fontFamily
                                                    font.letterSpacing: 0.8
                                                }
                                                Repeater {
                                                    model: [
                                                        { path: "~/dev", label: "dev", icon: "folder-open" },
                                                        { path: "~/.config", label: "config", icon: "gear" },
                                                        { path: "~/assets", label: "assets", icon: "images-square" }
                                                    ]
                                                    delegate: Item {
                                                        required property var modelData
                                                        width: contentDeveloper.width
                                                        height: 44
                                                        property string resolvedPath: modelData.path.replace("~", hubCard.home)
                                                        Rectangle {
                                                            anchors.fill: parent
                                                            anchors.margins: 0
                                                            radius: root.theme.radiusPill
                                                            color: "transparent"
                                                            border.width: 1
                                                            border.color: root.theme.border
                                                        }
                                                        Row {
                                                            anchors.fill: parent
                                                            anchors.leftMargin: 12
                                                            anchors.rightMargin: 12
                                                            spacing: 10
                                                            Image {
                                                                width: 16
                                                                height: 16
                                                                source: contentDeveloper.phosphorDir + "/" + modelData.icon + ".svg"
                                                                fillMode: Image.PreserveAspectFit
                                                                anchors.verticalCenter: parent.verticalCenter
                                                            }
                                                            Text {
                                                                text: "~/" + modelData.label
                                                                color: root.theme.textPrimary
                                                                font.pixelSize: 11
                                                                font.family: root.theme.fontFamily
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                width: 70
                                                            }
                                                            Row {
                                                                spacing: 6
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                Rectangle {
                                                                    width: 56
                                                                    height: 26
                                                                    radius: 6
                                                                    color: devYaziMa.containsMouse ? root.theme.accentDim2 : root.theme.bgBase
                                                                    border.width: 1
                                                                    border.color: root.theme.border
                                                                    MouseArea {
                                                                        id: devYaziMa
                                                                        anchors.fill: parent
                                                                        hoverEnabled: true
                                                                        cursorShape: Qt.PointingHandCursor
                                                                        onClicked: {
                                                                            hubLauncher.command = ["ghostty", "-e", "yazi", parent.parent.parent.resolvedPath]
                                                                            hubLauncher.running = true
                                                                            panelWindow.hubOpen = false
                                                                        }
                                                                    }
                                                                    Text {
                                                                        anchors.centerIn: parent
                                                                        text: "Yazi"
                                                                        font.pixelSize: 10
                                                                        font.family: root.theme.fontFamily
                                                                        color: root.theme.textPrimary
                                                                    }
                                                                }
                                                                Rectangle {
                                                                    width: 64
                                                                    height: 26
                                                                    radius: 6
                                                                    color: devTermMa.containsMouse ? root.theme.accentDim2 : root.theme.bgBase
                                                                    border.width: 1
                                                                    border.color: root.theme.border
                                                                    MouseArea {
                                                                        id: devTermMa
                                                                        anchors.fill: parent
                                                                        hoverEnabled: true
                                                                        cursorShape: Qt.PointingHandCursor
                                                                        onClicked: {
                                                                            hubLauncher.command = ["ghostty", "-e", "bash", "-c", "cd " + parent.parent.parent.resolvedPath + " && exec ~/.config/hypr/scripts/zellij-branded.sh"]
                                                                            hubLauncher.running = true
                                                                            panelWindow.hubOpen = false
                                                                        }
                                                                    }
                                                                    Text {
                                                                        anchors.centerIn: parent
                                                                        text: "Terminal"
                                                                        font.pixelSize: 10
                                                                        font.family: root.theme.fontFamily
                                                                        color: root.theme.textPrimary
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                Item { height: 8 }
                                                Text {
                                                    text: "CONFIG"
                                                    color: root.theme.textMuted
                                                    font.pixelSize: 9
                                                    font.family: root.theme.fontFamily
                                                    font.letterSpacing: 0.8
                                                }
                                                HubActionRow {
                                                    width: contentDeveloper.width
                                                    theme: root.theme
                                                    phosphorDir: contentDeveloper.phosphorDir
                                                    labelText: "Hypr config (nvim)"
                                                    subText: "Edit Hyprland config"
                                                    iconName: "file-code"
                                                    onClicked: {
                                                        hubLauncher.command = ["ghostty", "-e", "nvim", hubCard.home + "/.config/hypr"]
                                                        hubLauncher.running = true
                                                        panelWindow.hubOpen = false
                                                    }
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
                                                    width: contentWallpapers.width
                                                    theme: root.theme
                                                    phosphorDir: root.phosphorDir
                                                    title: "Wallpapers"
                                                    description: "Set wallpaper or open Waypaper."
                                                    home: hubCard.home
                                                    wallpaperNames: ["sl1c3d-l4bs-01.png","sl1c3d-l4bs-02.png","sl1c3d-l4bs-03.png","sl1c3d-l4bs-04.png","sl1c3d-l4bs-05.png","sl1c3d-l4bs-06.png","sl1c3d-l4bs-07.png","sl1c3d-l4bs-08.png","sl1c3d-l4bs-09.png","sl1c3d-l4bs-10.png","sl1c3d-l4bs-11.png","sl1c3d-l4bs-12.png","sl1c3d-l4bs-13.png","sl1c3d-l4bs-14.png","sl1c3d-l4bs-15.png"]
                                                    onRun: function(cmd) { hubLauncher.command = cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                }
                                            }
                                        }

                                        // ─── System (2026-style: Launch + Config & restore sections) ───
                                        Flickable {
                                            id: contentSystemFlick
                                            contentWidth: contentSystem.width
                                            contentHeight: contentSystem.height
                                            clip: true
                                            Column {
                                                id: contentSystem
                                                width: contentSystemFlick.width
                                                spacing: 16
                                                property string phosphorDir: root.phosphorDir

                                                Text {
                                                    text: "System"
                                                    color: root.theme.logoPurple
                                                    font.pixelSize: 13
                                                    font.family: root.theme.fontFamily
                                                    font.weight: Font.DemiBold
                                                }
                                                Text {
                                                    text: "Launcher, AI assistant, config editor, wallpaper restore."
                                                    color: root.theme.textMuted
                                                    font.pixelSize: 10
                                                    font.family: root.theme.fontFamily
                                                    wrapMode: Text.WordWrap
                                                    width: contentSystem.width
                                                }

                                                Item { height: 4 }
                                                Text {
                                                    text: "LAUNCH"
                                                    color: root.theme.textMuted
                                                    font.pixelSize: 9
                                                    font.family: root.theme.fontFamily
                                                    font.letterSpacing: 0.8
                                                }
                                                Repeater {
                                                    model: [
                                                        { label: "AI (OpenClaw)", sub: "Sidebar assistant", icon: "cursor", cmd: [hubCard.home + "/.config/hypr/scripts/openclaw-sidebar.sh"] },
                                                        { label: "Fuzzel", sub: "App launcher", icon: "magnifying-glass", cmd: ["fuzzel"] }
                                                    ]
                                                    delegate: HubActionRow {
                                                        width: contentSystem.width
                                                        theme: root.theme
                                                        phosphorDir: contentSystem.phosphorDir
                                                        labelText: modelData.label
                                                        subText: modelData.sub
                                                        iconName: modelData.icon
                                                        onClicked: { hubLauncher.command = modelData.cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                    }
                                                }

                                                Item { height: 8 }
                                                Text {
                                                    text: "CONFIG & RESTORE"
                                                    color: root.theme.textMuted
                                                    font.pixelSize: 9
                                                    font.family: root.theme.fontFamily
                                                    font.letterSpacing: 0.8
                                                }
                                                Repeater {
                                                    model: [
                                                        { label: "Hypr config (nvim)", sub: "Edit Hyprland config", icon: "file-code", cmd: ["ghostty", "-e", "nvim", hubCard.home + "/.config/hypr"] },
                                                        { label: "Waypaper restore", sub: "Restore saved wallpaper", icon: "images-square", cmd: ["waypaper", "--restore"] }
                                                    ]
                                                    delegate: HubActionRow {
                                                        width: contentSystem.width
                                                        theme: root.theme
                                                        phosphorDir: contentSystem.phosphorDir
                                                        labelText: modelData.label
                                                        subText: modelData.sub
                                                        iconName: modelData.icon
                                                        onClicked: { hubLauncher.command = modelData.cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
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

            PopupWindow {
                anchor.window: panelWindow
                anchor.rect.x: 0
                anchor.rect.y: panelWindow.implicitHeight
                anchor.rect.width: 260
                anchor.rect.height: 340
                implicitWidth: 260
                implicitHeight: 340
                visible: panelWindow.calendarOpen
                color: "transparent"

                onVisibleChanged: if (!visible) panelWindow.calendarOpen = false
                anchor.onAnchoring: {
                    if (timeDateSection && anchor.window) {
                        const p = timeDateSection.mapToItem(anchor.window, timeDateSection.width, timeDateSection.height)
                        anchor.rect = Qt.rect(p.x, p.y + 6, 260, 340)
                    }
                }

                GlassSurface {
                    id: calendarContent
                    theme: root.theme
                    strong: false
                    anchors.fill: parent
                    radius: root.theme.radiusModal
                    clip: true
                    focus: panelWindow.calendarOpen
                    Keys.onEscapePressed: panelWindow.calendarOpen = false

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
                        anchors.margins: root.theme.spacingLg
                        spacing: 0

                        // ─── Header: title + close (SL1C3D HUB-style) ───
                        Row {
                            width: parent.width - 32
                            height: 40
                            spacing: 8
                            Image {
                                source: root.phosphorDir + "/calendar-blank.svg"
                                width: 18
                                height: 18
                                anchors.verticalCenter: parent.verticalCenter
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                            Text {
                                text: "Calendar"
                                color: root.theme.logoPurple
                                font.pixelSize: 13
                                font.family: root.theme.fontFamily
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Item { width: parent.width - 18 - 80 - calCloseBtn.width - 8; height: 1 }
                            MouseArea {
                                id: calCloseBtn
                                width: 26
                                height: 26
                                anchors.verticalCenter: parent.verticalCenter
                                cursorShape: Qt.PointingHandCursor
                                onClicked: panelWindow.calendarOpen = false
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
                                    font.pixelSize: 14
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
                        Item { height: 10 }

                        // ─── MONTH navigation ───
                        Text {
                            text: "MONTH"
                            color: root.theme.textMuted
                            font.pixelSize: 9
                            font.family: root.theme.fontFamily
                            font.letterSpacing: 0.8
                        }
                        Item { height: 4 }
                        Row {
                            width: parent.width - 32
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
                                    color: parent.pressed ? root.theme.bgBase : (parent.containsMouse ? root.theme.accentDim2 : "transparent")
                                    opacity: parent.containsMouse && !parent.pressed ? 0.7 : 1
                                    Behavior on opacity { NumberAnimation { duration: root.theme.motionFastMs } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "‹"
                                        color: root.theme.logoPurple
                                        font.pixelSize: 16
                                        font.family: root.theme.fontFamily
                                    }
                                }
                            }

                            Item { width: 8; height: 1 }

                            Text {
                                text: calendarContent.monthNames[calendarContent.viewMonth] + " " + calendarContent.viewYear
                                color: root.theme.textPrimary
                                font.pixelSize: 12
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
                                    color: parent.pressed ? root.theme.bgBase : (parent.containsMouse ? root.theme.accentDim2 : "transparent")
                                    opacity: parent.containsMouse && !parent.pressed ? 0.7 : 1
                                    Behavior on opacity { NumberAnimation { duration: root.theme.motionFastMs } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "›"
                                        color: root.theme.logoPurple
                                        font.pixelSize: 16
                                        font.family: root.theme.fontFamily
                                    }
                                }
                            }
                        }

                        Item { height: 10 }
                        Text {
                            text: "WEEK"
                            color: root.theme.textMuted
                            font.pixelSize: 9
                            font.family: root.theme.fontFamily
                            font.letterSpacing: 0.8
                        }
                        Item { height: 4 }
                        Row {
                            spacing: 2
                            Repeater {
                                model: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
                                Text {
                                    required property string modelData
                                    width: 30
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData
                                    color: root.theme.accentPrimary
                                    font.pixelSize: 9
                                    font.family: root.theme.fontFamily
                                }
                            }
                        }

                        Grid {
                            id: calendarGrid
                            columns: 7
                            rowSpacing: 3
                            columnSpacing: 2
                            width: 7 * 30 + 6 * 2
                            property int year: calendarContent.viewYear
                            property int month: calendarContent.viewMonth
                            property int firstDay: { var d = new Date(calendarGrid.year, calendarGrid.month, 1); return (d.getDay() + 6) % 7 }
                            property int daysInMonth: new Date(calendarGrid.year, calendarGrid.month + 1, 0).getDate()

                            Repeater {
                                model: 42
                                Rectangle {
                                    required property int index
                                    width: 30
                                    height: 24
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
                                            return root.theme.textSecondary
                                        }
                                        font.pixelSize: 11
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

                        Item { height: 12 }
                        Rectangle {
                            width: parent.width - 32
                            height: 1
                            color: root.theme.border
                            opacity: 0.5
                        }
                        Item { height: 10 }

                        Text {
                            text: "CURRENT"
                            color: root.theme.textMuted
                            font.pixelSize: 9
                            font.family: root.theme.fontFamily
                            font.letterSpacing: 0.8
                        }
                        Item { height: 6 }
                        Rectangle {
                            width: parent.width - 32
                            height: 44
                            radius: root.theme.radiusPill
                            color: root.theme.bgBase
                            border.width: 1
                            border.color: root.theme.border
                            Row {
                                anchors.centerIn: parent
                                spacing: 16
                                Text {
                                    text: root.barTimeString
                                    color: root.theme.logoPurple
                                    font.pixelSize: 18
                                    font.family: root.theme.fontFamily
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: root.barDateString
                                    color: root.theme.textPrimary
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
}
