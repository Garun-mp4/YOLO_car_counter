import QtQuick 2.15
import QtQuick.Controls 6.5
import QtQuick.Layouts 1.15

Button {
    id: control

    property var theme
    property bool active: false

    implicitHeight: 34
    implicitWidth: Math.max(
        104,
        Math.ceil(labelMetrics.advanceWidth + leftPadding + rightPadding + 2)
    )
    Layout.minimumWidth: implicitWidth
    Layout.preferredWidth: implicitWidth
    hoverEnabled: true
    padding: 0
    leftPadding: 16
    rightPadding: 16
    Accessible.name: control.text

    TextMetrics {
        id: labelMetrics
        text: control.text
        font.family: control.theme ? control.theme.sansFont : "Segoe UI"
        font.pixelSize: 12
        font.weight: control.active ? Font.DemiBold : Font.Normal
    }

    contentItem: Text {
        text: control.text
        color: control.active ? "#ffffff" : control.theme.ink
        font.family: control.theme.sansFont
        font.pixelSize: 12
        font.weight: control.active ? Font.DemiBold : Font.Normal
        wrapMode: Text.NoWrap
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
