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
    property string barSecondsString: "00"
    property string barDayString: "—"
    property string uptimeString: "—"
    property string tz2String: "—"
    property string tz2Label: "UTC"
    property string devTimerLabel: ""
    property int    devTimerSecsLeft: -1
    property int    devTimerTotal: 0
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
        command: ["sh", "-c", "date '+%H:%M|%S|%b %d, %Y|%A'; uptime -p 2>/dev/null || uptime; TZ=UTC date '+%H:%M'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: function() {
                const lines = (text && text.trim()) ? text.trim().split("\n") : []
                if (lines.length >= 1) {
                    const parts = lines[0].trim().split("|")
                    if (parts.length >= 1) root.barTimeString  = parts[0] || "00:00"
                    if (parts.length >= 2) root.barSecondsString = parts[1] || "00"
                    if (parts.length >= 3) root.barDateString  = parts[2] || "—"
                    if (parts.length >= 4) root.barDayString   = parts[3] || "—"
                }
                if (lines.length >= 2) root.uptimeString = lines[1].trim().replace(/^up\s+/, "") || "—"
                if (lines.length >= 3) root.tz2String    = lines[2].trim() || "—"
            }
        }
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: dateTimeProc.running = true
    }

    // Poll dev-timer state file every 5s
    Process {
        id: devTimerStateProc
        command: ["sh", "-c", "cat \"$HOME/.local/run/dev-timer.state\" 2>/dev/null || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: function() {
                const raw = (text || "").trim()
                if (!raw) { root.devTimerSecsLeft = -1; root.devTimerLabel = ""; root.devTimerTotal = 0; return }
                const parts = raw.split("|")
                const endEpoch = parseInt(parts[0] || "0")
                const lbl = parts[1] || ""
                const tot = parseInt(parts[2] || "0")
                const now = Math.floor(Date.now() / 1000)
                const left = endEpoch - now
                root.devTimerLabel = lbl
                root.devTimerTotal = tot
                root.devTimerSecsLeft = left > 0 ? left : -1
            }
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: devTimerStateProc.running = true
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
            property bool focusOpen: false
            property bool powerMenuOpen: false
            property string calTab: "cal"  // "cal" | "notes"
            property string calSelectedDate: ""
            property string notesContent: ""
            property string notesLoadedDate: ""

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

                        // ── Clock pill → Focus Command Center ──────────────
                        Rectangle {
                            id: timePill
                            height: 24
                            width: timePillRow.width + 14
                            radius: root.theme.radiusPill
                            color: root.theme.surfaceGlassStrong
                            border.width: 1
                            border.color: panelWindow.focusOpen ? root.theme.accentPrimary : "transparent"
                            Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                            Row {
                                id: timePillRow
                                anchors.centerIn: parent
                                spacing: 6
                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: root.phosphorDir + "/clock.svg"
                                    width: 12; height: 12
                                    fillMode: Image.PreserveAspectFit; smooth: true
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
                                onClicked: {
                                    panelWindow.calendarOpen = false
                                    panelWindow.focusOpen = !panelWindow.focusOpen
                                }
                            }
                        }

                        // ── Date pill → Calendar + Notes ──────────────────
                        Rectangle {
                            id: timeDatePill
                            height: 24
                            width: datePillRow.width + 14
                            radius: root.theme.radiusPill
                            color: root.theme.surfaceGlassStrong
                            border.width: 1
                            border.color: panelWindow.calendarOpen ? root.theme.logoPurple : "transparent"
                            Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                            Row {
                                id: datePillRow
                                anchors.centerIn: parent
                                spacing: 6
                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: root.phosphorDir + "/calendar-blank.svg"
                                    width: 12; height: 12
                                    fillMode: Image.PreserveAspectFit; smooth: true
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
                                onClicked: {
                                    panelWindow.focusOpen = false
                                    panelWindow.calendarOpen = !panelWindow.calendarOpen
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

            // ═══════════════════════════════════════════════════════════════
            // FOCUS COMMAND CENTER  (clock pill click)
            // ═══════════════════════════════════════════════════════════════
            PopupWindow {
                id: focusPopup
                anchor.window: panelWindow
                implicitWidth: 280
                implicitHeight: 490
                visible: panelWindow.focusOpen
                color: "transparent"

                onVisibleChanged: if (!visible) panelWindow.focusOpen = false

                anchor.onAnchoring: {
                    if (!anchor.window || !timeDateSection) return
                    const p = timeDateSection.mapToItem(anchor.window, 0, timeDateSection.height)
                    anchor.rect = Qt.rect(p.x, p.y + 6, 280, 490)
                }

                GlassSurface {
                    id: focusCard
                    theme: root.theme
                    strong: true
                    anchors.fill: parent
                    radius: root.theme.radiusModal
                    clip: true

                    scale:   panelWindow.focusOpen ? 1.0 : 0.94
                    opacity: panelWindow.focusOpen ? 1.0 : 0.0
                    Behavior on scale   { NumberAnimation { duration: root.theme.motionBaseMs; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: root.theme.motionBaseMs } }

                    focus: panelWindow.focusOpen
                    Keys.onEscapePressed: panelWindow.focusOpen = false
                    MouseArea { anchors.fill: parent; onClicked: {} }

                    Column {
                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                        spacing: 0

                        // ── Header ─────────────────────────────────────────────
                        Item {
                            width: parent.width; height: 40
                            Text {
                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                text: "Focus"
                                color: root.theme.accentPrimary
                                font.pixelSize: 13; font.weight: Font.DemiBold
                                font.family: root.theme.fontFamily
                            }
                            MouseArea {
                                id: focusCloseBtn
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                width: 24; height: 24
                                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: panelWindow.focusOpen = false
                                Rectangle {
                                    anchors.fill: parent; radius: 6
                                    color: focusCloseBtn.containsMouse ? root.theme.border : "transparent"
                                    Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                }
                                Text { anchors.centerIn: parent; text: "×"; color: root.theme.textMuted; font.pixelSize: 16; font.family: root.theme.fontFamily }
                            }
                        }

                        Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.5 }
                        Item { height: 18 }

                        // ── Large live clock ────────────────────────────────────
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: root.barTimeString + ":" + root.barSecondsString
                            color: root.theme.accentPrimary
                            font.pixelSize: 46; font.weight: Font.Bold
                            font.family: root.theme.fontFamily
                        }
                        Item { height: 4 }
                        Text {
                            width: parent.width; horizontalAlignment: Text.AlignHCenter
                            text: root.barDayString + "  ·  " + root.barDateString
                            color: root.theme.textMuted
                            font.pixelSize: 11; font.family: root.theme.fontFamily
                        }

                        Item { height: 18 }
                        Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.4 }
                        Item { height: 14 }

                        // ── Dev timer ring ─────────────────────────────────────
                        Item {
                            width: parent.width; height: 90

                            Canvas {
                                id: timerRing
                                width: 80; height: 80
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter

                                property real progress: (root.devTimerTotal > 0 && root.devTimerSecsLeft > 0)
                                    ? Math.min(1.0, (root.devTimerTotal - root.devTimerSecsLeft) / root.devTimerTotal)
                                    : 0.0
                                property string arcColor: root.devTimerSecsLeft < 300  ? "#ff5555"
                                                        : root.devTimerSecsLeft < 900  ? "#ffb86c"
                                                        : "#5865F2"

                                onProgressChanged: requestPaint()
                                onArcColorChanged:  requestPaint()

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    var cx = width/2, cy = height/2, r = 34
                                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2)
                                    ctx.strokeStyle = "#2d2d2d"; ctx.lineWidth = 6; ctx.stroke()
                                    if (progress > 0.001) {
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + Math.PI*2*progress)
                                        ctx.strokeStyle = arcColor; ctx.lineWidth = 6
                                        ctx.lineCap = "round"; ctx.stroke()
                                    }
                                }
                                Component.onCompleted: requestPaint()

                                // Center text in ring
                                Column {
                                    anchors.centerIn: parent; spacing: 0
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: {
                                            if (root.devTimerSecsLeft <= 0) return "—"
                                            var h = Math.floor(root.devTimerSecsLeft / 3600)
                                            var m = Math.floor((root.devTimerSecsLeft % 3600) / 60)
                                            var s = root.devTimerSecsLeft % 60
                                            if (h > 0) return h + ":" + String(m).padStart(2,"0")
                                            return String(m).padStart(2,"0") + ":" + String(s).padStart(2,"0")
                                        }
                                        color: root.devTimerSecsLeft > 0 ? timerRing.arcColor : root.theme.textMuted
                                        font.pixelSize: 12; font.weight: Font.DemiBold
                                        font.family: root.theme.fontFamily
                                    }
                                }
                            }

                            Column {
                                anchors { left: timerRing.right; leftMargin: 14; verticalCenter: parent.verticalCenter; right: parent.right }
                                spacing: 6
                                Text {
                                    text: root.devTimerSecsLeft > 0 ? "DEV TIMER" : "NO ACTIVE TIMER"
                                    color: root.theme.textMuted; font.pixelSize: 9; font.letterSpacing: 0.8
                                    font.family: root.theme.fontFamily
                                }
                                Text {
                                    text: root.devTimerLabel || "—"
                                    color: root.theme.textPrimary; font.pixelSize: 12; font.weight: Font.Medium
                                    font.family: root.theme.fontFamily; elide: Text.ElideRight; width: parent.width
                                }
                                MouseArea {
                                    id: timerLaunchBtn
                                    width: parent.width; height: 26
                                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                    onClicked: {
                                        panelWindow.focusOpen = false
                                        hubLauncher.command = ["ghostty", "-e", "bash", "-c",
                                            root.homeDir + "/.config/hypr/scripts/dev-timer.sh; exec bash"]
                                        hubLauncher.running = true
                                    }
                                    Rectangle {
                                        anchors.fill: parent; radius: root.theme.radiusPill
                                        color: timerLaunchBtn.containsMouse ? root.theme.accentDim2 : root.theme.bgBase
                                        border.width: 1; border.color: root.theme.border
                                        Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: root.devTimerSecsLeft > 0 ? "New timer" : "Start timer"
                                            color: root.theme.accentPrimary; font.pixelSize: 10; font.family: root.theme.fontFamily
                                        }
                                    }
                                }
                            }
                        }

                        Item { height: 14 }
                        Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.4 }
                        Item { height: 14 }

                        // ── Quick timers ───────────────────────────────────────
                        Text {
                            text: "QUICK TIMER"
                            color: root.theme.textMuted; font.pixelSize: 9; font.letterSpacing: 0.8
                            font.family: root.theme.fontFamily
                        }
                        Item { height: 8 }
                        Row {
                            width: parent.width; spacing: 6
                            Repeater {
                                model: [
                                    { label: "15m", mins: 15 }, { label: "25m", mins: 25 },
                                    { label: "45m", mins: 45 }, { label: "90m", mins: 90 }
                                ]
                                delegate: MouseArea {
                                    required property var modelData
                                    id: qtBtn
                                    width: (parent.width - 18) / 4; height: 28
                                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                    onClicked: {
                                        var secs = modelData.mins * 60
                                        hubLauncher.command = ["bash", "-c",
                                            "END=$(( $(date +%s) + " + secs + " )); " +
                                            "mkdir -p ~/.local/run; " +
                                            "printf '%s' \"$END|" + modelData.label + " focus|" + secs + "\" > ~/.local/run/dev-timer.state; " +
                                            "notify-send 'Dev Timer' '" + modelData.label + " timer started' -i clock -u low"]
                                        hubLauncher.running = true
                                        panelWindow.focusOpen = false
                                    }
                                    Rectangle {
                                        anchors.fill: parent; radius: root.theme.radiusPill
                                        color: qtBtn.containsMouse ? root.theme.accentDim2 : root.theme.bgBase
                                        border.width: 1; border.color: root.theme.border
                                        Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        Text { anchors.centerIn: parent; text: qtBtn.modelData.label; color: root.theme.accentPrimary; font.pixelSize: 11; font.family: root.theme.fontFamily }
                                    }
                                }
                            }
                        }

                        Item { height: 14 }
                        Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.4 }
                        Item { height: 14 }

                        // ── World clocks ───────────────────────────────────────
                        Text {
                            text: "WORLD CLOCKS"
                            color: root.theme.textMuted; font.pixelSize: 9; font.letterSpacing: 0.8
                            font.family: root.theme.fontFamily
                        }
                        Item { height: 8 }
                        Item {
                            width: parent.width; height: 26
                            Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "Local"; color: root.theme.textSecondary; font.pixelSize: 11; font.family: root.theme.fontFamily }
                            Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: root.barTimeString; color: root.theme.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold; font.family: root.theme.fontFamily }
                        }
                        Item {
                            width: parent.width; height: 26
                            Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "UTC"; color: root.theme.textSecondary; font.pixelSize: 11; font.family: root.theme.fontFamily }
                            Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: root.tz2String; color: root.theme.logoPurple; font.pixelSize: 13; font.weight: Font.DemiBold; font.family: root.theme.fontFamily }
                        }

                        Item { height: 14 }
                        Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.4 }
                        Item { height: 12 }

                        // ── Uptime ─────────────────────────────────────────────
                        Item {
                            width: parent.width; height: 20
                            Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "UPTIME"; color: root.theme.textMuted; font.pixelSize: 9; font.letterSpacing: 0.8; font.family: root.theme.fontFamily }
                            Text {
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                text: root.uptimeString; color: root.theme.textSecondary; font.pixelSize: 10; font.family: root.theme.fontFamily
                                elide: Text.ElideLeft; width: parent.width * 0.72; horizontalAlignment: Text.AlignRight
                            }
                        }
                        Item { height: 14 }
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // CALENDAR + NOTES PANEL  (date pill click)
            // ═══════════════════════════════════════════════════════════════
            PopupWindow {
                id: calPopup
                anchor.window: panelWindow
                implicitWidth: 320
                implicitHeight: 480
                visible: panelWindow.calendarOpen
                color: "transparent"

                onVisibleChanged: if (!visible) panelWindow.calendarOpen = false

                anchor.onAnchoring: {
                    if (!anchor.window || !timeDateSection) return
                    const p = timeDateSection.mapToItem(anchor.window, 0, timeDateSection.height)
                    anchor.rect = Qt.rect(p.x, p.y + 6, 320, 480)
                }

                GlassSurface {
                    id: calCard
                    theme: root.theme
                    strong: true
                    anchors.fill: parent
                    radius: root.theme.radiusModal
                    clip: true

                    scale:   panelWindow.calendarOpen ? 1.0 : 0.94
                    opacity: panelWindow.calendarOpen ? 1.0 : 0.0
                    Behavior on scale   { NumberAnimation { duration: root.theme.motionBaseMs; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: root.theme.motionBaseMs } }

                    focus: panelWindow.calendarOpen
                    Keys.onEscapePressed: panelWindow.calendarOpen = false
                    MouseArea { anchors.fill: parent; onClicked: {} }

                    // ── Notes I/O processes ────────────────────────────────────
                    Process {
                        id: notesLoadProc
                        running: false
                        stdout: StdioCollector {
                            onStreamFinished: function() {
                                panelWindow.notesContent = text || ""
                                if (notesEditor) notesEditor.text = panelWindow.notesContent
                            }
                        }
                    }
                    Process { id: notesSaveProc; running: false }
                    Process {
                        id: notesDaysProc
                        running: false
                        stdout: StdioCollector {
                            onStreamFinished: function() {
                                calCard.noteDays = (text || "").trim().split("\n").filter(function(x) { return x.trim().length > 0 })
                            }
                        }
                    }
                    Process {
                        id: recentNotesProc
                        running: false
                        stdout: StdioCollector {
                            onStreamFinished: function() {
                                var chunks = (text || "").trim().split("\n---SEP---\n")
                                calCard.recentNotes = chunks.filter(function(c) { return c.trim().length > 0 }).map(function(chunk) {
                                    var lines = chunk.trim().split("\n")
                                    return { date: lines[0] || "—", preview: lines.slice(1).join(" ").trim().substring(0, 60) }
                                })
                            }
                        }
                    }

                    property var noteDays: []
                    property var recentNotes: []
                    property int viewYear:  new Date().getFullYear()
                    property int viewMonth: new Date().getMonth()
                    property var monthNames: ["January","February","March","April","May","June","July","August","September","October","November","December"]

                    function dateKey(y, m, d) {
                        return String(y) + "-" + String(m + 1).padStart(2,"0") + "-" + String(d).padStart(2,"0")
                    }
                    function isoWeek(y, m, d) {
                        var date = new Date(y, m, d)
                        var onejan = new Date(date.getFullYear(), 0, 1)
                        return Math.ceil(((date - onejan) / 86400000 + onejan.getDay() + 1) / 7)
                    }
                    function loadNote(key) {
                        notesLoadProc.command = ["sh", "-c",
                            "mkdir -p ~/.local/share/sl1c3d-labs/notes && " +
                            "cat ~/.local/share/sl1c3d-labs/notes/" + key + ".txt 2>/dev/null || true"]
                        notesLoadProc.running = true
                    }
                    function saveNote() {
                        if (!panelWindow.calSelectedDate) return
                        notesSaveProc.environment = { "NOTE_CONTENT": notesEditor.text }
                        notesSaveProc.command = ["sh", "-c",
                            "mkdir -p ~/.local/share/sl1c3d-labs/notes && " +
                            "printf '%s' \"$NOTE_CONTENT\" > ~/.local/share/sl1c3d-labs/notes/" +
                            panelWindow.calSelectedDate + ".txt"]
                        notesSaveProc.running = true
                        refreshDays()
                    }
                    function refreshDays() {
                        notesDaysProc.command = ["sh", "-c",
                            "ls ~/.local/share/sl1c3d-labs/notes/ 2>/dev/null | sed 's/\\.txt$//' | sort"]
                        notesDaysProc.running = true
                    }
                    function refreshRecent() {
                        recentNotesProc.command = ["sh", "-c",
                            "ls -t ~/.local/share/sl1c3d-labs/notes/*.txt 2>/dev/null | head -5 | while read f; do " +
                            "echo \"$(basename \"$f\" .txt)\"; head -2 \"$f\"; echo '---SEP---'; done"]
                        recentNotesProc.running = true
                    }

                    Connections {
                        target: panelWindow
                        function onCalendarOpenChanged() {
                            if (panelWindow.calendarOpen) {
                                var d = new Date()
                                calCard.viewYear  = d.getFullYear()
                                calCard.viewMonth = d.getMonth()
                                panelWindow.calSelectedDate = calCard.dateKey(d.getFullYear(), d.getMonth(), d.getDate())
                                panelWindow.calTab = "cal"
                                calCard.refreshDays()
                            }
                        }
                    }

                    Column {
                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                        spacing: 0

                        // ── Tab header ──────────────────────────────────────────
                        Item {
                            width: parent.width; height: 40

                            Row {
                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                Repeater {
                                    model: [{ id: "cal", label: "Calendar" }, { id: "notes", label: "Notes" }]
                                    delegate: MouseArea {
                                        required property var modelData
                                        id: calTabBtn
                                        width: calTabTxt.width + 18; height: 26
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (panelWindow.calTab === "notes" && modelData.id === "notes") return
                                            if (modelData.id === "notes") {
                                                calCard.loadNote(panelWindow.calSelectedDate)
                                                calCard.refreshRecent()
                                            }
                                            panelWindow.calTab = modelData.id
                                        }
                                        Rectangle {
                                            anchors.fill: parent; radius: root.theme.radiusPill
                                            color: panelWindow.calTab === calTabBtn.modelData.id ? root.theme.accentDim2 : "transparent"
                                            border.width: 1
                                            border.color: panelWindow.calTab === calTabBtn.modelData.id ? root.theme.logoPurple : "transparent"
                                            Behavior on color       { ColorAnimation { duration: root.theme.motionFastMs } }
                                            Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        }
                                        Text {
                                            id: calTabTxt
                                            anchors.centerIn: parent
                                            text: calTabBtn.modelData.label
                                            color: panelWindow.calTab === calTabBtn.modelData.id ? root.theme.logoPurple : root.theme.textMuted
                                            font.pixelSize: 11; font.weight: Font.Medium; font.family: root.theme.fontFamily
                                            Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: calCloseBtn
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                width: 24; height: 24
                                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: panelWindow.calendarOpen = false
                                Rectangle {
                                    anchors.fill: parent; radius: 6
                                    color: calCloseBtn.containsMouse ? root.theme.border : "transparent"
                                    Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                }
                                Text { anchors.centerIn: parent; text: "×"; color: root.theme.textMuted; font.pixelSize: 16; font.family: root.theme.fontFamily }
                            }
                        }

                        Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.5 }
                        Item { height: 12 }

                        // ── CALENDAR TAB ──────────────────────────────────────
                        Column {
                            width: parent.width
                            spacing: 0
                            visible: panelWindow.calTab === "cal"

                            // Month navigation
                            Row {
                                width: parent.width; height: 32; spacing: 0

                                MouseArea {
                                    id: calPrevBtn; width: 32; height: 32
                                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                    onClicked: { calCard.viewMonth--; if (calCard.viewMonth < 0) { calCard.viewMonth = 11; calCard.viewYear-- } }
                                    Rectangle { anchors.fill: parent; radius: 6; color: parent.containsMouse ? root.theme.accentDim2 : "transparent"; Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        Text { anchors.centerIn: parent; text: "‹"; color: root.theme.logoPurple; font.pixelSize: 16; font.family: root.theme.fontFamily }
                                    }
                                }

                                Text {
                                    width: parent.width - 32 - 32 - 58
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: calCard.monthNames[calCard.viewMonth] + " " + calCard.viewYear
                                    color: root.theme.textPrimary; font.pixelSize: 12; font.weight: Font.DemiBold
                                    font.family: root.theme.fontFamily; horizontalAlignment: Text.AlignHCenter
                                }

                                MouseArea {
                                    id: todayBtn; width: 46; height: 22; anchors.verticalCenter: parent.verticalCenter
                                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                    onClicked: {
                                        var d = new Date()
                                        calCard.viewYear = d.getFullYear(); calCard.viewMonth = d.getMonth()
                                        panelWindow.calSelectedDate = calCard.dateKey(d.getFullYear(), d.getMonth(), d.getDate())
                                    }
                                    Rectangle { anchors.fill: parent; radius: root.theme.radiusPill; color: todayBtn.containsMouse ? root.theme.accentDim2 : root.theme.bgBase; border.width: 1; border.color: root.theme.border; Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        Text { anchors.centerIn: parent; text: "Today"; color: root.theme.accentPrimary; font.pixelSize: 9; font.family: root.theme.fontFamily }
                                    }
                                }

                                MouseArea {
                                    id: calNextBtn; width: 32; height: 32
                                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                    onClicked: { calCard.viewMonth++; if (calCard.viewMonth > 11) { calCard.viewMonth = 0; calCard.viewYear++ } }
                                    Rectangle { anchors.fill: parent; radius: 6; color: parent.containsMouse ? root.theme.accentDim2 : "transparent"; Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        Text { anchors.centerIn: parent; text: "›"; color: root.theme.logoPurple; font.pixelSize: 16; font.family: root.theme.fontFamily }
                                    }
                                }
                            }

                            Item { height: 10 }

                            // Day-of-week headers (W# col + Mon-Sun)
                            Row {
                                spacing: 2
                                Text { width: 22; text: "#"; color: root.theme.border; font.pixelSize: 8; font.family: root.theme.fontFamily; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; height: 16 }
                                Repeater {
                                    model: ["M","T","W","T","F","S","S"]
                                    Text {
                                        required property string modelData
                                        required property int index
                                        width: 34; height: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                        text: modelData
                                        color: index >= 5 ? root.theme.accentRed : root.theme.accentPrimary
                                        font.pixelSize: 9; font.weight: Font.DemiBold; font.family: root.theme.fontFamily
                                    }
                                }
                            }

                            Item { height: 4 }

                            // 6-row calendar grid
                            Column {
                                id: calGridCol
                                width: parent.width; spacing: 2

                                property int gYear:     calCard.viewYear
                                property int gMonth:    calCard.viewMonth
                                property int firstDay:  { var d = new Date(gYear, gMonth, 1); return (d.getDay() + 6) % 7 }
                                property int daysInMon: new Date(gYear, gMonth + 1, 0).getDate()

                                Repeater {
                                    model: 6
                                    delegate: Row {
                                        required property int index
                                        id: weekRowItem
                                        spacing: 2
                                        property int rowStart: index * 7

                                        // Week number cell
                                        Text {
                                            width: 22; height: 30; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                                            text: {
                                                for (var c = 0; c < 7; c++) {
                                                    var i = weekRowItem.rowStart + c
                                                    if (i >= calGridCol.firstDay && i < calGridCol.firstDay + calGridCol.daysInMon) {
                                                        return calCard.isoWeek(calGridCol.gYear, calGridCol.gMonth, i - calGridCol.firstDay + 1)
                                                    }
                                                }
                                                return ""
                                            }
                                            color: root.theme.border; font.pixelSize: 8; font.family: root.theme.fontFamily
                                        }

                                        // 7 day cells
                                        Repeater {
                                            model: 7
                                            delegate: Item {
                                                required property int index
                                                id: dayCell
                                                width: 34; height: 30

                                                property int  ci:       weekRowItem.rowStart + index
                                                property bool blank:    ci < calGridCol.firstDay || ci >= calGridCol.firstDay + calGridCol.daysInMon
                                                property int  dayNum:   blank ? 0 : (ci - calGridCol.firstDay + 1)
                                                property bool isToday: {
                                                    if (blank) return false
                                                    var t = new Date()
                                                    return dayNum === t.getDate() && calGridCol.gMonth === t.getMonth() && calGridCol.gYear === t.getFullYear()
                                                }
                                                property string dKey:   blank ? "" : calCard.dateKey(calGridCol.gYear, calGridCol.gMonth, dayNum)
                                                property bool isSelected: !blank && dKey === panelWindow.calSelectedDate
                                                property bool isWeekend: index >= 5
                                                property bool hasNote:  !blank && calCard.noteDays.indexOf(dKey) >= 0

                                                Rectangle {
                                                    anchors.fill: parent; radius: 7
                                                    color: {
                                                        if (dayCell.blank)       return "transparent"
                                                        if (dayCell.isSelected)  return root.theme.accentDim2
                                                        if (dayCellMa.containsMouse) return root.theme.border
                                                        return "transparent"
                                                    }
                                                    border.width: (dayCell.isToday || dayCell.isSelected) && !dayCell.blank ? 1 : 0
                                                    border.color: dayCell.isSelected ? root.theme.accentPrimary : root.theme.logoPurple
                                                    Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }

                                                    Column {
                                                        anchors.centerIn: parent; spacing: 2
                                                        Text {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            text: dayCell.blank ? "" : dayCell.dayNum
                                                            color: {
                                                                if (dayCell.blank)      return "transparent"
                                                                if (dayCell.isSelected) return root.theme.accentPrimary
                                                                if (dayCell.isToday)    return root.theme.logoPurple
                                                                if (dayCell.isWeekend)  return root.theme.textMuted
                                                                return root.theme.textSecondary
                                                            }
                                                            font.pixelSize: 11; font.family: root.theme.fontFamily
                                                            font.weight: (dayCell.isToday || dayCell.isSelected) ? Font.DemiBold : Font.Normal
                                                            Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                                        }
                                                        Rectangle {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            width: 4; height: 4; radius: 2
                                                            color: dayCell.isSelected ? root.theme.accentPrimary : root.theme.logoPurple
                                                            visible: dayCell.hasNote
                                                        }
                                                    }
                                                }

                                                MouseArea {
                                                    id: dayCellMa; anchors.fill: parent; hoverEnabled: true
                                                    cursorShape: dayCell.blank ? Qt.ArrowCursor : Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (dayCell.blank) return
                                                        panelWindow.calSelectedDate = dayCell.dKey
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { height: 12 }
                            Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.4 }
                            Item { height: 10 }

                            // Selected date strip
                            Rectangle {
                                width: parent.width; height: 38; radius: root.theme.radiusPill
                                color: root.theme.bgBase; border.width: 1; border.color: root.theme.border
                                Row {
                                    anchors.centerIn: parent; spacing: 14
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: root.barTimeString + ":" + root.barSecondsString; color: root.theme.logoPurple; font.pixelSize: 16; font.weight: Font.Bold; font.family: root.theme.fontFamily }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: panelWindow.calSelectedDate || root.barDateString; color: root.theme.textPrimary; font.pixelSize: 11; font.family: root.theme.fontFamily }
                                }
                            }
                            Item { height: 8 }

                            // Open notes for selected day
                            MouseArea {
                                id: openNoteBtn; width: parent.width; height: 30
                                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: {
                                    calCard.loadNote(panelWindow.calSelectedDate)
                                    calCard.refreshRecent()
                                    panelWindow.calTab = "notes"
                                }
                                Rectangle {
                                    anchors.fill: parent; radius: root.theme.radiusPill
                                    color: openNoteBtn.containsMouse ? root.theme.accentDim2 : root.theme.bgBase
                                    border.width: 1; border.color: root.theme.border
                                    Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                    Row {
                                        anchors.centerIn: parent; spacing: 6
                                        Text { anchors.verticalCenter: parent.verticalCenter; text: "✏"; color: root.theme.logoPurple; font.pixelSize: 11; font.family: root.theme.fontFamily }
                                        Text { anchors.verticalCenter: parent.verticalCenter; text: "Notes for " + (panelWindow.calSelectedDate || "today"); color: root.theme.textSecondary; font.pixelSize: 11; font.family: root.theme.fontFamily }
                                    }
                                }
                            }
                            Item { height: 10 }
                        }

                        // ── NOTES TAB ──────────────────────────────────────────
                        Column {
                            width: parent.width; spacing: 0
                            visible: panelWindow.calTab === "notes"

                            // Date + save toolbar
                            Item {
                                width: parent.width; height: 30
                                Row {
                                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "✏"; color: root.theme.logoPurple; font.pixelSize: 12; font.family: root.theme.fontFamily }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: panelWindow.calSelectedDate || "Today"; color: root.theme.textMuted; font.pixelSize: 11; font.family: root.theme.fontFamily }
                                }
                                MouseArea {
                                    id: saveNoteBtn
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    width: 48; height: 24
                                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                    onClicked: calCard.saveNote()
                                    Rectangle {
                                        anchors.fill: parent; radius: root.theme.radiusPill
                                        color: saveNoteBtn.containsMouse ? root.theme.accentPrimary : root.theme.accentDim2
                                        Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        Text { anchors.centerIn: parent; text: "Save"; color: root.theme.textPrimary; font.pixelSize: 10; font.weight: Font.Medium; font.family: root.theme.fontFamily }
                                    }
                                }
                            }

                            Item { height: 8 }

                            // Note editor
                            Rectangle {
                                width: parent.width; height: 162; radius: root.theme.radiusPill
                                color: root.theme.bgBase; clip: true
                                border.width: 1
                                border.color: notesEditor.activeFocus ? root.theme.accentPrimary : root.theme.border
                                Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }

                                Flickable {
                                    anchors.fill: parent; anchors.margins: 10
                                    contentHeight: notesEditor.contentHeight; clip: true

                                    TextEdit {
                                        id: notesEditor
                                        width: parent.width
                                        text: panelWindow.notesContent
                                        color: root.theme.textPrimary
                                        font.pixelSize: 12; font.family: root.theme.fontFamily
                                        wrapMode: TextEdit.Wrap
                                        selectByMouse: true
                                        selectedTextColor: root.theme.bgBase
                                        selectionColor: root.theme.accentPrimary
                                    }
                                }
                            }

                            Item { height: 6 }

                            // Toolbar
                            Row {
                                spacing: 6
                                Repeater {
                                    model: [
                                        { label: "B",  action: "bold" },
                                        { label: "I",  action: "italic" },
                                        { label: "–",  action: "hr" },
                                        { label: "⌫", action: "clear" },
                                        { label: "⎘", action: "copy" }
                                    ]
                                    delegate: MouseArea {
                                        required property var modelData
                                        id: toolBtn; width: 28; height: 24
                                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                        onClicked: {
                                            if      (modelData.action === "bold")   notesEditor.insert(notesEditor.cursorPosition, "**text**")
                                            else if (modelData.action === "italic") notesEditor.insert(notesEditor.cursorPosition, "_text_")
                                            else if (modelData.action === "hr")     notesEditor.insert(notesEditor.cursorPosition, "\n---\n")
                                            else if (modelData.action === "clear")  notesEditor.text = ""
                                            else if (modelData.action === "copy")   { notesEditor.selectAll(); notesEditor.copy() }
                                        }
                                        Rectangle {
                                            anchors.fill: parent; radius: 6
                                            color: toolBtn.containsMouse ? root.theme.accentDim2 : root.theme.bgBase
                                            border.width: 1; border.color: root.theme.border
                                            Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                            Text { anchors.centerIn: parent; text: toolBtn.modelData.label; color: root.theme.textSecondary; font.pixelSize: 11; font.family: root.theme.fontFamily }
                                        }
                                    }
                                }
                            }

                            Item { height: 14 }
                            Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.4 }
                            Item { height: 10 }

                            Text { text: "RECENT NOTES"; color: root.theme.textMuted; font.pixelSize: 9; font.letterSpacing: 0.8; font.family: root.theme.fontFamily }
                            Item { height: 8 }

                            Repeater {
                                model: calCard.recentNotes.length > 0
                                    ? calCard.recentNotes
                                    : [{ date: "—", preview: "No notes yet. Click a day and start writing." }]
                                delegate: MouseArea {
                                    required property var modelData
                                    id: recentRow
                                    width: parent.width; height: 44
                                    cursorShape: modelData.date !== "—" ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        if (modelData.date === "—") return
                                        panelWindow.calSelectedDate = modelData.date
                                        calCard.loadNote(modelData.date)
                                    }
                                    Rectangle { anchors.fill: parent; anchors.margins: 1; radius: root.theme.radiusPill; color: recentRow.containsMouse && recentRow.modelData.date !== "—" ? root.theme.accentDim2 : "transparent"; Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } } }
                                    Column {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 8
                                        spacing: 2
                                        Text { text: recentRow.modelData.date; color: root.theme.logoPurple; font.pixelSize: 10; font.weight: Font.DemiBold; font.family: root.theme.fontFamily }
                                        Text { text: recentRow.modelData.preview || "Empty note"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.theme.fontFamily; elide: Text.ElideRight; width: parent.width - 16 }
                                    }
                                }
                            }
                            Item { height: 10 }
                        }
                    }
                }
            }
        }
    }
}
}
