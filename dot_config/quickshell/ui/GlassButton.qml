import QtQuick

Item {
    id: root
    required property var theme
    property string label: ""
    property bool primary: true
    signal clicked()

    implicitHeight: 28
    implicitWidth: textItem.implicitWidth + 20

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.theme.radiusPill
        color: area.pressed ? root.theme.bgBase : root.theme.surfaceGlass
        border.width: 1
        border.color: root.primary ? root.theme.borderGlass : root.theme.border
    }

    Text {
        id: textItem
        anchors.centerIn: parent
        text: root.label
        color: root.theme.textPrimary
        font.pixelSize: 11
        font.family: root.theme.fontFamily
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

