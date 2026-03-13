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
        id: rootPwTracker
        objects: [Pipewire.defaultAudioSink]
    }

    // Volume OSD — reacts globally to Pipewire volume changes
    property real lastKnownVolume: -1.0
    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onVolumeChanged() {
            const v = Pipewire.defaultAudioSink?.audio?.volume ?? 0
            if (root.lastKnownVolume < 0) { root.lastKnownVolume = v; return }
            root.lastKnownVolume = v
            // Broadcast to all panelWindows via the Variants model
        }
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

    // Power menu identity pollers
    Process {
        id: pwrUserProc
        command: ["sh", "-c", "echo \"$(whoami)|$(hostname -s)\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("|")
                if (panelWindow) {
                    panelWindow.pwrUsername = p[0] || "user"
                    panelWindow.pwrHostname = p[1] || "arch"
                }
            }
        }
    }
    Process {
        id: pwrTempProc
        command: ["sh", "-c", "sensors 2>/dev/null | grep -m1 'Core 0' | awk '{print $3}' | tr -d '+°C' || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (panelWindow) panelWindow.pwrCpuTemp = t ? t + "°" : ""
            }
        }
    }
    Timer { interval: 10000; repeat: true; running: true; onTriggered: pwrTempProc.running = true }

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
            property string pwrUsername: ""
            property string pwrHostname: ""
            property string pwrUptime: ""
            property string pwrCpuTemp: ""
            property int    pwrConfirm: -1  // index of action awaiting confirm (-1 = none)
            property bool networkPopupOpen: false
            property bool volumeOsdVisible: false
            property real volumeOsdLevel: 0.0
            property int  lastHubSection: 0
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
                        id: logoPillMa
                        width: 36
                        height: 24
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: panelWindow.hubOpen = true

                        scale: logoPillMa.containsMouse ? (logoPillMa.pressed ? 0.90 : 1.08) : 1.0
                        Behavior on scale { SpringAnimation { spring: 3.0; damping: 0.6 } }

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
                            scale: timePillMa.containsMouse ? (timePillMa.pressed ? 0.93 : 1.04) : 1.0
                            Behavior on scale { SpringAnimation { spring: 2.8; damping: 0.65 } }
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
                                id: timePillMa
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
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
                            scale: datePillMa.containsMouse ? (datePillMa.pressed ? 0.93 : 1.04) : 1.0
                            Behavior on scale { SpringAnimation { spring: 2.8; damping: 0.65 } }
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
                                id: datePillMa
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
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
                        scale: nowPlayingMa.containsMouse ? (nowPlayingMa.pressed ? 0.93 : 1.04) : 1.0
                        Behavior on scale { SpringAnimation { spring: 2.8; damping: 0.65 } }

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
                            id: nowPlayingMa
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
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
                            id: netPill
                            height: 24
                            width: netContent.width + 12
                            radius: 8
                            color: root.theme.bgBase
                            border.width: 1
                            border.color: panelWindow.networkPopupOpen ? root.theme.accentPrimary : "transparent"
                            Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                            scale: netPillMa.containsMouse ? (netPillMa.pressed ? 0.93 : 1.04) : 1.0
                            Behavior on scale { SpringAnimation { spring: 2.8; damping: 0.65 } }
                            Accessible.role: Accessible.Button
                            Accessible.name: "Network: " + SystemInfo.networkInfo + ". Click for details."

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
                                    color: SystemInfo.networkInfo === "Disconnected" ? root.theme.accentRed : root.theme.accentGreen
                                    Behavior on color { ColorAnimation { duration: root.theme.motionBaseMs } }
                                    font.pixelSize: 11
                                    font.family: root.theme.fontFamily
                                }
                            }
                            MouseArea {
                                id: netPillMa
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: panelWindow.networkPopupOpen = !panelWindow.networkPopupOpen
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
                        scale: btopMouseArea.containsMouse ? (btopMouseArea.pressed ? 0.93 : 1.04) : 1.0
                        Behavior on scale { SpringAnimation { spring: 2.8; damping: 0.65 } }

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
                        height: 28; width: 36; radius: 10
                        color: panelWindow.powerMenuOpen ? Qt.rgba(0.9,0.2,0.2,0.15) : "transparent"
                        border.width: 1
                        border.color: panelWindow.powerMenuOpen ? root.theme.accentRed : root.theme.border
                        Behavior on color        { ColorAnimation { duration: root.theme.motionFastMs } }
                        Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                        scale: pwrPillHover.containsMouse ? (pwrPillHover.pressed ? 0.92 : 1.06) : 1.0
                        Behavior on scale { SpringAnimation { spring: 3.0; damping: 0.7 } }
                        Accessible.role: Accessible.Button
                        Accessible.name: "Power menu"

                        Image {
                            anchors.centerIn: parent
                            source: root.phosphorDir + "/power.svg"
                            width: 14; height: 14
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            opacity: panelWindow.powerMenuOpen ? 1.0 : (pwrPillHover.containsMouse ? 0.9 : 0.6)
                            Behavior on opacity { NumberAnimation { duration: root.theme.motionFastMs } }
                        }

                        MouseArea {
                            id: pwrPillHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                panelWindow.pwrConfirm = -1
                                panelWindow.powerMenuOpen = !panelWindow.powerMenuOpen
                            }
                        }
                    }
                }
            }

            // ─── Power menu dropdown popup (masterclass) ──────────────────────
            PopupWindow {
                id: powerMenuPopup
                anchor.window: panelWindow
                implicitWidth: 264
                implicitHeight: pwrOuterCol.implicitHeight + 24
                visible: panelWindow.powerMenuOpen
                color: "transparent"

                onVisibleChanged: if (!visible) { panelWindow.powerMenuOpen = false; panelWindow.pwrConfirm = -1 }

                anchor.onAnchoring: {
                    if (!anchor.window) return
                    const win = anchor.window
                    const pr = win.contentItem.mapFromItem(
                        powerPill, 0, powerPill.height, powerPill.width, powerPill.height)
                    const x = pr.x + powerPill.width - implicitWidth
                    anchor.rect = Qt.rect(x, pr.y + 8, implicitWidth, implicitHeight)
                }

                GlassSurface {
                    id: powerCard
                    theme: root.theme
                    strong: true
                    anchors.fill: parent
                    radius: root.theme.radiusModal
                    clip: true

                    scale:   panelWindow.powerMenuOpen ? 1.0 : 0.93
                    opacity: panelWindow.powerMenuOpen ? 1.0 : 0.0
                    Behavior on scale   { NumberAnimation { duration: root.theme.motionBaseMs; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: root.theme.motionBaseMs } }

                    Keys.onEscapePressed: panelWindow.powerMenuOpen = false
                    focus: panelWindow.powerMenuOpen
                    MouseArea { anchors.fill: parent; onClicked: {} }

                    Column {
                        id: pwrOuterCol
                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
                        spacing: 0

                        // ── User identity card ────────────────────────────────
                        Item {
                            width: parent.width; height: 60
                            Row {
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                spacing: 12

                                // Avatar circle with initial
                                Rectangle {
                                    width: 38; height: 38; radius: 19
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: root.theme.logoPurple }
                                        GradientStop { position: 1.0; color: root.theme.accentPrimary }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: (panelWindow.pwrUsername || "U").slice(0,1).toUpperCase()
                                        color: "white"
                                        font.pixelSize: 16; font.weight: Font.Bold
                                        font.family: root.theme.fontFamily
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Text {
                                        text: panelWindow.pwrUsername || "user"
                                        color: root.theme.textPrimary
                                        font.pixelSize: 13; font.weight: Font.DemiBold
                                        font.family: root.theme.fontFamily
                                    }
                                    Text {
                                        text: (panelWindow.pwrHostname || "arch") + " · up " + root.uptimeString
                                        color: root.theme.textMuted
                                        font.pixelSize: 9; font.family: root.theme.fontFamily
                                    }
                                }
                            }

                            // Close button top-right
                            MouseArea {
                                id: pwrClose
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                width: 24; height: 24
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
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

                        // ── Divider ───────────────────────────────────────────
                        Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.5 }
                        Item { width: 1; height: 6 }

                        // ── SESSION group label ───────────────────────────────
                        Text {
                            text: "SESSION"
                            color: root.theme.textMuted
                            font.pixelSize: 8; font.letterSpacing: 1.2
                            font.family: root.theme.fontFamily
                            leftPadding: 4
                        }
                        Item { width: 1; height: 4 }

                        // ── Session actions (Lock, Suspend, Logout) ───────────
                        Repeater {
                            model: [
                                { label: "Lock",    sub: "Lock screen",  icon: "lock-simple",        accent: root.theme.textSecondary, hint: "Super+L",  dangerous: false, cmd: ["loginctl", "lock-session"] },
                                { label: "Suspend", sub: "Sleep mode",   icon: "moon",               accent: root.theme.accentPrimary,  hint: "",         dangerous: false, cmd: ["systemctl", "suspend"] },
                                { label: "Logout",  sub: "End session",  icon: "sign-out",           accent: root.theme.accentPrimary,  hint: "",         dangerous: false, cmd: ["sh", "-c", "hyprctl dispatch exit"] }
                            ]
                            delegate: Item {
                                required property var modelData
                                required property int index
                                id: sessionRow
                                width: pwrOuterCol.width; height: 46
                                property bool hov: sessionMa.containsMouse
                                MouseArea {
                                    id: sessionMa; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        panelWindow.powerMenuOpen = false
                                        hubLauncher.command = sessionRow.modelData.cmd
                                        hubLauncher.running = true
                                    }
                                }
                                Rectangle {
                                    anchors { fill: parent; margins: 1 }
                                    radius: root.theme.radiusPill
                                    color: sessionRow.hov ? root.theme.accentDim2 : "transparent"
                                    Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                }
                                Row {
                                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 8; rightMargin: 8 }
                                    spacing: 10

                                    Rectangle {
                                        width: 28; height: 28; radius: 8; anchors.verticalCenter: parent.verticalCenter
                                        color: sessionRow.hov ? Qt.rgba(0.34,0.40,0.95,0.15) : Qt.rgba(1,1,1,0.04)
                                        Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        Image {
                                            anchors.centerIn: parent; width: 14; height: 14
                                            source: root.phosphorDir + "/" + sessionRow.modelData.icon + ".svg"
                                            fillMode: Image.PreserveAspectFit; smooth: true
                                        }
                                    }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter; spacing: 1
                                        Text { text: sessionRow.modelData.label; color: root.theme.textPrimary; font.pixelSize: 12; font.weight: Font.Medium; font.family: root.theme.fontFamily }
                                        Text { text: sessionRow.modelData.sub;   color: root.theme.textMuted;  font.pixelSize: 9;  font.family: root.theme.fontFamily }
                                    }
                                    Item { Layout.fillWidth: true; height: 1; width: pwrOuterCol.width - 28 - 10 - 120 }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: sessionRow.modelData.hint
                                        color: root.theme.border; font.pixelSize: 9; font.family: root.theme.fontFamily
                                        visible: sessionRow.modelData.hint !== ""
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "›"
                                        color: sessionRow.hov ? sessionRow.modelData.accent : root.theme.border
                                        font.pixelSize: 15; font.family: root.theme.fontFamily
                                        Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                    }
                                }
                            }
                        }

                        Item { width: 1; height: 8 }

                        // ── Danger zone divider ───────────────────────────────
                        Item {
                            width: parent.width; height: 18
                            Rectangle { anchors { left: parent.left; right: dangerLabel.left; verticalCenter: parent.verticalCenter; rightMargin: 6 }; height: 1; color: root.theme.accentRed; opacity: 0.25 }
                            Text { id: dangerLabel; anchors { right: parent.right; verticalCenter: parent.verticalCenter }; text: "SYSTEM"; color: root.theme.accentRed; opacity: 0.6; font.pixelSize: 8; font.letterSpacing: 1.2; font.family: root.theme.fontFamily }
                        }
                        Item { width: 1; height: 4 }

                        // ── Destructive actions (Reboot, Shutdown) w/ confirm ─
                        Repeater {
                            model: [
                                { label: "Reboot",   sub: "Restart system", icon: "arrows-clockwise", accent: root.theme.accentOrange, cmd: ["systemctl", "reboot"],  confirmIdx: 3 },
                                { label: "Shutdown", sub: "Power off",       icon: "power",            accent: root.theme.accentRed,    cmd: ["systemctl", "poweroff"], confirmIdx: 4 }
                            ]
                            delegate: Item {
                                required property var modelData
                                required property int index
                                id: dangerRow
                                width: pwrOuterCol.width; height: 50
                                property bool hov: dangerMa.containsMouse
                                property bool confirming: panelWindow.pwrConfirm === modelData.confirmIdx

                                MouseArea {
                                    id: dangerMa; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (dangerRow.confirming) {
                                            panelWindow.pwrConfirm = -1
                                            panelWindow.powerMenuOpen = false
                                            hubLauncher.command = dangerRow.modelData.cmd
                                            hubLauncher.running = true
                                        } else {
                                            panelWindow.pwrConfirm = dangerRow.modelData.confirmIdx
                                            pwrConfirmTimer.restart()
                                        }
                                    }
                                }
                                Timer {
                                    id: pwrConfirmTimer
                                    interval: 3000; repeat: false
                                    onTriggered: if (panelWindow.pwrConfirm === dangerRow.modelData.confirmIdx) panelWindow.pwrConfirm = -1
                                }

                                // Confirm pulsing border
                                Rectangle {
                                    anchors { fill: parent; margins: 1 }
                                    radius: root.theme.radiusPill
                                    color: dangerRow.confirming
                                        ? Qt.rgba(dangerRow.modelData.accent === root.theme.accentRed ? 0.9 : 0.8,
                                                  dangerRow.modelData.accent === root.theme.accentRed ? 0.1 : 0.35, 0.1, 0.18)
                                        : (dangerRow.hov ? root.theme.accentDim2 : "transparent")
                                    border.width: dangerRow.confirming ? 1 : 0
                                    border.color: dangerRow.modelData.accent
                                    Behavior on color        { ColorAnimation { duration: root.theme.motionFastMs } }
                                    Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }

                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite; running: dangerRow.confirming
                                        NumberAnimation { to: 0.5; duration: 600 }
                                        NumberAnimation { to: 1.0; duration: 600 }
                                    }
                                }

                                Row {
                                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 8; rightMargin: 8 }
                                    spacing: 10

                                    Rectangle {
                                        width: 28; height: 28; radius: 8; anchors.verticalCenter: parent.verticalCenter
                                        color: dangerRow.confirming
                                            ? Qt.rgba(dangerRow.modelData.accent === root.theme.accentRed ? 0.9 : 0.8,
                                                      dangerRow.modelData.accent === root.theme.accentRed ? 0.1 : 0.35, 0.1, 0.25)
                                            : (dangerRow.hov ? Qt.rgba(0.9,0.2,0.1,0.15) : Qt.rgba(1,1,1,0.04))
                                        Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        Image {
                                            anchors.centerIn: parent; width: 14; height: 14
                                            source: root.phosphorDir + "/" + dangerRow.modelData.icon + ".svg"
                                            fillMode: Image.PreserveAspectFit; smooth: true
                                        }
                                    }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                        Text {
                                            text: dangerRow.confirming ? "Confirm " + dangerRow.modelData.label + "?" : dangerRow.modelData.label
                                            color: dangerRow.confirming ? dangerRow.modelData.accent : root.theme.textPrimary
                                            font.pixelSize: 12; font.weight: Font.Medium; font.family: root.theme.fontFamily
                                            Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        }
                                        Text {
                                            text: dangerRow.confirming ? "Click again to confirm · auto-cancel 3s" : dangerRow.modelData.sub
                                            color: dangerRow.confirming ? Qt.rgba(1,0.5,0.3,0.8) : root.theme.textMuted
                                            font.pixelSize: 9; font.family: root.theme.fontFamily
                                            Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        }
                                    }
                                    Item { height: 1; width: pwrOuterCol.width - 28 - 10 - 130 }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: dangerRow.confirming ? "⚠" : "›"
                                        color: dangerRow.hov || dangerRow.confirming ? dangerRow.modelData.accent : root.theme.border
                                        font.pixelSize: dangerRow.confirming ? 13 : 15; font.family: root.theme.fontFamily
                                        Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                    }
                                }
                            }
                        }

                        Item { width: 1; height: 8 }

                        // ── Status strip ─────────────────────────────────────
                        Rectangle {
                            width: parent.width; height: 28; radius: 8
                            color: Qt.rgba(1,1,1,0.03); border.width: 1; border.color: root.theme.border
                            Row {
                                anchors.centerIn: parent; spacing: 16
                                Text {
                                    text: root.uptimeString !== "—" ? "⏱  " + root.uptimeString : ""
                                    color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily
                                    visible: root.uptimeString !== "—"
                                }
                                Text {
                                    text: SystemInfo.memoryUsage !== "0%" ? "  " + SystemInfo.memoryUsage : ""
                                    color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily
                                    visible: SystemInfo.memoryUsage !== "0%"
                                }
                                Text {
                                    text: SystemInfo.batteryLevelRaw > 0 ? "🔋 " + SystemInfo.batteryLevelRaw + "%" : ""
                                    color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily
                                    visible: SystemInfo.batteryLevelRaw > 0
                                }
                                Text {
                                    text: panelWindow.pwrCpuTemp !== "" ? "🌡  " + panelWindow.pwrCpuTemp : ""
                                    color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily
                                    visible: panelWindow.pwrCpuTemp !== ""
                                }
                            }
                        }

                        Item { width: 1; height: 4 }
                    }
                }
            }

            PopupWindow {
                id: hubPopup
                // Anchor below the left logo pill using native item-relative positioning
                anchor.item: leftSection
                anchor.edges: Edges.Bottom | Edges.Left
                anchor.gravity: Edges.Bottom | Edges.Right
                anchor.adjustment: PopupAdjustment.Flip
                anchor.margins.top: 8
                implicitWidth: 500
                implicitHeight: 620
                visible: panelWindow.hubOpen
                color: "transparent"

                onVisibleChanged: if (!visible) panelWindow.hubOpen = false

                GlassSurface {
                    id: hubCard
                    theme: root.theme
                    strong: false
                    anchors.fill: parent
                    radius: root.theme.radiusModal
                    clip: true

                    scale: panelWindow.hubOpen ? 1 : 0.95
                    opacity: panelWindow.hubOpen ? 1 : 0
                    Behavior on scale   { NumberAnimation { duration: root.theme.motionBaseMs; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: root.theme.motionBaseMs } }

                    Process { id: hubLauncher; running: false }

                    property string home: root.homeDir
                    // 0 Overview · 1 Media · 2 Developer · 3 Wallpapers · 4 Control · 5 System
                    property int hubSection: panelWindow.lastHubSection
                    onHubSectionChanged: {
                        panelWindow.lastHubSection = hubSection
                        if (hubSection === 2) refreshDevTab()
                    }

                    property string selectedWallpaper: ""

                    // ── MPRIS live data (Mpris is the singleton, not MprisController) ─
                    property var mprisPlayer: Mpris.players.length > 0 ? Mpris.players[0] : null
                    PwObjectTracker { id: pwTracker; objects: [Pipewire.defaultAudioSink] }
                    property real audioVolume: Pipewire.defaultAudioSink?.audio?.volume ?? 1.0

                    // Position ticker (drives progress bar while playing)
                    Timer {
                        id: mprisTicker
                        interval: 1000; repeat: true
                        running: hubCard.mprisPlayer !== null && (hubCard.mprisPlayer?.isPlaying ?? false) && panelWindow.hubOpen
                        onTriggered: if (hubCard.mprisPlayer) hubCard.mprisPlayer.positionChanged()
                    }

                    // ── Developer tab live data ───────────────────────────
                    property string chezmoiStatus: "—"
                    property string cmBranch: "main"
                    property string cmLastCommit: "—"
                    property int    cmChangedCount: 0
                    property var    runtimePills: []

                    Process {
                        id: chezmoiStatusProc
                        running: false
                        stdout: StdioCollector {
                            onStreamFinished: {
                                const lines = text.trim().split("\n").filter(l => l.length > 0)
                                hubCard.cmChangedCount = lines.length
                                hubCard.chezmoiStatus = lines.length > 0 ? lines.length + " modified" : "clean"
                            }
                        }
                    }
                    Process {
                        id: cmBranchProc
                        command: ["sh", "-c", "git -C $(chezmoi source-path 2>/dev/null) branch --show-current 2>/dev/null || echo 'main'"]
                        running: false
                        stdout: StdioCollector {
                            onStreamFinished: hubCard.cmBranch = text.trim() || "main"
                        }
                    }
                    Process {
                        id: cmLastCommitProc
                        command: ["sh", "-c", "git -C $(chezmoi source-path 2>/dev/null) log -1 --format='%h · %cr · %s' 2>/dev/null || echo '—'"]
                        running: false
                        stdout: StdioCollector {
                            onStreamFinished: hubCard.cmLastCommit = text.trim() || "—"
                        }
                    }
                    Process {
                        id: runtimesProc
                        command: ["sh", "-c", [
                            "V=$(git --version 2>/dev/null | grep -oP '[\\d.]+' | head -1) && echo 'git:'$V",
                            "V=$(nvim --version 2>/dev/null | head -1 | grep -oP '[\\d.]+' | head -1) && echo 'nvim:'$V",
                            "V=$(python3 --version 2>/dev/null | awk '{print $2}') && echo 'python:'$V",
                            "V=$(node --version 2>/dev/null | tr -d v) && echo 'node:'$V",
                            "V=$(rustc --version 2>/dev/null | awk '{print $2}') && echo 'rust:'$V",
                            "V=$(go version 2>/dev/null | awk '{print $3}' | tr -d go) && echo 'go:'$V",
                            "true"
                        ].join("; ")]
                        running: false
                        stdout: StdioCollector {
                            onStreamFinished: {
                                const colorMap = {
                                    git:    { bg: "#0d1a0d", border: "#3d6b3d", color: "#73c991", icon: "" },
                                    nvim:   { bg: "#091a2a", border: "#1a6b4a", color: "#57c7a5", icon: "" },
                                    python: { bg: "#0a1020", border: "#254f7f", color: "#5fa8d3", icon: "" },
                                    node:   { bg: "#0a1a0a", border: "#2d5a2d", color: "#68a063", icon: "" },
                                    rust:   { bg: "#1a0a08", border: "#6b2820", color: "#ce4c2b", icon: "" },
                                    go:     { bg: "#081520", border: "#00576f", color: "#00acd7", icon: "" }
                                }
                                const pills = []
                                text.trim().split("\n").forEach(function(line) {
                                    const parts = line.split(":")
                                    if (parts.length < 2 || !parts[1].trim()) return
                                    const name = parts[0].trim()
                                    const ver  = parts[1].trim()
                                    const c = colorMap[name] || { bg: "#1a1a1a", border: "#444", color: "#f8f8f2", icon: "▸" }
                                    pills.push({ name: name, ver: ver, bg: c.bg, border: c.border, color: c.color, icon: c.icon })
                                })
                                hubCard.runtimePills = pills
                            }
                        }
                    }

                    // Trigger dev-tab data refresh whenever section 2 becomes active
                    function refreshDevTab() {
                        chezmoiStatusProc.command = ["sh", "-c", "chezmoi status 2>/dev/null"]
                        chezmoiStatusProc.running = true
                        cmBranchProc.running      = true
                        cmLastCommitProc.running  = true
                        runtimesProc.running      = true
                    }
                    Connections {
                        target: panelWindow
                        function onHubOpenChanged() {
                            if (panelWindow.hubOpen && hubCard.hubSection === 2) hubCard.refreshDevTab()
                        }
                    }

                    MouseArea { anchors.fill: parent; onClicked: { } }

                    Item {
                        anchors.fill: parent
                        focus: panelWindow.hubOpen
                        Keys.onEscapePressed: panelWindow.hubOpen = false

                        Column {
                            anchors.fill: parent
                            anchors.margins: root.theme.spacingLg
                            spacing: 0

                            // ─── Header ──────────────────────────────────────
                            Row {
                                width: parent.width
                                height: 44
                                spacing: 10
                                Image {
                                    source: "file://" + hubCard.home + "/assets/icons/Logo-bar.svg"
                                    width: 22; height: 22
                                    anchors.verticalCenter: parent.verticalCenter
                                    fillMode: Image.PreserveAspectFit; smooth: true; mipmap: true
                                }
                                Text {
                                    text: "SL1C3D HUB"
                                    color: root.theme.logoPurple
                                    font.pixelSize: 14; font.family: root.theme.fontFamily; font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Item { Layout.fillWidth: true; width: parent.width - 22 - 90 - 28 - 20; height: 1 }
                                MouseArea {
                                    id: closeBtn; width: 28; height: 28
                                    anchors.verticalCenter: parent.verticalCenter
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: panelWindow.hubOpen = false
                                    Rectangle {
                                        anchors.fill: parent; radius: 6
                                        color: closeBtn.containsMouse ? root.theme.border : "transparent"
                                        Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                    }
                                    Text { anchors.centerIn: parent; text: "×"; color: root.theme.textMuted; font.pixelSize: 18; font.family: root.theme.fontFamily }
                                }
                            }

                            Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.5 }
                            Item { height: 12 }

                            // ─── Two-column: Nav rail | Content ──────────────
                            Row {
                                width: parent.width
                                height: parent.height - 44 - 1 - 12 - 12
                                spacing: 14

                                // ── Nav rail ─────────────────────────────────
                                Column {
                                    width: 112; height: parent.height; spacing: 3

                                    Repeater {
                                        model: [
                                            { id: 0, label: "Overview",   icon: "house",               accent: root.theme.accentPrimary },
                                            { id: 1, label: "Media",      icon: "music-notes",         accent: root.theme.logoPurple },
                                            { id: 2, label: "Developer",  icon: "terminal-window",     accent: root.theme.accentPrimary },
                                            { id: 3, label: "Wallpapers", icon: "images-square",       accent: root.theme.accentOrange },
                                            { id: 4, label: "Control",    icon: "sliders-horizontal",  accent: root.theme.logoPurple },
                                            { id: 5, label: "System",     icon: "desktop-tower",       accent: root.theme.accentGreen }
                                        ]
                                        delegate: MouseArea {
                                            required property var modelData
                                            width: 112; height: 36
                                            cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                            onClicked: hubCard.hubSection = modelData.id
                                            Rectangle {
                                                anchors.fill: parent; anchors.margins: 2
                                                radius: root.theme.radiusPill
                                                color: hubCard.hubSection === modelData.id ? root.theme.accentDim2 : (parent.containsMouse ? root.theme.border : "transparent")
                                                opacity: hubCard.hubSection === modelData.id ? 1 : (parent.containsMouse ? 0.4 : 0)
                                                Behavior on opacity { NumberAnimation { duration: root.theme.motionFastMs } }
                                            }
                                            // Active accent left-bar
                                            Rectangle {
                                                width: 3; height: 20
                                                anchors.left: parent.left; anchors.leftMargin: 3
                                                anchors.verticalCenter: parent.verticalCenter
                                                radius: 2
                                                color: modelData.accent
                                                opacity: hubCard.hubSection === modelData.id ? 1 : 0
                                                Behavior on opacity { NumberAnimation { duration: root.theme.motionFastMs } }
                                            }
                                            Row {
                                                anchors { left: parent.left; right: parent.right; leftMargin: 14; rightMargin: 8 }
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 7
                                                Image {
                                                    width: 14; height: 14
                                                    source: root.phosphorDir + "/" + modelData.icon + ".svg"
                                                    fillMode: Image.PreserveAspectFit
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                                Text {
                                                    text: modelData.label
                                                    color: hubCard.hubSection === modelData.id ? modelData.accent : root.theme.textSecondary
                                                    font.pixelSize: 10; font.family: root.theme.fontFamily
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    elide: Text.ElideRight
                                                    width: 112 - 14 - 14 - 7 - 8
                                                    Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                                }
                                            }
                                        }
                                    }

                                    Item { height: 8 }
                                    Rectangle { width: parent.width - 8; height: 1; anchors.horizontalCenter: parent.horizontalCenter; color: root.theme.border; opacity: 0.4 }
                                    Item { height: 6 }
                                    // Edition tag at bottom of nav
                                    Text {
                                        text: root.editionName
                                        color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                // ── Content area (cross-fade panels) ─────────
                                Item {
                                    id: hubContentArea
                                    width: parent.width - 112 - 14
                                    height: parent.height
                                    clip: true

                                    // ─── 0 · OVERVIEW ────────────────────────
                                    Flickable {
                                        anchors.fill: parent; contentHeight: ovCol.implicitHeight; clip: true
                                        opacity: hubCard.hubSection === 0 ? 1 : 0
                                        visible: opacity > 0
                                        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                        Column {
                                            id: ovCol; width: parent.width; spacing: 14

                                            // System health rings
                                            Text { text: "SYSTEM HEALTH"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily; font.letterSpacing: 1.0 }
                                            Row {
                                                spacing: 12
                                                Repeater {
                                                    model: [
                                                        { label: "CPU",  color: root.theme.accentPrimary },
                                                        { label: "RAM",  color: root.theme.logoPurple    },
                                                        { label: "Disk", color: root.theme.accentOrange  }
                                                    ]
                                                    delegate: Item {
                                                        required property var modelData
                                                        required property int index
                                                        width: 72; height: 72
                                                        property real liveVal: index === 0 ? SystemInfo.cpuUsageNum
                                                                             : index === 1 ? SystemInfo.ramUsageNum
                                                                             : SystemInfo.diskUsageNum
                                                        Canvas {
                                                            id: statRing; anchors.fill: parent
                                                            property real val: parent.liveVal / 100.0
                                                            onValChanged: requestPaint()
                                                            onPaint: {
                                                                var ctx = getContext("2d")
                                                                ctx.clearRect(0, 0, width, height)
                                                                var cx = width/2, cy = height/2, r = 28
                                                                ctx.lineWidth = 5
                                                                ctx.strokeStyle = root.theme.border
                                                                ctx.beginPath(); ctx.arc(cx,cy,r,0,2*Math.PI); ctx.stroke()
                                                                var col = val > 0.8 ? root.theme.accentRed : val > 0.5 ? root.theme.accentOrange : modelData.color
                                                                ctx.strokeStyle = col
                                                                ctx.beginPath(); ctx.arc(cx,cy,r,-Math.PI/2,-Math.PI/2+2*Math.PI*val,false); ctx.stroke()
                                                            }
                                                        }
                                                        Column {
                                                            anchors.centerIn: parent; spacing: 0
                                                            Text {
                                                                anchors.horizontalCenter: parent.horizontalCenter
                                                                text: Math.round(parent.parent.liveVal) + "%"
                                                                color: root.theme.textPrimary; font.pixelSize: 12; font.family: root.theme.fontFamily; font.weight: Font.DemiBold
                                                            }
                                                            Text {
                                                                anchors.horizontalCenter: parent.horizontalCenter
                                                                text: modelData.label
                                                                color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // CPU / RAM sparkline history chart
                                            Item {
                                                width: parent.width; height: 52
                                                Canvas {
                                                    id: sparklineChart
                                                    anchors.fill: parent
                                                    property var cpuHist: SystemInfo.cpuHistory
                                                    property var ramHist: SystemInfo.ramHistory
                                                    onCpuHistChanged: requestPaint()
                                                    onRamHistChanged: requestPaint()
                                                    onPaint: {
                                                        var ctx = getContext("2d")
                                                        ctx.clearRect(0, 0, width, height)
                                                        // Background glass
                                                        ctx.fillStyle = "#0affffff"
                                                        roundedRect(ctx, 0, 0, width, height, 8)
                                                        ctx.fill()
                                                        // Grid lines at 25/50/75%
                                                        ctx.strokeStyle = "#14ffffff"
                                                        ctx.lineWidth = 1
                                                        ;[0.25, 0.5, 0.75].forEach(function(p) {
                                                            var y = height - p * height
                                                            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
                                                        })
                                                        function drawSparkline(hist, hexColor, alphaFill) {
                                                            if (!hist || hist.length < 2) return
                                                            var pts = []
                                                            for (var i = 0; i < hist.length; i++) {
                                                                pts.push({ x: (i / (hist.length - 1)) * (width - 4) + 2, y: height - 2 - (hist[i] / 100) * (height - 8) })
                                                            }
                                                            // Fill area
                                                            ctx.beginPath()
                                                            ctx.moveTo(pts[0].x, height)
                                                            for (var j = 0; j < pts.length; j++) ctx.lineTo(pts[j].x, pts[j].y)
                                                            ctx.lineTo(pts[pts.length-1].x, height)
                                                            ctx.closePath()
                                                            ctx.fillStyle = hexColor + alphaFill
                                                            ctx.fill()
                                                            // Line
                                                            ctx.beginPath()
                                                            ctx.moveTo(pts[0].x, pts[0].y)
                                                            for (var k = 1; k < pts.length; k++) ctx.lineTo(pts[k].x, pts[k].y)
                                                            ctx.strokeStyle = hexColor + "cc"
                                                            ctx.lineWidth = 1.8
                                                            ctx.stroke()
                                                            // Dot at latest value
                                                            var last = pts[pts.length-1]
                                                            ctx.beginPath(); ctx.arc(last.x, last.y, 3, 0, 2*Math.PI)
                                                            ctx.fillStyle = hexColor + "ff"; ctx.fill()
                                                        }
                                                        function roundedRect(c, x, y, w, h, r) {
                                                            c.beginPath(); c.moveTo(x+r,y); c.lineTo(x+w-r,y)
                                                            c.arcTo(x+w,y,x+w,y+r,r); c.lineTo(x+w,y+h-r)
                                                            c.arcTo(x+w,y+h,x+w-r,y+h,r); c.lineTo(x+r,y+h)
                                                            c.arcTo(x,y+h,x,y+h-r,r); c.lineTo(x,y+r)
                                                            c.arcTo(x,y,x+r,y,r); c.closePath()
                                                        }
                                                        drawSparkline(cpuHist, "#5865F2", "22")
                                                        drawSparkline(ramHist, "#b366ff", "22")
                                                    }
                                                }
                                                // Legend
                                                Row {
                                                    anchors { right: parent.right; bottom: parent.bottom; margins: 6 }
                                                    spacing: 8
                                                    Repeater {
                                                        model: [{ label: "CPU", color: root.theme.accentPrimary }, { label: "RAM", color: root.theme.logoPurple }]
                                                        delegate: Row {
                                                            required property var modelData
                                                            spacing: 3
                                                            Rectangle { width: 10; height: 2; radius: 1; color: modelData.color; anchors.verticalCenter: parent.verticalCenter }
                                                            Text { text: modelData.label; color: root.theme.textMuted; font.pixelSize: 8; font.family: root.theme.fontFamily }
                                                        }
                                                    }
                                                }
                                            }

                                            // Mini MPRIS player
                                            Rectangle {
                                                width: parent.width; height: hubCard.mprisPlayer ? 56 : 0
                                                visible: height > 0
                                                radius: root.theme.radiusPill; color: root.theme.bgBase
                                                border.width: 1; border.color: root.theme.border
                                                Row {
                                                    anchors { fill: parent; margins: 10 }
                                                    spacing: 10
                                                    Rectangle {
                                                        width: 36; height: 36; radius: 6
                                                        color: root.theme.bgBase; clip: true
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        Image {
                                                            anchors.fill: parent
                                                            source: hubCard.mprisPlayer?.trackArtUrl ?? ""
                                                            fillMode: Image.PreserveAspectCrop
                                                        }
                                                    }
                                                    Column {
                                                        width: parent.width - 36 - 10 - 80; anchors.verticalCenter: parent.verticalCenter; spacing: 1
                                                        Text { text: hubCard.mprisPlayer?.trackTitle || "—"; color: root.theme.textPrimary; font.pixelSize: 11; font.family: root.theme.fontFamily; font.weight: Font.Medium; elide: Text.ElideRight; width: parent.width }
                                                        Text { text: hubCard.mprisPlayer?.trackArtist || ""; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.theme.fontFamily; elide: Text.ElideRight; width: parent.width }
                                                    }
                                                    Row {
                                                        spacing: 4; anchors.verticalCenter: parent.verticalCenter
                                                        Repeater {
                                                            model: ["⏮", hubCard.mprisPlayer?.isPlaying ? "⏸" : "▶", "⏭"]
                                                            delegate: MouseArea {
                                                                required property string modelData
                                                                required property int index
                                                                width: 26; height: 26; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                                onClicked: {
                                                                    var p = hubCard.mprisPlayer
                                                                    if (!p) return
                                                                    if      (index === 0 && p.canGoPrevious) p.previous()
                                                                    else if (index === 1 && p.canTogglePlaying) p.togglePlaying()
                                                                    else if (index === 2 && p.canGoNext)     p.next()
                                                                }
                                                                Rectangle { anchors.fill: parent; radius: 6; color: parent.containsMouse ? root.theme.accentDim2 : "transparent"; Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } } }
                                                                Text { anchors.centerIn: parent; text: parent.modelData; color: root.theme.textPrimary; font.pixelSize: 12 }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // Quick-action grid (2×3)
                                            Text { text: "QUICK LAUNCH"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily; font.letterSpacing: 1.0 }
                                            Flow {
                                                width: parent.width; spacing: 8
                                                Repeater {
                                                    model: [
                                                        { label: "Terminal",  icon: "terminal-window", cmd: ["ghostty"] },
                                                        { label: "Files",     icon: "folder-open",     cmd: ["ghostty", "-e", "yazi"] },
                                                        { label: "Editor",    icon: "file-code",       cmd: ["ghostty", "-e", "nvim"] },
                                                        { label: "Monitor",   icon: "gauge",           cmd: ["ghostty", "-e", "btop"] },
                                                        { label: "Music",     icon: "music-notes",     cmd: ["bash", "-c", hubCard.home + "/.config/hypr/scripts/spotifyd-toggle.sh"] },
                                                        { label: "AI",        icon: "robot",           cmd: [hubCard.home + "/.config/hypr/scripts/openclaw-sidebar.sh"] }
                                                    ]
                                                    delegate: MouseArea {
                                                        required property var modelData
                                                        width: 80; height: 64
                                                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                        onClicked: { hubLauncher.command = modelData.cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                        Rectangle {
                                                            anchors.fill: parent; radius: 10
                                                            color: parent.containsMouse ? root.theme.accentDim2 : root.theme.bgBase
                                                            border.width: 1; border.color: parent.containsMouse ? root.theme.accentPrimary : root.theme.border
                                                            Behavior on color       { ColorAnimation { duration: root.theme.motionFastMs } }
                                                            Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                                                            Column {
                                                                anchors.centerIn: parent; spacing: 4
                                                                Image { width: 22; height: 22; source: root.phosphorDir + "/" + parent.parent.parent.modelData.icon + ".svg"; fillMode: Image.PreserveAspectFit; anchors.horizontalCenter: parent.horizontalCenter }
                                                                Text { text: parent.parent.parent.modelData.label; color: root.theme.textSecondary; font.pixelSize: 9; font.family: root.theme.fontFamily; anchors.horizontalCenter: parent.horizontalCenter }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // Uptime strip
                                            Text { text: "uptime  " + root.uptimeString; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.theme.fontFamily }
                                        }
                                    }

                                    // ─── 1 · MEDIA ───────────────────────────
                                    Flickable {
                                        anchors.fill: parent; contentHeight: mediaCol.implicitHeight; clip: true
                                        opacity: hubCard.hubSection === 1 ? 1 : 0
                                        visible: opacity > 0
                                        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                        Column {
                                            id: mediaCol; width: parent.width; spacing: 14

                                            // ── spotifyd daemon status + controls ─────────
                                            property bool spotifydRunning: false
                                            Process {
                                                id: spotifydStatusProc
                                                command: ["sh", "-c", "systemctl --user is-active spotifyd 2>/dev/null"]
                                                running: true
                                                stdout: StdioCollector {
                                                    onStreamFinished: mediaCol.spotifydRunning = text.trim() === "active"
                                                }
                                            }
                                            Timer {
                                                interval: 4000; repeat: true; running: hubCard.hubSection === 1
                                                onTriggered: spotifydStatusProc.running = true
                                            }

                                            // Header: MEDIA PLAYER + live daemon pill
                                            Item {
                                                width: parent.width; height: 22
                                                Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "MEDIA PLAYER"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily; font.letterSpacing: 1.0 }
                                                // Live daemon status pill
                                                Rectangle {
                                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                                    height: 18; width: daemonPillRow.width + 12; radius: 9
                                                    color: mediaCol.spotifydRunning ? "#0d2210" : root.theme.bgBase
                                                    border.width: 1
                                                    border.color: mediaCol.spotifydRunning ? root.theme.accentGreen : root.theme.border
                                                    Behavior on color        { ColorAnimation { duration: 400 } }
                                                    Behavior on border.color { ColorAnimation { duration: 400 } }
                                                    Row {
                                                        id: daemonPillRow
                                                        anchors.centerIn: parent; spacing: 5
                                                        Rectangle {
                                                            width: 6; height: 6; radius: 3
                                                            color: mediaCol.spotifydRunning ? root.theme.accentGreen : root.theme.textMuted
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            Behavior on color { ColorAnimation { duration: 400 } }
                                                            SequentialAnimation on opacity {
                                                                loops: Animation.Infinite; running: mediaCol.spotifydRunning
                                                                NumberAnimation { to: 0.3; duration: 900 }
                                                                NumberAnimation { to: 1.0; duration: 900 }
                                                            }
                                                        }
                                                        Text {
                                                            text: mediaCol.spotifydRunning ? "spotifyd active" : "daemon stopped"
                                                            color: mediaCol.spotifydRunning ? root.theme.accentGreen : root.theme.textMuted
                                                            font.pixelSize: 9; font.family: root.theme.fontFamily
                                                            Behavior on color { ColorAnimation { duration: 400 } }
                                                        }
                                                    }
                                                }
                                            }

                                            // Daemon control card (always visible, above MPRIS panel)
                                            Rectangle {
                                                width: parent.width; height: 52; radius: 10
                                                color: root.theme.bgBase; border.width: 1
                                                border.color: mediaCol.spotifydRunning ? Qt.rgba(0.19,0.49,0.27,0.4) : Qt.rgba(1,1,1,0.07)
                                                Behavior on border.color { ColorAnimation { duration: 400 } }

                                                Item {
                                                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }

                                                    // Left: icon + description
                                                    Row {
                                                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                                                        Image { source: root.phosphorDir + "/music-notes.svg"; width: 18; height: 18; fillMode: Image.PreserveAspectFit; smooth: true; anchors.verticalCenter: parent.verticalCenter; opacity: mediaCol.spotifydRunning ? 1.0 : 0.4 }
                                                        Column {
                                                            anchors.verticalCenter: parent.verticalCenter; spacing: 1
                                                            Text { text: "spotifyd"; color: root.theme.textPrimary; font.pixelSize: 11; font.weight: Font.DemiBold; font.family: root.theme.fontFamily }
                                                            Text { text: mediaCol.spotifydRunning ? "Headless — open Spotify on any device to play" : "Start daemon to stream headlessly"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily }
                                                        }
                                                    }

                                                    // Right: Start / Stop toggle button
                                                    MouseArea {
                                                        id: daemonToggleBtn
                                                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                                        width: daemonToggleTxt.width + 20; height: 28
                                                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                        scale: containsMouse ? (pressed ? 0.91 : 1.06) : 1.0
                                                        Behavior on scale { SpringAnimation { spring: 2.8; damping: 0.65 } }
                                                        onClicked: {
                                                            var action = mediaCol.spotifydRunning ? "stop" : "start"
                                                            hubLauncher.command = ["bash", "-c", root.homeDir + "/.config/hypr/scripts/spotifyd-toggle.sh " + action]
                                                            hubLauncher.running = true
                                                            // Optimistic UI update
                                                            mediaCol.spotifydRunning = !mediaCol.spotifydRunning
                                                        }
                                                        Rectangle {
                                                            anchors.fill: parent; radius: root.theme.radiusPill
                                                            color: daemonToggleBtn.containsMouse
                                                                ? (mediaCol.spotifydRunning ? "#2a0a0a" : "#0a2210")
                                                                : Qt.rgba(0.05,0.05,0.1,1)
                                                            border.width: 1
                                                            border.color: mediaCol.spotifydRunning
                                                                ? (daemonToggleBtn.containsMouse ? root.theme.accentRed : Qt.rgba(0.8,0.2,0.2,0.5))
                                                                : (daemonToggleBtn.containsMouse ? root.theme.accentGreen : Qt.rgba(0.2,0.8,0.3,0.4))
                                                            Behavior on color        { ColorAnimation { duration: root.theme.motionFastMs } }
                                                            Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                                                        }
                                                        Text {
                                                            id: daemonToggleTxt
                                                            anchors.centerIn: parent
                                                            text: mediaCol.spotifydRunning ? "Stop" : "Start"
                                                            color: mediaCol.spotifydRunning
                                                                ? (daemonToggleBtn.containsMouse ? root.theme.accentRed : root.theme.textSecondary)
                                                                : (daemonToggleBtn.containsMouse ? root.theme.accentGreen : root.theme.textSecondary)
                                                            font.pixelSize: 10; font.family: root.theme.fontFamily
                                                            Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                                        }
                                                    }
                                                }
                                            }

                                            // No MPRIS signal yet
                                            Rectangle {
                                                visible: !hubCard.mprisPlayer && mediaCol.spotifydRunning
                                                width: parent.width; height: 44; radius: 10
                                                color: root.theme.bgBase; border.width: 1; border.color: Qt.rgba(1,1,1,0.06)
                                                Row {
                                                    anchors { fill: parent; leftMargin: 12 }
                                                    spacing: 10
                                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "ℹ"; font.pixelSize: 14; color: root.theme.accentPrimary }
                                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Open Spotify on your phone or desktop,\nselect \"SL1C3D-L4BS\" as the device."; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily }
                                                }
                                            }
                                            Rectangle {
                                                visible: !hubCard.mprisPlayer && !mediaCol.spotifydRunning
                                                width: parent.width; height: 36; radius: 10
                                                color: root.theme.bgBase; border.width: 1; border.color: Qt.rgba(1,1,1,0.06)
                                                Text { anchors.centerIn: parent; text: "Start spotifyd, then play from the Spotify app"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily }
                                            }

                                            // Full MPRIS panel
                                            Column {
                                                visible: hubCard.mprisPlayer !== null
                                                width: parent.width; spacing: 12

                                                // Album art + track info
                                                Row {
                                                    spacing: 14; width: parent.width
                                                    Rectangle {
                                                        width: 80; height: 80; radius: 10
                                                        color: root.theme.bgBase; border.width: 1; border.color: root.theme.border
                                                        Image {
                                                            anchors.fill: parent; anchors.margins: 2
                                                            source: hubCard.mprisPlayer?.trackArtUrl ?? ""
                                                            fillMode: Image.PreserveAspectCrop
                                                            smooth: true; mipmap: true
                                                        }
                                                    }
                                                    Column {
                                                        width: parent.width - 80 - 14
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        spacing: 4
                                                        Text { text: hubCard.mprisPlayer?.identity ?? "Player"; color: root.theme.logoPurple; font.pixelSize: 9; font.family: root.theme.fontFamily }
                                                        Text { text: hubCard.mprisPlayer?.trackTitle || "No track"; color: root.theme.textPrimary; font.pixelSize: 13; font.family: root.theme.fontFamily; font.weight: Font.DemiBold; elide: Text.ElideRight; width: parent.width }
                                                        Text { text: hubCard.mprisPlayer?.trackArtist || ""; color: root.theme.textSecondary; font.pixelSize: 11; font.family: root.theme.fontFamily; elide: Text.ElideRight; width: parent.width }
                                                        Text { text: hubCard.mprisPlayer?.trackAlbum || ""; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.theme.fontFamily; elide: Text.ElideRight; width: parent.width }
                                                    }
                                                }

                                                // Progress bar
                                                Item {
                                                    width: parent.width; height: 24
                                                    property real progress: {
                                                        var p = hubCard.mprisPlayer
                                                        if (!p || !p.lengthSupported || p.length <= 0) return 0
                                                        return Math.min(1, p.position / p.length)
                                                    }
                                                    Rectangle {
                                                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                                        height: 4; radius: 2; color: root.theme.border
                                                        Rectangle {
                                                            width: parent.width * parent.parent.progress
                                                            height: parent.height; radius: 2; color: root.theme.logoPurple
                                                            Behavior on width { NumberAnimation { duration: 800 } }
                                                        }
                                                    }
                                                    Row {
                                                        anchors { bottom: parent.top; bottomMargin: 2; left: parent.left; right: parent.right }
                                                        Text {
                                                            property real s: hubCard.mprisPlayer?.position ?? 0
                                                            text: Math.floor(s/60) + ":" + String(Math.floor(s%60)).padStart(2,"0")
                                                            color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily
                                                        }
                                                        Item { width: parent.width - 60; height: 1 }
                                                        Text {
                                                            property real s: hubCard.mprisPlayer?.length ?? 0
                                                            text: Math.floor(s/60) + ":" + String(Math.floor(s%60)).padStart(2,"0")
                                                            color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily
                                                        }
                                                    }
                                                }

                                                // Controls: prev / play-pause / next + shuffle + loop
                                                Row {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    spacing: 8
                                                    Repeater {
                                                        model: ["⏮", hubCard.mprisPlayer?.isPlaying ? "⏸" : "▶", "⏭"]
                                                        delegate: MouseArea {
                                                            required property string modelData
                                                            required property int index
                                                            width: index === 1 ? 44 : 36; height: index === 1 ? 44 : 36
                                                            cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                            onClicked: {
                                                                var p = hubCard.mprisPlayer
                                                                if (!p) return
                                                                if      (index === 0 && p.canGoPrevious)    p.previous()
                                                                else if (index === 1 && p.canTogglePlaying) p.togglePlaying()
                                                                else if (index === 2 && p.canGoNext)        p.next()
                                                            }
                                                            Rectangle {
                                                                anchors.fill: parent; radius: index === 1 ? 22 : 10
                                                                color: index === 1 ? (parent.containsMouse ? root.theme.logoPurple : root.theme.accentDim2)
                                                                                  : (parent.containsMouse ? root.theme.accentDim2 : root.theme.bgBase)
                                                                border.width: 1
                                                                border.color: index === 1 ? root.theme.logoPurple : root.theme.border
                                                                Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                                            }
                                                            Text { anchors.centerIn: parent; text: parent.modelData; color: root.theme.textPrimary; font.pixelSize: index === 1 ? 16 : 13 }
                                                        }
                                                    }
                                                }

                                                // Volume slider (Pipewire)
                                                Text { text: "VOLUME"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily; font.letterSpacing: 1.0 }
                                                Row {
                                                    width: parent.width; spacing: 8
                                                    Text { text: "🔈"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                                    Item {
                                                        width: parent.width - 40 - 36; height: 20
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        Rectangle {
                                                            id: volTrack; anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                                            height: 4; radius: 2; color: root.theme.border
                                                            Rectangle {
                                                                width: parent.width * Math.min(1, hubCard.audioVolume)
                                                                height: parent.height; radius: 2; color: root.theme.accentPrimary
                                                            }
                                                        }
                                                        MouseArea {
                                                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                            onClicked: function(e) {
                                                                var newVol = Math.max(0, Math.min(1, e.x / width))
                                                                var sink = Pipewire.defaultAudioSink
                                                                if (sink && sink.audio) sink.audio.volume = newVol
                                                            }
                                                            onPositionChanged: function(e) {
                                                                if (pressed) {
                                                                    var newVol = Math.max(0, Math.min(1, e.x / width))
                                                                    var sink = Pipewire.defaultAudioSink
                                                                    if (sink && sink.audio) sink.audio.volume = newVol
                                                                }
                                                            }
                                                        }
                                                    }
                                                    Text {
                                                        text: Math.round(hubCard.audioVolume * 100) + "%"
                                                        color: root.theme.textMuted; font.pixelSize: 10; font.family: root.theme.fontFamily
                                                        width: 32; anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                    Text { text: "🔊"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                                }
                                            }
                                        }
                                    }

                                    // ─── 2 · DEVELOPER ───────────────────────
                                    Flickable {
                                        id: devFlickable
                                        anchors.fill: parent; contentHeight: devCol.implicitHeight; clip: true
                                        opacity: hubCard.hubSection === 2 ? 1 : 0
                                        visible: opacity > 0
                                        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                        Column {
                                            id: devCol; width: parent.width; spacing: 8

                                            // ── DOTFILES CARD ─────────────────────────────
                                            Rectangle {
                                                width: devCol.width
                                                height: dotfilesInner.implicitHeight + 24
                                                radius: 10
                                                color: root.theme.bgBase
                                                border.width: 1
                                                border.color: hubCard.cmChangedCount > 0 ? root.theme.accentOrange : root.theme.accentGreen
                                                Behavior on border.color { ColorAnimation { duration: 400 } }

                                                SequentialAnimation on opacity {
                                                    loops: Animation.Infinite
                                                    running: hubCard.cmChangedCount > 0
                                                    NumberAnimation { to: 0.65; duration: 1200; easing.type: Easing.InOutSine }
                                                    NumberAnimation { to: 1.0;  duration: 1200; easing.type: Easing.InOutSine }
                                                }

                                                Column {
                                                    id: dotfilesInner
                                                    anchors { fill: parent; margins: 12 }
                                                    spacing: 8

                                                    // Branch LEFT · status badge + refresh RIGHT
                                                    Item {
                                                        width: parent.width; height: 20
                                                        Row {
                                                            anchors.left: parent.left
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            spacing: 6
                                                            Image {
                                                                source: root.phosphorDir + "/git-branch.svg"
                                                                width: 13; height: 13
                                                                fillMode: Image.PreserveAspectFit; smooth: true
                                                                anchors.verticalCenter: parent.verticalCenter
                                                            }
                                                            Text {
                                                                text: hubCard.cmBranch
                                                                color: root.theme.accentPrimary
                                                                font.pixelSize: 11; font.weight: Font.DemiBold; font.family: root.theme.fontFamily
                                                                anchors.verticalCenter: parent.verticalCenter
                                                            }
                                                        }
                                                        Row {
                                                            anchors.right: parent.right
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            spacing: 6
                                                            Rectangle {
                                                                height: 18; width: dfStatusTxt.width + 12; radius: 9
                                                                color: hubCard.cmChangedCount > 0 ? "#2a1200" : "#0d2210"
                                                                border.width: 1
                                                                border.color: hubCard.cmChangedCount > 0 ? root.theme.accentOrange : root.theme.accentGreen
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                Text {
                                                                    id: dfStatusTxt; anchors.centerIn: parent
                                                                    text: hubCard.cmChangedCount > 0 ? ("⚡ " + hubCard.cmChangedCount + " pending") : "✓ clean"
                                                                    color: hubCard.cmChangedCount > 0 ? root.theme.accentOrange : root.theme.accentGreen
                                                                    font.pixelSize: 9; font.family: root.theme.fontFamily
                                                                }
                                                            }
                                                            MouseArea {
                                                                id: dfRefreshBtn; width: 20; height: 20
                                                                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                onClicked: hubCard.refreshDevTab()
                                                                scale: containsMouse ? (pressed ? 0.88 : 1.14) : 1.0
                                                                Behavior on scale { SpringAnimation { spring: 3.0; damping: 0.6 } }
                                                                Text {
                                                                    anchors.centerIn: parent; text: "↻"
                                                                    color: dfRefreshBtn.containsMouse ? root.theme.accentPrimary : root.theme.textMuted
                                                                    font.pixelSize: 14
                                                                    Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                                                }
                                                            }
                                                        }
                                                    }

                                                    // Last commit line
                                                    Text {
                                                        width: parent.width
                                                        text: hubCard.cmLastCommit
                                                        color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily
                                                        elide: Text.ElideRight
                                                    }

                                                    // Separator
                                                    Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.5 }

                                                    // Action pills — equal width, fill card
                                                    Row {
                                                        width: parent.width; spacing: 6
                                                        Repeater {
                                                            model: [
                                                                { label: "Apply",  accent: root.theme.accentPrimary, cmd: ["ghostty", "-e", "bash", "-lc", "chezmoi apply && echo '\\n✓ applied'; read"] },
                                                                { label: "Push",   accent: root.theme.accentGreen,   cmd: ["sh", "-c", "cd $(chezmoi source-path 2>/dev/null) && git add -A && git commit -m 'chore: sync' --allow-empty 2>/dev/null; git push 2>&1 | head -4 | notify-send -u low 'Dotfiles' 'Pushed'"] },
                                                                { label: "Status", accent: root.theme.accentOrange,  cmd: ["ghostty", "-e", "bash", "-lc", "chezmoi status; echo; read"] }
                                                            ]
                                                            delegate: MouseArea {
                                                                required property var modelData
                                                                required property int index
                                                                width: (dotfilesInner.width - 12) / 3; height: 28
                                                                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                                scale: containsMouse ? (pressed ? 0.92 : 1.04) : 1.0
                                                                Behavior on scale { SpringAnimation { spring: 2.8; damping: 0.65 } }
                                                                onClicked: { hubLauncher.command = modelData.cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                                Rectangle {
                                                                    anchors.fill: parent; radius: 8
                                                                    color: parent.containsMouse ? Qt.rgba(0.04,0.04,0.1,1) : "transparent"
                                                                    border.width: 1
                                                                    border.color: parent.containsMouse ? modelData.accent : Qt.rgba(1,1,1,0.10)
                                                                    Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                                                                    Behavior on color        { ColorAnimation { duration: root.theme.motionFastMs } }
                                                                }
                                                                Text {
                                                                    anchors.centerIn: parent; text: modelData.label
                                                                    color: parent.containsMouse ? modelData.accent : root.theme.textSecondary
                                                                    font.pixelSize: 10; font.family: root.theme.fontFamily
                                                                    Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // ── DEV TIMER CARD (conditional) ──────────────
                                            Rectangle {
                                                width: devCol.width; height: visible ? 46 : 0
                                                visible: root.devTimerSecsLeft > 0
                                                radius: 10; color: root.theme.bgBase
                                                border.width: 1; border.color: root.theme.accentPrimary
                                                clip: true
                                                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                                                Item {
                                                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }

                                                    // Left: icon + text
                                                    Row {
                                                        anchors.left: parent.left
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        spacing: 8
                                                        Text {
                                                            text: "⏱"; font.pixelSize: 14
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            SequentialAnimation on opacity {
                                                                loops: Animation.Infinite; running: root.devTimerSecsLeft > 0
                                                                NumberAnimation { to: 0.3; duration: 900 }
                                                                NumberAnimation { to: 1.0; duration: 900 }
                                                            }
                                                        }
                                                        Column {
                                                            anchors.verticalCenter: parent.verticalCenter; spacing: 1
                                                            Text {
                                                                text: root.devTimerLabel || "Dev Timer"
                                                                color: root.theme.textPrimary; font.pixelSize: 10; font.weight: Font.DemiBold; font.family: root.theme.fontFamily
                                                            }
                                                            Text {
                                                                text: {
                                                                    const s = root.devTimerSecsLeft
                                                                    if (s <= 0) return "—"
                                                                    const h = Math.floor(s / 3600)
                                                                    const m = Math.floor((s % 3600) / 60)
                                                                    const sec = s % 60
                                                                    return (h > 0 ? h + "h " : "") + String(m).padStart(2,"0") + "m " + String(sec).padStart(2,"0") + "s"
                                                                }
                                                                color: root.devTimerSecsLeft < 300 ? root.theme.accentRed : root.theme.accentPrimary
                                                                font.pixelSize: 10; font.family: root.theme.fontFamily
                                                                Behavior on color { ColorAnimation { duration: 500 } }
                                                            }
                                                        }
                                                    }

                                                    // Right: progress bar
                                                    Item {
                                                        width: 72; height: 5
                                                        anchors.right: parent.right
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        Rectangle { anchors.fill: parent; radius: 3; color: root.theme.border }
                                                        Rectangle {
                                                            height: parent.height; radius: 3
                                                            width: root.devTimerTotal > 0 ? parent.width * (root.devTimerSecsLeft / root.devTimerTotal) : 0
                                                            color: root.devTimerSecsLeft < 300 ? root.theme.accentRed : root.theme.accentPrimary
                                                            Behavior on width { NumberAnimation { duration: 1000 } }
                                                        }
                                                    }
                                                }
                                            }

                                            // ── ENVIRONMENT ───────────────────────────────
                                            Item { height: 4 }
                                            Item {
                                                width: parent.width; height: 16
                                                Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "ENVIRONMENT"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily; font.letterSpacing: 1.2 }
                                            }
                                            Flow {
                                                width: parent.width; spacing: 5
                                                Repeater {
                                                    model: hubCard.runtimePills
                                                    delegate: Rectangle {
                                                        required property var modelData
                                                        height: 22; radius: 11; width: rtTxt.width + 18
                                                        color: modelData.bg || root.theme.bgBase
                                                        border.width: 1; border.color: modelData.border || root.theme.border
                                                        Text {
                                                            id: rtTxt; anchors.centerIn: parent
                                                            text: (modelData.icon || "") + " " + modelData.name + " " + modelData.ver
                                                            color: modelData.color || root.theme.textPrimary
                                                            font.pixelSize: 9; font.family: root.theme.fontFamily
                                                        }
                                                    }
                                                }
                                                Text {
                                                    visible: hubCard.runtimePills.length === 0
                                                    text: "detecting runtimes…"
                                                    color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily
                                                }
                                            }

                                            // ── WORKSPACES ────────────────────────────────
                                            Item { height: 4 }
                                            Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.3 }
                                            Item { height: 2 }
                                            Item {
                                                width: parent.width; height: 16
                                                Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "WORKSPACES"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily; font.letterSpacing: 1.2 }
                                            }
                                            Repeater {
                                                model: [
                                                    { path: "~/dev",                  label: "dev",       sub: "~/dev",          icon: "folder-open",     git: true,  iconBg: "#0f1135", accent: "#5865F2" },
                                                    { path: "~/.config",              label: ".config",   sub: "~/.config",      icon: "gear",            git: false, iconBg: "#251a00", accent: "#ffb86c" },
                                                    { path: "~/.local/share/chezmoi", label: "dotfiles",  sub: "chezmoi source", icon: "git-branch",      git: true,  iconBg: "#0d2210", accent: "#50fa7b" },
                                                    { path: "~/scripts",              label: "scripts",   sub: "~/scripts",      icon: "terminal-window", git: false, iconBg: "#1a0820", accent: "#b366ff" },
                                                    { path: "~/assets",               label: "assets",    sub: "~/assets",       icon: "images-square",   git: false, iconBg: "#1a1015", accent: "#ff79c6" }
                                                ]
                                                delegate: Rectangle {
                                                    id: wsDelegate
                                                    required property var modelData
                                                    required property int index
                                                    width: devCol.width; height: 52; radius: 10
                                                    property string rp: wsDelegate.modelData.path.replace("~", hubCard.home)
                                                    color: wsMa.containsMouse ? Qt.rgba(0.04,0.04,0.09,1.0) : root.theme.bgBase
                                                    border.width: 1
                                                    border.color: wsMa.containsMouse ? wsDelegate.modelData.accent : Qt.rgba(1,1,1,0.07)
                                                    scale: wsMa.containsMouse ? 1.007 : 1.0
                                                    Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                                                    Behavior on color        { ColorAnimation { duration: root.theme.motionFastMs } }
                                                    Behavior on scale        { SpringAnimation { spring: 3.0; damping: 0.7 } }

                                                    opacity: 0; y: 6
                                                    NumberAnimation on opacity { from: 0; to: 1; duration: 200 + wsDelegate.index * 40; easing.type: Easing.OutCubic; running: devFlickable.visible }
                                                    NumberAnimation on y      { from: 6; to: 0; duration: 200 + wsDelegate.index * 40; easing.type: Easing.OutCubic; running: devFlickable.visible }

                                                    Item {
                                                        anchors { fill: parent; leftMargin: 12; rightMargin: 10 }

                                                        // Icon backdrop — left-anchored
                                                        Rectangle {
                                                            id: wsIcon
                                                            width: 32; height: 32; radius: 8
                                                            anchors.left: parent.left
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            color: wsDelegate.modelData.iconBg
                                                            border.width: 1; border.color: Qt.rgba(1,1,1,0.07)
                                                            Image {
                                                                anchors.centerIn: parent
                                                                source: root.phosphorDir + "/" + wsDelegate.modelData.icon + ".svg"
                                                                width: 15; height: 15; fillMode: Image.PreserveAspectFit; smooth: true
                                                            }
                                                        }

                                                        // Action buttons — right-anchored
                                                        Row {
                                                            id: wsActions
                                                            spacing: 4
                                                            anchors.right: parent.right
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            Repeater {
                                                                model: wsDelegate.modelData.git
                                                                    ? [ { i: "folder-open",     c: ["ghostty", "-e", "yazi", wsDelegate.rp] },
                                                                        { i: "terminal-window", c: ["ghostty", "-e", "bash", "-c", "cd " + wsDelegate.rp + " && exec ~/.config/hypr/scripts/zellij-branded.sh 2>/dev/null || exec zsh"] },
                                                                        { i: "git-branch",      c: ["ghostty", "-e", "bash", "-c", "cd " + wsDelegate.rp + " && lazygit"] } ]
                                                                    : [ { i: "folder-open",     c: ["ghostty", "-e", "yazi", wsDelegate.rp] },
                                                                        { i: "terminal-window", c: ["ghostty", "-e", "bash", "-c", "cd " + wsDelegate.rp + " && exec ~/.config/hypr/scripts/zellij-branded.sh 2>/dev/null || exec zsh"] } ]
                                                                delegate: MouseArea {
                                                                    required property var modelData
                                                                    width: 26; height: 26
                                                                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                                    scale: containsMouse ? (pressed ? 0.84 : 1.1) : 1.0
                                                                    Behavior on scale { SpringAnimation { spring: 3.2; damping: 0.6 } }
                                                                    onClicked: { hubLauncher.command = modelData.c; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                                    Rectangle {
                                                                        anchors.fill: parent; radius: 7
                                                                        color: parent.containsMouse ? root.theme.accentDim2 : "transparent"
                                                                        border.width: 1
                                                                        border.color: parent.containsMouse ? wsDelegate.modelData.accent : Qt.rgba(1,1,1,0.10)
                                                                        Behavior on color        { ColorAnimation { duration: root.theme.motionFastMs } }
                                                                        Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                                                                    }
                                                                    Image {
                                                                        anchors.centerIn: parent
                                                                        source: root.phosphorDir + "/" + modelData.i + ".svg"
                                                                        width: 13; height: 13; fillMode: Image.PreserveAspectFit; smooth: true
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        // Label + subpath — fills between icon and actions
                                                        Column {
                                                            anchors.left: wsIcon.right; anchors.leftMargin: 10
                                                            anchors.right: wsActions.left; anchors.rightMargin: 8
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            spacing: 2
                                                            Text { text: wsDelegate.modelData.label; color: root.theme.textPrimary; font.pixelSize: 11; font.weight: Font.DemiBold; font.family: root.theme.fontFamily; elide: Text.ElideRight; width: parent.width }
                                                            Text { text: wsDelegate.modelData.sub;   color: root.theme.textMuted;  font.pixelSize: 9;  font.family: root.theme.fontFamily;  elide: Text.ElideRight; width: parent.width }
                                                        }
                                                    }
                                                    MouseArea { id: wsMa; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                                                }
                                            }

                                            // ── CONFIG EDITORS ────────────────────────────
                                            Item { height: 4 }
                                            Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.3 }
                                            Item { height: 2 }
                                            Item {
                                                width: parent.width; height: 16
                                                Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "CONFIG EDITORS"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily; font.letterSpacing: 1.2 }
                                            }
                                            Repeater {
                                                model: [
                                                    { label: "Zsh",           sub: "~/.zshrc",              icon: "terminal-window", accent: "#b366ff", cmd: ["ghostty", "-e", "nvim", hubCard.home + "/.zshrc"] },
                                                    { label: "Hyprland",      sub: "~/.config/hypr/",       icon: "app-window",      accent: "#5865F2", cmd: ["ghostty", "-e", "nvim", hubCard.home + "/.config/hypr"] },
                                                    { label: "Quickshell",    sub: "bar/Bar.qml",           icon: "layout",          accent: "#5865F2", cmd: ["ghostty", "-e", "nvim", hubCard.home + "/.config/quickshell/bar/Bar.qml"] },
                                                    { label: "Zellij",        sub: "config.kdl",            icon: "grid-four",       accent: "#ffb86c", cmd: ["ghostty", "-e", "nvim", hubCard.home + "/.config/zellij/config.kdl"] },
                                                    { label: "Starship",      sub: "starship.toml",         icon: "sparkle",         accent: "#ff79c6", cmd: ["ghostty", "-e", "nvim", hubCard.home + "/.config/starship.toml"] },
                                                    { label: "Neovim",        sub: "~/.config/nvim/",       icon: "file-code",       accent: "#50fa7b", cmd: ["ghostty", "-e", "nvim", hubCard.home + "/.config/nvim"] },
                                                    { label: "Chezmoi apply", sub: "Sync & apply dotfiles", icon: "arrow-clockwise", accent: "#5865F2", cmd: ["ghostty", "-e", "bash", "-lc", "chezmoi apply && echo '\\n✓ Done'; read"] }
                                                ]
                                                delegate: MouseArea {
                                                    id: cfgDelegate
                                                    required property var modelData
                                                    required property int index
                                                    width: devCol.width; height: 42
                                                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                    scale: containsMouse ? (pressed ? 0.98 : 1.004) : 1.0
                                                    Behavior on scale { SpringAnimation { spring: 3.0; damping: 0.7 } }
                                                    onClicked: { hubLauncher.command = modelData.cmd; hubLauncher.running = true; panelWindow.hubOpen = false }

                                                    opacity: 0
                                                    NumberAnimation on opacity {
                                                        from: 0; to: 1; duration: 220 + cfgDelegate.index * 35
                                                        easing.type: Easing.OutCubic; running: devFlickable.visible
                                                    }

                                                    Rectangle {
                                                        anchors.fill: parent; radius: 9
                                                        color: cfgDelegate.containsMouse ? Qt.rgba(0.04,0.04,0.1,1) : "transparent"
                                                        border.width: 1
                                                        border.color: cfgDelegate.containsMouse ? cfgDelegate.modelData.accent : "transparent"
                                                        Behavior on color        { ColorAnimation { duration: root.theme.motionFastMs } }
                                                        Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }

                                                        Item {
                                                            anchors { fill: parent; leftMargin: 8; rightMargin: 10 }

                                                            // Icon — left
                                                            Rectangle {
                                                                id: cfgIcon
                                                                width: 26; height: 26; radius: 7
                                                                anchors.left: parent.left
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                color: Qt.rgba(0.07, 0.07, 0.14, 1)
                                                                border.width: 1
                                                                border.color: cfgDelegate.containsMouse ? cfgDelegate.modelData.accent : Qt.rgba(1,1,1,0.07)
                                                                Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                                                                Image {
                                                                    anchors.centerIn: parent
                                                                    source: root.phosphorDir + "/" + cfgDelegate.modelData.icon + ".svg"
                                                                    width: 12; height: 12; fillMode: Image.PreserveAspectFit; smooth: true
                                                                }
                                                            }

                                                            // Chevron — right
                                                            Text {
                                                                id: cfgChevron
                                                                anchors.right: parent.right
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: "›"; font.pixelSize: 16; font.family: root.theme.fontFamily
                                                                color: cfgDelegate.containsMouse ? cfgDelegate.modelData.accent : root.theme.textMuted
                                                                Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                                            }

                                                            // Label + sub — fills between icon and chevron
                                                            Column {
                                                                anchors.left: cfgIcon.right; anchors.leftMargin: 10
                                                                anchors.right: cfgChevron.left; anchors.rightMargin: 6
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                spacing: 1
                                                                Text {
                                                                    text: cfgDelegate.modelData.label
                                                                    color: cfgDelegate.containsMouse ? cfgDelegate.modelData.accent : root.theme.textPrimary
                                                                    font.pixelSize: 11; font.weight: Font.DemiBold; font.family: root.theme.fontFamily
                                                                    elide: Text.ElideRight; width: parent.width
                                                                    Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                                                }
                                                                Text {
                                                                    text: cfgDelegate.modelData.sub
                                                                    color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily
                                                                    elide: Text.ElideRight; width: parent.width
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            Item { height: 6 }
                                        }
                                    }

                                    // ─── 3 · WALLPAPERS ──────────────────────
                                    Flickable {
                                        anchors.fill: parent; contentHeight: wpCol.implicitHeight; clip: true
                                        opacity: hubCard.hubSection === 3 ? 1 : 0
                                        visible: opacity > 0
                                        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                        Column {
                                            id: wpCol; width: parent.width; spacing: 12

                                            Text { text: "WALLPAPERS"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily; font.letterSpacing: 1.0 }

                                            // Thumbnail grid — 3 columns
                                            Flow {
                                                width: parent.width; spacing: 6
                                                Repeater {
                                                    model: ["sl1c3d-l4bs-01.png","sl1c3d-l4bs-02.png","sl1c3d-l4bs-03.png",
                                                            "sl1c3d-l4bs-04.png","sl1c3d-l4bs-05.png","sl1c3d-l4bs-06.png",
                                                            "sl1c3d-l4bs-07.png","sl1c3d-l4bs-08.png","sl1c3d-l4bs-09.png",
                                                            "sl1c3d-l4bs-10.png","sl1c3d-l4bs-11.png","sl1c3d-l4bs-12.png",
                                                            "sl1c3d-l4bs-13.png","sl1c3d-l4bs-14.png","sl1c3d-l4bs-15.png"]
                                                    delegate: MouseArea {
                                                        required property string modelData
                                                        property bool isSelected: hubCard.selectedWallpaper === modelData
                                                        width: (wpCol.width - 12) / 3
                                                        height: width * 0.5625
                                                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                        onClicked: {
                                                            hubCard.selectedWallpaper = modelData
                                                            hubLauncher.command = ["waypaper", "--wallpaper", hubCard.home + "/assets/wallpapers/" + modelData, "--fill", "fill", "--monitor", "All", "--backend", "swaybg"]
                                                            hubLauncher.running = true
                                                        }
                                                        Rectangle {
                                                            anchors.fill: parent; radius: 8
                                                            color: root.theme.bgBase
                                                            border.width: isSelected ? 2 : (parent.containsMouse ? 1 : 0)
                                                            border.color: isSelected ? root.theme.accentPrimary : root.theme.accentDim
                                                            Behavior on border.width { NumberAnimation { duration: root.theme.motionFastMs } }
                                                            Image {
                                                                anchors { fill: parent; margins: isSelected ? 3 : 2 }
                                                                source: "file://" + hubCard.home + "/assets/wallpapers/" + modelData
                                                                fillMode: Image.PreserveAspectCrop
                                                                smooth: true; mipmap: true
                                                                layer.enabled: true
                                                                layer.effect: null
                                                            }
                                                            // Selected checkmark overlay
                                                            Rectangle {
                                                                visible: isSelected
                                                                width: 18; height: 18; radius: 9
                                                                color: root.theme.accentPrimary
                                                                anchors { top: parent.top; right: parent.right; topMargin: 4; rightMargin: 4 }
                                                                Text { anchors.centerIn: parent; text: "✓"; color: root.theme.textPrimary; font.pixelSize: 10; font.weight: Font.Bold }
                                                            }
                                                        }
                                                        // Caption
                                                        Text {
                                                            anchors { bottom: parent.bottom; bottomMargin: 2; horizontalCenter: parent.horizontalCenter }
                                                            text: modelData.replace("sl1c3d-l4bs-","").replace(".png","")
                                                            color: root.theme.textMuted; font.pixelSize: 8; font.family: root.theme.fontFamily
                                                        }
                                                    }
                                                }
                                            }

                                            Row {
                                                spacing: 8
                                                Repeater {
                                                    model: [
                                                        { label: "Browse folder", cmd: ["ghostty", "-e", "yazi", hubCard.home + "/assets/wallpapers"] },
                                                        { label: "Waypaper GUI",  cmd: ["waypaper"] },
                                                        { label: "Restore last",  cmd: ["waypaper", "--restore"] }
                                                    ]
                                                    delegate: MouseArea {
                                                        required property var modelData
                                                        width: btnTxt.width + 16; height: 26
                                                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                        onClicked: { hubLauncher.command = modelData.cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                        Rectangle { anchors.fill: parent; radius: root.theme.radiusPill; color: parent.containsMouse ? root.theme.accentDim2 : root.theme.bgBase; border.width: 1; border.color: root.theme.border; Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } } }
                                                        Text { id: btnTxt; anchors.centerIn: parent; text: modelData.label; color: root.theme.textPrimary; font.pixelSize: 10; font.family: root.theme.fontFamily }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // ─── 4 · CONTROL PLANE ───────────────────
                                    Flickable {
                                        anchors.fill: parent; contentHeight: ctrlCol.implicitHeight; clip: true
                                        opacity: hubCard.hubSection === 4 ? 1 : 0
                                        visible: opacity > 0
                                        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                        Column {
                                            id: ctrlCol; width: parent.width; spacing: 12

                                            Text { text: "VALIDATION & RELOAD"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily; font.letterSpacing: 1.0 }
                                            Repeater {
                                                model: [
                                                    { label: "Validate configs",    sub: "Run all 53 checks",        icon: "check-circle",    cmd: ["ghostty", "-e", "bash", "-lc", hubCard.home + "/scripts/validate-configs.sh; echo; echo 'Press Enter'; read"] },
                                                    { label: "Reload Hyprland",     sub: "Apply hypr config",        icon: "arrow-clockwise",         cmd: ["sh", "-c", "hyprctl reload >/dev/null 2>&1 || true"] },
                                                    { label: "Restart Quickshell",  sub: "Reload bar",               icon: "arrow-counter-clockwise", cmd: ["sh", "-c", "pkill quickshell; sleep 0.5; quickshell &"] }
                                                ]
                                                delegate: HubActionRow {
                                                    required property var modelData
                                                    width: ctrlCol.width; theme: root.theme; phosphorDir: root.phosphorDir
                                                    labelText: modelData.label; subText: modelData.sub; iconName: modelData.icon
                                                    onClicked: { hubLauncher.command = modelData.cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                }
                                            }

                                            Text { text: "DISPLAY & CAPTURE"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily; font.letterSpacing: 1.0 }
                                            Repeater {
                                                model: [
                                                    { label: "Screenshot (region)", sub: "Copy region to clipboard", icon: "camera",    cmd: ["sh", "-c", "grimblast copy area"] },
                                                    { label: "Screenshot (window)", sub: "Copy active window",       icon: "selection", cmd: ["sh", "-c", "grimblast copy active"] },
                                                    { label: "Color picker",        sub: "Pick & copy hex color",    icon: "palette",   cmd: ["sh", "-c", "hyprpicker -a"] },
                                                    { label: "Toggle DND",          sub: "Mako do-not-disturb",      icon: "bell",      cmd: ["sh", "-c", "makoctl mode -t do-not-disturb"] }
                                                ]
                                                delegate: HubActionRow {
                                                    required property var modelData
                                                    width: ctrlCol.width; theme: root.theme; phosphorDir: root.phosphorDir
                                                    labelText: modelData.label; subText: modelData.sub; iconName: modelData.icon
                                                    onClicked: { hubLauncher.command = modelData.cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                }
                                            }

                                            Text { text: "SERVICES"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily; font.letterSpacing: 1.0 }
                                            Repeater {
                                                model: [
                                                    { label: "AI Gateway (restart)", sub: "OpenClaw gateway", icon: "robot",        cmd: ["sh", "-c", "systemctl --user restart openclaw-gateway.service >/dev/null 2>&1 || true"] },
                                                    { label: "AGS doctor",           sub: "Quick settings",  icon: "stethoscope",  cmd: ["ghostty", "-e", "bash", "-lc", hubCard.home + "/.config/SL1C3D-L4BS/bin/sl1c3d-ags doctor; read"] }
                                                ]
                                                delegate: HubActionRow {
                                                    required property var modelData
                                                    width: ctrlCol.width; theme: root.theme; phosphorDir: root.phosphorDir
                                                    labelText: modelData.label; subText: modelData.sub; iconName: modelData.icon
                                                    onClicked: { hubLauncher.command = modelData.cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                }
                                            }
                                        }
                                    }

                                    // ─── 5 · SYSTEM ──────────────────────────
                                    Flickable {
                                        anchors.fill: parent; contentHeight: sysCol.implicitHeight; clip: true
                                        opacity: hubCard.hubSection === 5 ? 1 : 0
                                        visible: opacity > 0
                                        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                        Column {
                                            id: sysCol; width: parent.width; spacing: 12

                                            Text { text: "KEYBINDS"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily; font.letterSpacing: 1.0 }
                                            Repeater {
                                                model: [
                                                    { key: "Super + T",           desc: "Terminal (Ghostty)" },
                                                    { key: "Super + B",           desc: "Browser" },
                                                    { key: "Super + E",           desc: "File manager (Yazi)" },
                                                    { key: "Super + R",           desc: "App launcher (Fuzzel)" },
                                                    { key: "Super + Shift + B",   desc: "Btop monitor" },
                                                    { key: "Super + Shift + G",   desc: "Lazygit" },
                                                    { key: "Super + Shift + A",   desc: "AI (OpenClaw)" },
                                                    { key: "Super + Shift + T",   desc: "Dev timer" },
                                                    { key: "Super + L",           desc: "Lock screen" },
                                                    { key: "Super + A",           desc: "Window overview" },
                                                    { key: "Super + /",           desc: "Keybind help (Fuzzel)" },
                                                    { key: "Super + Q",           desc: "Close window" },
                                                    { key: "Super + F",           desc: "Fullscreen" },
                                                    { key: "Super + V",           desc: "Float toggle" }
                                                ]
                                                delegate: Item {
                                                    required property var modelData
                                                    width: sysCol.width; height: 26
                                                    Row {
                                                        anchors { fill: parent; leftMargin: 4; rightMargin: 4 }
                                                        spacing: 0
                                                        Rectangle {
                                                            height: 20; width: kbdTxt.width + 12; radius: 5
                                                            color: root.theme.bgBase; border.width: 1; border.color: root.theme.border
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            Text { id: kbdTxt; anchors.centerIn: parent; text: modelData.key; color: root.theme.accentPrimary; font.pixelSize: 9; font.family: root.theme.fontFamily }
                                                        }
                                                        Item { width: 8; height: 1 }
                                                        Text { text: modelData.desc; color: root.theme.textSecondary; font.pixelSize: 10; font.family: root.theme.fontFamily; anchors.verticalCenter: parent.verticalCenter }
                                                    }
                                                }
                                            }

                                            Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.4 }

                                            Text { text: "LAUNCH"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily; font.letterSpacing: 1.0 }
                                            Flow {
                                                width: parent.width; spacing: 6
                                                Repeater {
                                                    model: [
                                                        { label: "Ghostty",   cmd: ["ghostty"] },
                                                        { label: "Fuzzel",    cmd: ["fuzzel"] },
                                                        { label: "Waypaper",  cmd: ["waypaper"] },
                                                        { label: "btop",      cmd: ["ghostty", "-e", "btop"] },
                                                        { label: "lazygit",   cmd: ["ghostty", "-e", "lazygit"] },
                                                        { label: "nmtui",     cmd: ["ghostty", "-e", "nmtui"] },
                                                        { label: "Yazi",      cmd: ["ghostty", "-e", "yazi"] },
                                                        { label: "Python",    cmd: ["ghostty", "-e", "python3"] }
                                                    ]
                                                    delegate: MouseArea {
                                                        required property var modelData
                                                        width: launchTxt.width + 16; height: 26
                                                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                        onClicked: { hubLauncher.command = modelData.cmd; hubLauncher.running = true; panelWindow.hubOpen = false }
                                                        Rectangle { anchors.fill: parent; radius: root.theme.radiusPill; color: parent.containsMouse ? root.theme.accentDim2 : root.theme.bgBase; border.width: 1; border.color: root.theme.border; Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } } }
                                                        Text { id: launchTxt; anchors.centerIn: parent; text: modelData.label; color: root.theme.textPrimary; font.pixelSize: 10; font.family: root.theme.fontFamily }
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
                anchor.item: timePill
                anchor.edges: Edges.Bottom | Edges.Left
                anchor.gravity: Edges.Bottom | Edges.Right
                anchor.adjustment: PopupAdjustment.Flip
                anchor.margins.top: 8
                implicitWidth: 268
                implicitHeight: 416
                visible: panelWindow.focusOpen
                color: "transparent"

                onVisibleChanged: if (!visible) panelWindow.focusOpen = false

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
                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
                        spacing: 0

                        // ── Header ─────────────────────────────────────────────
                        Item {
                            width: parent.width; height: 34
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
                        Item { height: 10 }

                        // ── Large live clock ────────────────────────────────────
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: root.barTimeString + ":" + root.barSecondsString
                            color: root.theme.accentPrimary
                            font.pixelSize: 39; font.weight: Font.Bold
                            font.family: root.theme.fontFamily
                        }
                        Item { height: 2 }
                        Text {
                            width: parent.width; horizontalAlignment: Text.AlignHCenter
                            text: root.barDayString + "  ·  " + root.barDateString
                            color: root.theme.textMuted
                            font.pixelSize: 11; font.family: root.theme.fontFamily
                        }

                        Item { height: 10 }
                        Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.4 }
                        Item { height: 8 }

                        // ── Dev timer ring ─────────────────────────────────────
                        Item {
                            width: parent.width; height: 76

                            Canvas {
                                id: timerRing
                                width: 68; height: 68
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
                                    var cx = width/2, cy = height/2, r = 28
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
                                anchors { left: timerRing.right; leftMargin: 10; verticalCenter: parent.verticalCenter; right: parent.right }
                                spacing: 4
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
                                    width: parent.width; height: 24
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

                        Item { height: 8 }
                        Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.4 }
                        Item { height: 8 }

                        // ── Quick timers ───────────────────────────────────────
                        Text {
                            text: "QUICK TIMER"
                            color: root.theme.textMuted; font.pixelSize: 9; font.letterSpacing: 0.8
                            font.family: root.theme.fontFamily
                        }
                        Item { height: 6 }
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
                                    width: (parent.width - 18) / 4; height: 24
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

                        Item { height: 8 }
                        Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.4 }
                        Item { height: 8 }

                        // ── World clocks ───────────────────────────────────────
                        Text {
                            text: "WORLD CLOCKS"
                            color: root.theme.textMuted; font.pixelSize: 9; font.letterSpacing: 0.8
                            font.family: root.theme.fontFamily
                        }
                        Item { height: 6 }
                        Item {
                            width: parent.width; height: 22
                            Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "Local"; color: root.theme.textSecondary; font.pixelSize: 11; font.family: root.theme.fontFamily }
                            Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: root.barTimeString; color: root.theme.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold; font.family: root.theme.fontFamily }
                        }
                        Item {
                            width: parent.width; height: 22
                            Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "UTC"; color: root.theme.textSecondary; font.pixelSize: 11; font.family: root.theme.fontFamily }
                            Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: root.tz2String; color: root.theme.logoPurple; font.pixelSize: 13; font.weight: Font.DemiBold; font.family: root.theme.fontFamily }
                        }

                        Item { height: 8 }
                        Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.4 }
                        Item { height: 8 }

                        // ── Uptime ─────────────────────────────────────────────
                        Item {
                            width: parent.width; height: 18
                            Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "UPTIME"; color: root.theme.textMuted; font.pixelSize: 9; font.letterSpacing: 0.8; font.family: root.theme.fontFamily }
                            Text {
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                text: root.uptimeString; color: root.theme.textSecondary; font.pixelSize: 10; font.family: root.theme.fontFamily
                                elide: Text.ElideLeft; width: parent.width * 0.72; horizontalAlignment: Text.AlignRight
                            }
                        }
                        Item { height: 8 }
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // CALENDAR + NOTES PANEL  (date pill click)
            // ═══════════════════════════════════════════════════════════════
            PopupWindow {
                id: calPopup
                anchor.item: timeDatePill
                anchor.edges: Edges.Bottom | Edges.Left
                anchor.gravity: Edges.Bottom | Edges.Right
                anchor.adjustment: PopupAdjustment.Flip
                anchor.margins.top: 8
                implicitWidth: 332
                implicitHeight: panelWindow.calTab === "notes" ? 432 : 360
                visible: panelWindow.calendarOpen

                Behavior on implicitHeight { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                color: "transparent"

                onVisibleChanged: if (!visible) panelWindow.calendarOpen = false

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
                                const loaded = text || ""
                                panelWindow.notesContent = loaded
                                calCard.loadedText = loaded
                                calCard.confirmingClear = false
                                autosaveTimer.stop()
                                if (notesEditor) notesEditor.text = loaded
                            }
                        }
                    }
                    Process { id: notesSaveProc; running: false }
                    Process {
                        id: noteDeleteProc
                        running: false
                        stdout: StdioCollector {
                            onStreamFinished: function() {
                                calCard.refreshDays()
                                calCard.refreshRecent()
                            }
                        }
                    }
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
                    property string loadedText: ""
                    property bool confirmingClear: false
                    property bool noteDirty: notesEditor ? (notesEditor.text !== loadedText) : false

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
                        if (notesSaveProc.running) { autosaveTimer.restart(); return }
                        autosaveTimer.stop()
                        const content = notesEditor ? notesEditor.text : ""
                        notesSaveProc.environment = { "NOTE_CONTENT": content }
                        notesSaveProc.command = ["sh", "-c",
                            "mkdir -p ~/.local/share/sl1c3d-labs/notes && " +
                            "printf '%s' \"$NOTE_CONTENT\" > ~/.local/share/sl1c3d-labs/notes/" +
                            panelWindow.calSelectedDate + ".txt"]
                        notesSaveProc.running = true
                        calCard.loadedText = content
                        calCard.confirmingClear = false
                        refreshDays()
                        refreshRecent()
                    }
                    function deleteNote() {
                        if (!panelWindow.calSelectedDate) return
                        autosaveTimer.stop()
                        noteDeleteProc.command = ["sh", "-c",
                            "rm -f ~/.local/share/sl1c3d-labs/notes/" +
                            panelWindow.calSelectedDate + ".txt"]
                        noteDeleteProc.running = true
                        if (notesEditor) notesEditor.text = ""
                        panelWindow.notesContent = ""
                        calCard.loadedText = ""
                        calCard.confirmingClear = false
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

                    Timer { id: autosaveTimer; interval: 2500; repeat: false; onTriggered: calCard.saveNote() }
                    Timer { id: clearCancelTimer; interval: 3000; repeat: false; onTriggered: calCard.confirmingClear = false }

                    Column {
                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
                        spacing: 0

                        // ── Tab header ──────────────────────────────────────────
                        Item {
                            width: parent.width; height: 34

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
                        Item { height: 8 }

                        // ── CALENDAR TAB ──────────────────────────────────────
                        Column {
                            width: parent.width
                            spacing: 0
                            visible: panelWindow.calTab === "cal"

                            // Month navigation
                            Row {
                                width: parent.width; height: 28; spacing: 0

                                MouseArea {
                                    id: calPrevBtn; width: 28; height: 28
                                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                    onClicked: { calCard.viewMonth--; if (calCard.viewMonth < 0) { calCard.viewMonth = 11; calCard.viewYear-- } }
                                    Rectangle { anchors.fill: parent; radius: 6; color: parent.containsMouse ? root.theme.accentDim2 : "transparent"; Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        Text { anchors.centerIn: parent; text: "‹"; color: root.theme.logoPurple; font.pixelSize: 16; font.family: root.theme.fontFamily }
                                    }
                                }

                                Text {
                                    width: parent.width - 28 - 28 - 56
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: calCard.monthNames[calCard.viewMonth] + " " + calCard.viewYear
                                    color: root.theme.textPrimary; font.pixelSize: 12; font.weight: Font.DemiBold
                                    font.family: root.theme.fontFamily; horizontalAlignment: Text.AlignHCenter
                                }

                                MouseArea {
                                    id: todayBtn; width: 44; height: 20; anchors.verticalCenter: parent.verticalCenter
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
                                    id: calNextBtn; width: 28; height: 28
                                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                    onClicked: { calCard.viewMonth++; if (calCard.viewMonth > 11) { calCard.viewMonth = 0; calCard.viewYear++ } }
                                    Rectangle { anchors.fill: parent; radius: 6; color: parent.containsMouse ? root.theme.accentDim2 : "transparent"; Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        Text { anchors.centerIn: parent; text: "›"; color: root.theme.logoPurple; font.pixelSize: 16; font.family: root.theme.fontFamily }
                                    }
                                }
                            }

                            Item { height: 6 }

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

                            Item { height: 3 }

                            // Dynamic-row calendar grid (4–6 rows depending on month)
                            Column {
                                id: calGridCol
                                width: parent.width; spacing: 2

                                property int gYear:     calCard.viewYear
                                property int gMonth:    calCard.viewMonth
                                property int firstDay:  { var d = new Date(gYear, gMonth, 1); return (d.getDay() + 6) % 7 }
                                property int daysInMon: new Date(gYear, gMonth + 1, 0).getDate()
                                property int rowCount:  Math.ceil((firstDay + daysInMon) / 7)

                                Repeater {
                                    model: calGridCol.rowCount
                                    delegate: Row {
                                        required property int index
                                        id: weekRowItem
                                        spacing: 2
                                        property int rowStart: index * 7

                                        // Week number cell
                                        Text {
                                            width: 20; height: 28; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
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
                                                width: 36; height: 28

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
                                                        calCard.loadNote(dayCell.dKey)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { height: 8 }
                            Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.4 }
                            Item { height: 8 }

                            // Selected date strip
                            Rectangle {
                                width: parent.width; height: 34; radius: root.theme.radiusPill
                                color: root.theme.bgBase; border.width: 1; border.color: root.theme.border
                                Row {
                                    anchors.centerIn: parent; spacing: 10
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: root.barTimeString + ":" + root.barSecondsString; color: root.theme.logoPurple; font.pixelSize: 14; font.weight: Font.Bold; font.family: root.theme.fontFamily }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: panelWindow.calSelectedDate || root.barDateString; color: root.theme.textPrimary; font.pixelSize: 11; font.family: root.theme.fontFamily }
                                }
                            }
                            Item { height: 6 }

                            // Open notes for selected day
                            MouseArea {
                                id: openNoteBtn; width: parent.width; height: 28
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
                            Item { height: 6 }
                        }

                        // ── NOTES TAB ──────────────────────────────────────────
                        Column {
                            width: parent.width; spacing: 0
                            visible: panelWindow.calTab === "notes"

                            // ── Header: date label + delete + save ─────────────
                            Item {
                                width: parent.width; height: 28

                                Row {
                                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "✏"; color: root.theme.logoPurple; font.pixelSize: 12; font.family: root.theme.fontFamily }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: panelWindow.calSelectedDate || "Today"; color: root.theme.textMuted; font.pixelSize: 11; font.family: root.theme.fontFamily }
                                }

                                Row {
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 4

                                    // Delete button
                                    MouseArea {
                                        id: deleteNoteBtn; width: 24; height: 22
                                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                        onClicked: calCard.deleteNote()
                                        Rectangle {
                                            anchors.fill: parent; radius: 6
                                            color: deleteNoteBtn.containsMouse ? "#3a1010" : root.theme.bgBase
                                            border.width: 1; border.color: deleteNoteBtn.containsMouse ? root.theme.accentRed : root.theme.border
                                            Behavior on color       { ColorAnimation { duration: root.theme.motionFastMs } }
                                            Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                                            Text { anchors.centerIn: parent; text: "🗑"; font.pixelSize: 10; color: root.theme.accentRed }
                                        }
                                    }

                                    // Save button with dirty indicator
                                    MouseArea {
                                        id: saveNoteBtn; width: 52; height: 22
                                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                        onClicked: calCard.saveNote()
                                        Rectangle {
                                            anchors.fill: parent; radius: root.theme.radiusPill
                                            color: saveNoteBtn.containsMouse ? root.theme.accentPrimary
                                                 : calCard.noteDirty         ? root.theme.accentDim2
                                                 : root.theme.bgBase
                                            border.width: 1
                                            border.color: calCard.noteDirty ? root.theme.accentPrimary : root.theme.border
                                            Behavior on color        { ColorAnimation { duration: root.theme.motionFastMs } }
                                            Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                                            Row {
                                                anchors.centerIn: parent; spacing: 3
                                                Rectangle {
                                                    width: 5; height: 5; radius: 2.5
                                                    color: root.theme.accentPrimary
                                                    visible: calCard.noteDirty
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Save"; color: root.theme.textPrimary; font.pixelSize: 10; font.weight: Font.Medium; font.family: root.theme.fontFamily }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { height: 6 }

                            // ── Note editor ────────────────────────────────────
                            Rectangle {
                                width: parent.width; height: 152; radius: 10
                                color: root.theme.bgBase; clip: true
                                border.width: 1
                                border.color: notesEditor.activeFocus ? root.theme.accentPrimary : root.theme.border
                                Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }

                                Flickable {
                                    id: noteFlickable
                                    anchors { top: parent.top; left: parent.left; bottom: parent.bottom; right: noteScrollBar.left }
                                    anchors.margins: 8; anchors.rightMargin: 2
                                    contentHeight: notesEditor.contentHeight
                                    clip: true
                                    interactive: contentHeight > height

                                    TextEdit {
                                        id: notesEditor
                                        width: parent.width
                                        color: root.theme.textPrimary
                                        font.pixelSize: 12; font.family: root.theme.fontFamily
                                        wrapMode: TextEdit.Wrap
                                        selectByMouse: true
                                        selectedTextColor: root.theme.bgBase
                                        selectionColor: root.theme.accentPrimary

                                        onTextChanged: {
                                            if (text !== calCard.loadedText) autosaveTimer.restart()
                                        }
                                    }

                                    // Placeholder text when editor is empty
                                    Text {
                                        anchors.fill: parent
                                        text: "Write your notes for " + (panelWindow.calSelectedDate || "today") + "…"
                                        color: root.theme.textMuted
                                        font.pixelSize: 12; font.family: root.theme.fontFamily
                                        wrapMode: Text.Wrap
                                        visible: notesEditor.text.length === 0 && !notesEditor.activeFocus
                                    }
                                }

                                // Slim custom scrollbar (no QtQuick.Controls needed)
                                Rectangle {
                                    id: noteScrollBar
                                    anchors { top: parent.top; right: parent.right; bottom: parent.bottom; margins: 4 }
                                    width: 3; radius: 2
                                    color: root.theme.border
                                    visible: noteFlickable.contentHeight > noteFlickable.height
                                    Rectangle {
                                        width: parent.width; radius: 2
                                        color: root.theme.accentPrimary
                                        height: noteFlickable.height > 0
                                            ? (noteFlickable.height / noteFlickable.contentHeight) * parent.height
                                            : parent.height
                                        y: noteFlickable.contentHeight > noteFlickable.height
                                            ? (noteFlickable.contentY / noteFlickable.contentHeight) * parent.height
                                            : 0
                                        Behavior on y { NumberAnimation { duration: 80 } }
                                    }
                                }
                            }

                            Item { height: 4 }

                            // ── Toolbar ────────────────────────────────────────
                            Row {
                                spacing: 5; width: parent.width

                                // Format tools
                                Repeater {
                                    model: [
                                        { label: "B", action: "bold" },
                                        { label: "I", action: "italic" },
                                        { label: "—", action: "hr" },
                                        { label: "⎘", action: "copy" }
                                    ]
                                    delegate: MouseArea {
                                        required property var modelData
                                        id: fmtBtn; width: 28; height: 24
                                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                        onClicked: {
                                            if      (modelData.action === "bold")   notesEditor.insert(notesEditor.cursorPosition, "**text**")
                                            else if (modelData.action === "italic") notesEditor.insert(notesEditor.cursorPosition, "_text_")
                                            else if (modelData.action === "hr")     notesEditor.insert(notesEditor.cursorPosition, "\n---\n")
                                            else if (modelData.action === "copy")   { notesEditor.selectAll(); notesEditor.copy() }
                                        }
                                        Rectangle {
                                            anchors.fill: parent; radius: 6
                                            color: fmtBtn.containsMouse ? root.theme.accentDim2 : root.theme.bgBase
                                            border.width: 1; border.color: root.theme.border
                                            Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                            Text { anchors.centerIn: parent; text: fmtBtn.modelData.label; color: root.theme.textSecondary; font.pixelSize: 11; font.family: root.theme.fontFamily }
                                        }
                                    }
                                }

                                // Clear button (two-step confirmation)
                                MouseArea {
                                    id: clearBtn; width: calCard.confirmingClear ? 52 : 28; height: 24
                                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                    Behavior on width { NumberAnimation { duration: 120 } }
                                    onClicked: {
                                        if (!calCard.confirmingClear) {
                                            calCard.confirmingClear = true
                                            clearCancelTimer.restart()
                                        } else {
                                            notesEditor.text = ""
                                            calCard.confirmingClear = false
                                            clearCancelTimer.stop()
                                        }
                                    }
                                    Rectangle {
                                        anchors.fill: parent; radius: 6
                                        color: calCard.confirmingClear ? "#3a1010" : (clearBtn.containsMouse ? root.theme.accentDim2 : root.theme.bgBase)
                                        border.width: 1
                                        border.color: calCard.confirmingClear ? root.theme.accentRed : root.theme.border
                                        Behavior on color        { ColorAnimation { duration: root.theme.motionFastMs } }
                                        Behavior on border.color { ColorAnimation { duration: root.theme.motionFastMs } }
                                        Text {
                                            anchors.centerIn: parent
                                            text: calCard.confirmingClear ? "Sure?" : "⌫"
                                            color: calCard.confirmingClear ? root.theme.accentRed : root.theme.textSecondary
                                            font.pixelSize: calCard.confirmingClear ? 9 : 11; font.family: root.theme.fontFamily
                                        }
                                    }
                                }

                                // Autosave status indicator (right-aligned)
                                Item { width: parent.width - 4*28 - 52 - 5*5; height: 1 }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: autosaveTimer.running ? "saving…" : (calCard.noteDirty ? "unsaved" : "saved")
                                    color: calCard.noteDirty ? root.theme.accentOrange : root.theme.textMuted
                                    font.pixelSize: 9; font.family: root.theme.fontFamily
                                    Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } }
                                }
                            }

                            Item { height: 8 }
                            Rectangle { width: parent.width; height: 1; color: root.theme.border; opacity: 0.4 }
                            Item { height: 8 }

                            Text { text: "RECENT NOTES"; color: root.theme.textMuted; font.pixelSize: 9; font.letterSpacing: 0.8; font.family: root.theme.fontFamily }
                            Item { height: 6 }

                            Repeater {
                                model: calCard.recentNotes.length > 0
                                    ? calCard.recentNotes
                                    : [{ date: "—", preview: "No notes yet. Click a day and start writing." }]
                                delegate: MouseArea {
                                    required property var modelData
                                    id: recentRow
                                    width: parent.width; height: 38
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
                            Item { height: 6 }
                        }
                    }
                }
            }

            // ─── Volume OSD ─────────────────────────────────────────────────
            PwObjectTracker { id: osdPwTracker; objects: [Pipewire.defaultAudioSink] }

            Timer {
                id: volumeOsdDismiss
                interval: 2200; repeat: false
                onTriggered: panelWindow.volumeOsdVisible = false
            }
            Connections {
                target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
                function onVolumeChanged() {
                    const v = Pipewire.defaultAudioSink?.audio?.volume ?? 0
                    panelWindow.volumeOsdLevel = Math.min(1.0, v)
                    panelWindow.volumeOsdVisible = true
                    volumeOsdDismiss.restart()
                }
            }

            PopupWindow {
                anchor.window: panelWindow
                implicitWidth: 220
                implicitHeight: 52
                color: "transparent"
                visible: panelWindow.volumeOsdVisible

                anchor.onAnchoring: {
                    if (!anchor.window) return
                    const pw = anchor.window.width
                    const ph = anchor.window.height
                    const x = (pw - implicitWidth) / 2
                    const y = ph - implicitHeight - 64
                    anchor.rect = Qt.rect(x, y, implicitWidth, implicitHeight)
                }

                GlassSurface {
                    theme: root.theme
                    strong: true
                    anchors.fill: parent
                    radius: root.theme.radiusPill

                    scale:   panelWindow.volumeOsdVisible ? 1.0 : 0.88
                    opacity: panelWindow.volumeOsdVisible ? 1.0 : 0.0
                    Behavior on scale   { SpringAnimation { spring: 2.5; damping: 0.7 } }
                    Behavior on opacity { NumberAnimation { duration: root.theme.motionBaseMs; easing.type: Easing.OutCubic } }

                    Row {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                const v = panelWindow.volumeOsdLevel
                                if (v === 0) return "🔇"
                                if (v < 0.33) return "🔈"
                                if (v < 0.66) return "🔉"
                                return "🔊"
                            }
                            font.pixelSize: 14
                        }

                        // Volume bar
                        Item {
                            width: parent.width - 50 - 46
                            height: 6
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                anchors.fill: parent; radius: 3; color: root.theme.border
                                Rectangle {
                                    width: parent.width * panelWindow.volumeOsdLevel
                                    height: parent.height; radius: 3
                                    color: panelWindow.volumeOsdLevel > 1.0 ? root.theme.accentRed : root.theme.accentPrimary
                                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(panelWindow.volumeOsdLevel * 100) + "%"
                            color: root.theme.textPrimary
                            font.pixelSize: 12; font.family: root.theme.fontFamily; font.weight: Font.DemiBold
                            width: 36; horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            // ─── Network quick-settings popup ───────────────────────────────
            Process {
                id: netDetailsProc
                property string output: ""
                command: ["sh", "-c", "ip route get 1 2>/dev/null | awk '{print $7; exit}'; echo '---'; nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | awk -F: '$1==\"yes\"{print $2\"|\"$3; exit}'; echo '---'; ip -4 addr show 2>/dev/null | awk '/inet /{print $2; exit}'"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: netDetailsProc.output = text.trim()
                }
            }
            PopupWindow {
                anchor.item: netPill
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
                anchor.adjustment: PopupAdjustment.Flip
                anchor.margins.top: 8
                implicitWidth: 230
                implicitHeight: netQuickCol.implicitHeight + 24
                color: "transparent"
                visible: panelWindow.networkPopupOpen
                onVisibleChanged: {
                    if (visible) { netDetailsProc.output = ""; netDetailsProc.running = true }
                    else panelWindow.networkPopupOpen = false
                }
                GlassSurface {
                    theme: root.theme; strong: true; anchors.fill: parent
                    radius: root.theme.radiusModal; clip: true

                    scale:   panelWindow.networkPopupOpen ? 1.0 : 0.92
                    opacity: panelWindow.networkPopupOpen ? 1.0 : 0.0
                    Behavior on scale   { SpringAnimation { spring: 2.5; damping: 0.7 } }
                    Behavior on opacity { NumberAnimation { duration: root.theme.motionBaseMs; easing.type: Easing.OutCubic } }

                    Column {
                        id: netQuickCol
                        anchors { fill: parent; margins: 14 }
                        spacing: 10

                        Row {
                            width: parent.width
                            Text { text: "NETWORK"; color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily; font.letterSpacing: 1.0 }
                            Item { width: parent.width - networkCloseBtn.width - 60; height: 1 }
                            MouseArea {
                                id: networkCloseBtn
                                width: 18; height: 18; cursorShape: Qt.PointingHandCursor
                                onClicked: panelWindow.networkPopupOpen = false
                                Text { anchors.centerIn: parent; text: "✕"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.theme.fontFamily }
                            }
                        }

                        // SSID + status
                        Rectangle {
                            width: parent.width; height: 36; radius: root.theme.radiusPill
                            color: root.theme.bgBase; border.width: 1; border.color: root.theme.border
                            Row {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                spacing: 8
                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: root.phosphorDir + "/network.svg"
                                    width: 14; height: 14; fillMode: Image.PreserveAspectFit; smooth: true
                                }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter; spacing: 1
                                    Text {
                                        text: SystemInfo.networkInfo
                                        color: SystemInfo.networkInfo === "Disconnected" ? root.theme.accentRed : root.theme.accentGreen
                                        font.pixelSize: 11; font.family: root.theme.fontFamily; font.weight: Font.DemiBold
                                    }
                                    Text {
                                        text: {
                                            const parts = (netDetailsProc.output || "").split("\n---\n")
                                            if (parts.length > 2) return (parts[2] || "").trim() || "—"
                                            return "—"
                                        }
                                        color: root.theme.textMuted; font.pixelSize: 9; font.family: root.theme.fontFamily
                                    }
                                }
                            }
                        }

                        // Quick actions
                        Row {
                            width: parent.width; spacing: 6
                            Repeater {
                                model: [
                                    { label: "nmtui",        cmd: ["ghostty", "-e", "nmtui"] },
                                    { label: "Toggle WiFi",  cmd: ["sh", "-c", "nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on"] },
                                    { label: "Disconnect",   cmd: ["sh", "-c", "nmcli networking off; sleep 0.5; nmcli networking on"] }
                                ]
                                delegate: MouseArea {
                                    required property var modelData
                                    height: 28; width: (netQuickCol.width - 12) / 3
                                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                    onClicked: { netLauncher.command = modelData.cmd; netLauncher.running = true; panelWindow.networkPopupOpen = false }
                                    Rectangle { anchors.fill: parent; radius: root.theme.radiusPill; color: parent.containsMouse ? root.theme.accentDim2 : root.theme.bgBase; border.width: 1; border.color: root.theme.border; Behavior on color { ColorAnimation { duration: root.theme.motionFastMs } } }
                                    Text { anchors.centerIn: parent; text: modelData.label; color: root.theme.textPrimary; font.pixelSize: 9; font.family: root.theme.fontFamily }
                                }
                            }
                        }
                    }
                }
                Process { id: netLauncher; command: ["sh", "-c", "true"]; running: false }
            }
        }
    }
}
}
