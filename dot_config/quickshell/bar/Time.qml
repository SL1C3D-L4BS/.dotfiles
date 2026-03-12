pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string timeString: Qt.formatTime(systemClock.time, "HH:mm")
    property string dateString: Qt.formatDate(systemClock.time, "ddd MMM d")
    property string longDateString: Qt.formatDate(systemClock.time, "MMM d, yyyy")

    SystemClock {
        id: systemClock
        precision: SystemClock.Seconds
    }
}
