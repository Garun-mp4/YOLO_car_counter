import QtQuick 2.15
import QtQuick.Controls 6.5

Button {
    id: control

    property var theme
    property bool active: false

    implicitHeight: 34
    implicitWidth: 104
    hoverEnabled: true
    padding: 0
    leftPadding: 12
    rightPadding: 12
    Accessible.name: control.text

    contentItem: Text {
        text: control.text
        color: control.active ? "#ffffff" : control.theme.ink
        font.family: control.theme.sansFont
        font.pixelSize: 12
        font.weight: control.active ? Font.DemiBold : Font.Normal
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: control.theme.radiusPill
        color: control.active ? control.theme.deepGreen : (control.hovered ? control.theme.paleGreen : control.theme.canvas)
        border.color: control.activeFocus ? control.theme.focusBlue : (control.active ? control.theme.deepGreen : control.theme.hairline)
        border.width: control.activeFocus ? 2 : 1
        opacity: control.enabled ? 1.0 : 0.48
    }
}
