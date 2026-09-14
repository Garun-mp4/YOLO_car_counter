import QtQuick 2.15
import QtQuick.Controls 6.5
import QtQuick.Layouts 1.15

Button {
    id: control

    property var theme
    property bool active: false
    property bool compact: false
    property string indexLabel: "01"

    implicitHeight: 40
    Layout.minimumWidth: compact ? 40 : 136
    hoverEnabled: true
    padding: 0
    leftPadding: compact ? 4 : 12
    rightPadding: compact ? 4 : 12
    Accessible.name: control.text

    contentItem: RowLayout {
        spacing: 10
        Text {
            text: control.indexLabel
            color: control.active ? control.theme.deepGreen : control.theme.muted
            font.family: control.theme.monoFont
            font.pixelSize: 10
            font.weight: Font.DemiBold
            visible: !control.compact
        }
        Text {
            Layout.fillWidth: true
            text: control.text
            color: control.active ? control.theme.deepGreen : control.theme.ink
            font.family: control.theme.sansFont
            font.pixelSize: 13
            font.weight: control.active ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
            horizontalAlignment: control.compact ? Text.AlignHCenter : Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }
    }

    background: Rectangle {
        radius: control.theme.radiusSmall
        color: control.active ? control.theme.paleGreen : (control.hovered ? "#f7f8f7" : "transparent")
        border.color: control.activeFocus ? control.theme.focusBlue : "transparent"
        border.width: control.activeFocus ? 2 : 0

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: control.active ? 3 : 0
            color: control.theme.deepGreen
            radius: 2
        }
    }
}
