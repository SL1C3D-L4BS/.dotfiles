// ─────────────────────────────────────────────────────────────────────────────
// AIPanel.qml — SL1C3D-L4BS native AI sidebar in Quickshell bar
// Wired to OpenClaw gateway: http://127.0.0.1:18789/v1
// Toggle: bar AI button or Super+Shift+A
// ─────────────────────────────────────────────────────────────────────────────

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

Item {
    id: root
    required property var theme

    // ── State ──────────────────────────────────────────────────────────────
    property bool visible_: false
    property string currentModel: "gpt-4o"
    property var models: ["gpt-4o", "qwen2.5-coder:7b", "deepseek-r1:7b"]
    property var history: []          // [{role, content}]
    property bool isLoading: false
    property string streamBuffer: ""

    // ── Toggle visibility ──────────────────────────────────────────────────
    function toggle() {
        visible_ = !visible_
        if (visible_) inputField.forceActiveFocus()
    }

    function sendMessage(msg) {
        if (msg.trim() === "" || isLoading) return
        inputField.text = ""
        isLoading = true
        streamBuffer = ""

        // Add user message to history
        var userEntry = { role: "user", content: msg }
        history.push(userEntry)
        historyChanged()

        // Add empty assistant placeholder
        var assistantEntry = { role: "assistant", content: "" }
        history.push(assistantEntry)
        historyChanged()

        // Build JSON payload
        var payload = JSON.stringify({
            model: currentModel,
            stream: true,
            messages: history.slice(0, history.length - 1)
        })

        // Launch curl for SSE streaming
        aiProc.command = [
            "curl", "-s", "-N",
            "-X", "POST",
            "-H", "Content-Type: application/json",
            "-H", "Authorization: Bearer sk-local",
            "-d", payload,
            "http://127.0.0.1:18789/v1/chat/completions"
        ]
        aiProc.running = true
    }

    // ── SSE curl process ───────────────────────────────────────────────────
    Process {
        id: aiProc
        stdout: SplitParser {
            onRead: function(line) {
                if (line.startsWith("data: ")) {
                    var data = line.substring(6)
                    if (data === "[DONE]") {
                        isLoading = false
                        return
                    }
                    try {
                        var obj = JSON.parse(data)
                        var delta = obj.choices?.[0]?.delta?.content ?? ""
                        if (delta) {
                            streamBuffer += delta
                            // Update last assistant message
                            if (history.length > 0) {
                                history[history.length - 1].content = streamBuffer
                                historyChanged()
                            }
                        }
                        // Check for finish
                        if (obj.choices?.[0]?.finish_reason === "stop") {
                            isLoading = false
                        }
                    } catch (e) {}
                }
            }
        }
        onExited: function(code, signal) {
            isLoading = false
        }
    }

    // ── Panel window ───────────────────────────────────────────────────────
    PanelWindow {
        id: panel
        visible: root.visible_
        width: 380
        height: Screen.height - 80
        anchors {
            right: true
            top: true
            margins { top: 40; right: 8 }
        }
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Close on Escape
        Keys.onEscapePressed: root.visible_ = false

        Rectangle {
            anchors.fill: parent
            color: root.theme.surfaceGlassStrong
            border.color: root.theme.border
            border.width: 1
            radius: root.theme.radiusModal

            ColumnLayout {
                anchors { fill: parent; margins: 12 }
                spacing: 8

                // ── Header ───────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "󰧑  AI"
                        color: root.theme.accentPrimary
                        font.family: root.theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    // Model selector
                    ComboBox {
                        id: modelSelector
                        model: root.models
                        currentIndex: root.models.indexOf(root.currentModel)
                        onCurrentTextChanged: root.currentModel = currentText
                        implicitWidth: 160
                        implicitHeight: 28
                        font.family: root.theme.fontFamily
                        font.pixelSize: 11
                        contentItem: Text {
                            text: modelSelector.displayText
                            color: root.theme.textSecondary
                            font: modelSelector.font
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }
                        background: Rectangle {
                            color: root.theme.bgSurface
                            border.color: root.theme.border
                            border.width: 1
                            radius: 6
                        }
                        popup: Popup {
                            width: modelSelector.width
                            padding: 4
                            background: Rectangle {
                                color: root.theme.bgSurface
                                border.color: root.theme.accentPrimary
                                border.width: 1
                                radius: 8
                            }
                            contentItem: ListView {
                                model: modelSelector.delegateModel
                                implicitHeight: contentHeight
                            }
                        }
                        delegate: ItemDelegate {
                            required property string modelData
                            width: modelSelector.width
                            contentItem: Text {
                                text: modelData
                                color: root.theme.textPrimary
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: hovered ? Qt.rgba(
                                    root.theme.accentPrimary.r,
                                    root.theme.accentPrimary.g,
                                    root.theme.accentPrimary.b, 0.15) : "transparent"
                                radius: 4
                            }
                        }
                    }

                    // Clear button
                    Rectangle {
                        width: 28; height: 28
                        color: clearArea.containsMouse ? Qt.rgba(1,0,0,0.15) : "transparent"
                        border.color: root.theme.border
                        border.width: 1
                        radius: 6
                        Text {
                            anchors.centerIn: parent
                            text: "󰆴"
                            color: root.theme.accentRed
                            font.family: root.theme.fontFamily
                            font.pixelSize: 14
                        }
                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.history = []
                                root.streamBuffer = ""
                                root.isLoading = false
                            }
                        }
                    }
                }

                // ── Conversation area ──────────────────────────────────────
                ScrollView {
                    id: scrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    Column {
                        id: messageColumn
                        width: scrollView.availableWidth
                        spacing: 8

                        Repeater {
                            model: root.history
                            delegate: Item {
                                required property var modelData
                                width: messageColumn.width
                                height: msgBubble.height + 4

                                Rectangle {
                                    id: msgBubble
                                    width: parent.width
                                    height: msgText.implicitHeight + 16
                                    color: modelData.role === "user"
                                        ? Qt.rgba(root.theme.accentPrimary.r,
                                                  root.theme.accentPrimary.g,
                                                  root.theme.accentPrimary.b, 0.15)
                                        : root.theme.bgSurface
                                    border.color: modelData.role === "user"
                                        ? Qt.rgba(root.theme.accentPrimary.r,
                                                  root.theme.accentPrimary.g,
                                                  root.theme.accentPrimary.b, 0.3)
                                        : root.theme.border
                                    border.width: 1
                                    radius: 8

                                    Text {
                                        id: msgText
                                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                                        text: modelData.content || (root.isLoading && modelData.role === "assistant" ? "▋" : "")
                                        color: root.theme.textPrimary
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 12
                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                        textFormat: Text.PlainText
                                    }
                                }
                            }
                        }

                        // Auto-scroll to bottom
                        onHeightChanged: {
                            scrollView.ScrollBar.vertical.position = 1.0 - scrollView.ScrollBar.vertical.size
                        }
                    }
                }

                // Loading indicator
                Rectangle {
                    visible: root.isLoading
                    Layout.fillWidth: true
                    height: 2
                    color: "transparent"
                    Rectangle {
                        width: parent.width * 0.4
                        height: 2
                        color: root.theme.accentPrimary
                        radius: 1
                        SequentialAnimation on x {
                            loops: Animation.Infinite
                            NumberAnimation { to: parent.parent.width * 0.6; duration: 800; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 0; duration: 800; easing.type: Easing.InOutQuad }
                        }
                    }
                }

                // ── Input area ────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        height: Math.min(inputField.implicitHeight + 16, 120)
                        color: root.theme.bgSurface
                        border.color: inputField.activeFocus ? root.theme.accentPrimary : root.theme.border
                        border.width: 1
                        radius: 8

                        TextArea {
                            id: inputField
                            anchors { fill: parent; margins: 8 }
                            color: root.theme.textPrimary
                            font.family: root.theme.fontFamily
                            font.pixelSize: 12
                            placeholderText: "Ask anything... (Enter to send)"
                            placeholderTextColor: root.theme.textMuted
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            background: Item {}
                            Keys.onReturnPressed: function(e) {
                                if (e.modifiers & Qt.ShiftModifier) {
                                    insert(cursorPosition, "\n")
                                } else {
                                    root.sendMessage(text)
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 36; height: 36
                        color: sendArea.containsMouse ? root.theme.accentPrimary : Qt.rgba(
                            root.theme.accentPrimary.r,
                            root.theme.accentPrimary.g,
                            root.theme.accentPrimary.b, 0.3)
                        border.color: root.theme.accentPrimary
                        border.width: 1
                        radius: 8
                        opacity: root.isLoading ? 0.5 : 1.0

                        Text {
                            anchors.centerIn: parent
                            text: root.isLoading ? "󰔟" : "󰒊"
                            color: root.theme.textPrimary
                            font.family: root.theme.fontFamily
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: sendArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sendMessage(inputField.text)
                        }
                    }
                }
            }
        }
    }
}
