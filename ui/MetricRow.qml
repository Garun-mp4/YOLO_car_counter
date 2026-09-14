import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property var theme
    property string label: ""
    property int value: 0
    property color markerColor: "#003c33"

    implicitHeight: 50
    Layout.fillWidth: true

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 3
            Layout.preferredHeight: 18
            radius: 2
            color: root.markerColor
        }

        Text {
            Layout.fillWidth: true
            text: root.label
            color: root.theme.ink
            font.family: root.theme.sansFont
            font.pixelSize: 13
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text: root.value
            color: root.theme.ink
            font.family: root.theme.monoFont
            font.pixelSize: 18
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: root.theme.hairline
    }
}
