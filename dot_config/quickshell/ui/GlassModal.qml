import QtQuick

Item {
    id: root
    required property var theme

    // Controls visibility from parent PopupWindow or overlay
    property bool open: false

    // Content item is placed inside the card
    default property alias content: contentSlot.data

    anchors.fill: parent
    visible: open

    Rectangle {
        anchors.fill: parent
        color: root.theme.scrim
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.theme.motionBaseMs } }
    }

    GlassSurface {
        id: card
        theme: root.theme
        strong: false

        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 420)
        height: Math.min(parent.height - 40, 520)

        scale: root.open ? 1 : 0.98
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.theme.motionBaseMs } }
        Behavior on scale { NumberAnimation { duration: root.theme.motionBaseMs } }

        Item {
            id: contentSlot
            anchors.fill: parent
            anchors.margins: root.theme.spacingLg
        }
    }
}

