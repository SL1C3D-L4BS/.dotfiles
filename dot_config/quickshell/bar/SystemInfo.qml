pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string cpuUsage: "0%"
    property real   cpuUsageNum: 0
    property string memoryUsage: "0%"
    property real   ramUsageNum: 0
    property real   diskUsageNum: 0
    property string networkInfo: "Disconnected"

    // Sparkline history — last 30 samples (one per ~1.5s = ~45s window)
    property var cpuHistory: []
    property var ramHistory: []
    readonly property int sparkMaxSamples: 30

    function pushSample(arr, val) {
        const copy = arr.slice()
        copy.push(val)
        if (copy.length > sparkMaxSamples) copy.shift()
        return copy
    }
    property int batteryLevelRaw: 0
    property string batteryLevel: "0%"
    property string batteryIcon: ""
    property bool batteryCharging: false
    property string temperature: "N/A"

    Process {
        id: cpuProc
        command: ["sh", "-c", "top -bn1 2>/dev/null | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1\"%\"}' || echo '0%'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: function() {
                const s = (text && text.trim()) ? text.trim() : "0%"
                root.cpuUsage = s
                const n = parseFloat(s) || 0
                root.cpuUsageNum = n
                root.cpuHistory = root.pushSample(root.cpuHistory, n)
            }
        }
    }

    Process {
        id: memProc
        command: ["sh", "-c", "free 2>/dev/null | grep Mem | awk '{printf \"%.1f%%\", ($3/$2) * 100.0}' || echo '0%'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: function() {
                const s = (text && text.trim()) ? text.trim() : "0%"
                root.memoryUsage = s
                const n = parseFloat(s) || 0
                root.ramUsageNum = n
                root.ramHistory = root.pushSample(root.ramHistory, n)
            }
        }
    }

    Process {
        id: diskProc
        command: ["sh", "-c", "df / 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%' || echo '0'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: function() { root.diskUsageNum = parseFloat(text.trim()) || 0 }
        }
    }

    Process {
        id: netProc
        command: ["sh", "-c", "{ nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1==\"yes\" {print ($2 ? $2 : \"Wi‑Fi\"); exit}'; nmcli -t -f TYPE connection show --active 2>/dev/null | grep -qE '802-3-ethernet|ethernet' && echo 'Ethernet'; nmcli -t -f DEVICE,STATE device 2>/dev/null | awk -F: '$2~/connected/ && $1!~/^wl/ {print \"Ethernet\"; exit}'; nmcli -t connection show --active 2>/dev/null | head -1 | cut -d: -f1; echo 'Disconnected'; } | grep -m1 ."]
        running: true
        stdout: StdioCollector {
            onStreamFinished: function() {
                const s = (text && text.trim()) ? text.trim() : ""
                root.networkInfo = s || "Disconnected"
            }
        }
    }

    Process {
        id: batteryProc
        command: ["sh", "-c", "printf '%s\\n%s' \"$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo '99')\" \"$(cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo 'Discharging')\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: function() {
                const lines = (text && text.trim()) ? text.trim().split("\n") : ["99", "Discharging"]
                const level = parseInt(lines[0]) || 0
                const status = (lines[1] || "Discharging").trim()
                root.batteryLevelRaw = level
                root.batteryLevel = level + "%"
                root.batteryCharging = status === "Charging"
                if (level >= 90) root.batteryIcon = "󰁹"
                else if (level >= 80) root.batteryIcon = "󰂂"
                else if (level >= 70) root.batteryIcon = "󰂁"
                else if (level >= 60) root.batteryIcon = "󰂀"
                else if (level >= 50) root.batteryIcon = "󰁿"
                else if (level >= 40) root.batteryIcon = "󰁾"
                else if (level >= 30) root.batteryIcon = "󰁽"
                else if (level >= 20) root.batteryIcon = "󰁼"
                else if (level >= 10) root.batteryIcon = "󰁻"
                else root.batteryIcon = "󰁺"
            }
        }
    }

    Process {
        id: tempProc
        command: ["sh", "-c", "sensors 2>/dev/null | grep -E 'Package id 0|Tctl' | head -1 | awk '{print $2}' | sed 's/+//' || echo 'N/A'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: function() { root.temperature = (text && text.trim()) ? text.trim() : "N/A" }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: function() {
            cpuProc.running = true
            memProc.running = true
            diskProc.running = true
            netProc.running = true
            batteryProc.running = true
            tempProc.running = true
        }
    }
}
