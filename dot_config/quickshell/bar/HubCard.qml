import QtQuick
import QtQuick.Layouts

// Premium hub card: title + description + optional actions / path rows / wallpaper grid.
// Emits run(cmd) when user triggers an action; parent wires to hubLauncher and closes hub.
Item {
    id: root
    required property var theme
    property string title: ""
    property string description: ""
    property var actions: []       // [ { label, icon, command } ]
    property var pathRows: []      // [ { path, label } ] — path can be ~/dev etc
    property var wallpaperNames: []
    property string home: ""
    property string phosphorDir: ""
    signal run(var cmd)

    implicitWidth: card.width
    implicitHeight: cardColumn.implicitHeight + 24

    Rectangle {
        id: card
        width: parent.width
        height: cardColumn.implicitHeight + 20
        radius: root.theme.radiusModal
        color: root.theme.bgBase
        border.width: 1
        border.color: root.theme.border

        Column {
            id: cardColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 10

            Text {
                text: root.title
                color: root.theme.logoPurple
                font.pixelSize: 12
                font.family: root.theme.fontFamily
                font.weight: Font.DemiBold
            }
            Text {
                text: root.description
                color: root.theme.textMuted
                font.pixelSize: 10
                font.family: root.theme.fontFamily
                wrapMode: Text.WordWrap
                width: card.width - 24
            }

            // Actions list
            Repeater {
                model: Array.isArray(root.actions) ? root.actions : []
                delegate: MouseArea {
                    required property var modelData
                    width: card.width - 24
                    height: 32
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.run(modelData.command)
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 6
                        color: actionHover.containsMouse ? root.theme.accentDim2 : "transparent"
                    }
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        spacing: 8
                        Image {
                            width: 14
                            height: 14
                            source: root.phosphorDir ? (root.phosphorDir + "/" + (modelData.icon || "gear") + ".svg") : ""
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.label
                            color: root.theme.textPrimary
                            font.pixelSize: 11
                            font.family: root.theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: actionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                    }
                }
            }

            // Path rows: ~/dev, ~/.config, ~/assets — Yazi + Terminal
            Repeater {
                model: Array.isArray(root.pathRows) ? root.pathRows : []
                delegate: Item {
                    required property var modelData
                    width: card.width - 24
                    height: 36
                    property string resolvedPath: (root.home && modelData.path) ? modelData.path.replace("~", root.home) : ""
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Text {
                            text: (modelData.label || modelData.path) + ":"
                            color: root.theme.textMuted
                            font.pixelSize: 10
                            font.family: root.theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: yaziTxt.width + 16
                            height: 26
                            radius: 6
                            color: yaziMa.containsMouse ? root.theme.accentDim2 : root.theme.border
                            MouseArea {
                                id: yaziMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.run(["ghostty", "-e", "yazi", parent.parent.parent.resolvedPath])
                            }
                            Text {
                                id: yaziTxt
                                anchors.centerIn: parent
                                text: "Yazi"
                                font.pixelSize: 10
                                font.family: root.theme.fontFamily
                                color: root.theme.textPrimary
                            }
                        }
                        Rectangle {
                            width: termTxt.width + 16
                            height: 26
                            radius: 6
                            color: termMa.containsMouse ? root.theme.accentDim2 : root.theme.border
                            MouseArea {
                                id: termMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.run(["ghostty", "-e", "bash", "-c", "cd " + parent.parent.parent.resolvedPath + " && exec ~/.config/hypr/scripts/zellij-branded.sh"])
                            }
                            Text {
                                id: termTxt
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

            // Wallpapers: grid of Set XX + Open folder + Waypaper GUI
            Flow {
                visible: Array.isArray(root.wallpaperNames) && root.wallpaperNames.length > 0
                width: card.width - 24
                spacing: 6
                Repeater {
                    model: root.wallpaperNames || []
                    delegate: Rectangle {
                        required property string modelData
                        width: setTxt.width + 16
                        height: 26
                        radius: 6
                        color: setMa.containsMouse ? root.theme.accentDim2 : root.theme.border
                        MouseArea {
                            id: setMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.run(["waypaper", "--wallpaper", root.home + "/assets/wallpapers/" + modelData, "--fill", "fill", "--monitor", "All", "--backend", "swaybg"])
                        }
                        Text {
                            id: setTxt
                            anchors.centerIn: parent
                            text: "Set " + modelData.replace(".png", "")
                            font.pixelSize: 10
                            font.family: root.theme.fontFamily
                            color: root.theme.textPrimary
                        }
                    }
                }
            }
            Row {
                visible: Array.isArray(root.wallpaperNames) && root.wallpaperNames.length > 0
                spacing: 8
                Rectangle {
                    width: openTxt.width + 16
                    height: 26
                    radius: 6
                    color: openMa.containsMouse ? root.theme.accentDim2 : root.theme.border
                    MouseArea {
                        id: openMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.run(["ghostty", "-e", "yazi", root.home + "/assets/wallpapers"])
                    }
                    Text {
                        id: openTxt
                        anchors.centerIn: parent
                        text: "Open folder"
                        font.pixelSize: 10
                        font.family: root.theme.fontFamily
                        color: root.theme.textPrimary
                    }
                }
                Rectangle {
                    width: wpTxt.width + 16
                    height: 26
                    radius: 6
                    color: wpMa.containsMouse ? root.theme.accentDim2 : root.theme.border
                    MouseArea {
                        id: wpMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.run(["waypaper"])
                    }
                    Text {
                        id: wpTxt
                        anchors.centerIn: parent
                        text: "Waypaper GUI"
                        font.pixelSize: 10
                        font.family: root.theme.fontFamily
                        color: root.theme.textPrimary
                    }
                }
            }
        }
    }
}
