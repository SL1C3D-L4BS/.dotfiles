import QtQuick

// 2026-style action row: icon + label + optional subtitle, hover, click
Item {
    id: root
    required property var theme
    property string phosphorDir: ""
    property string labelText: ""
    property string subText: ""
    property string iconName: "gear"
    signal clicked()

    width: parent ? parent.width : 200
    implicitHeight: subText ? 40 : 36

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: root.theme.radiusPill
            color: parent.containsMouse ? root.theme.accentDim2 : "transparent"
            opacity: parent.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: root.theme.motionFastMs } }
        }
        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10
            Image {
                width: 16
                height: 16
                source: (root.phosphorDir && root.iconName) ? (root.phosphorDir + "/" + root.iconName + ".svg") : ""
                fillMode: Image.PreserveAspectFit
                anchors.verticalCenter: parent.verticalCenter
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                Text {
                    text: root.labelText
                    color: root.theme.textPrimary
                    font.pixelSize: 11
                    font.family: root.theme.fontFamily
                }
                Text {
                    visible: root.subText !== ""
                    text: root.subText
                    color: root.theme.textMuted
                    font.pixelSize: 9
                    font.family: root.theme.fontFamily
                }
            }
            Item { width: 1; height: 1 }
        }
    }
}
