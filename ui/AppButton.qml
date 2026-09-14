import QtQuick 2.15
import QtQuick.Controls 6.5

Button {
    id: control

    property var theme
    property string variant: "secondary" // primary, secondary, text, danger
    property bool compact: false

    implicitHeight: compact ? 34 : 38
    implicitWidth: compact ? 104 : 132
    hoverEnabled: true
    padding: 0
    leftPadding: compact ? 13 : 16
    rightPadding: compact ? 13 : 16
    Accessible.name: control.text

    contentItem: Text {
        text: control.text
        color: {
            if (!control.enabled)
                return control.variant === "primary" ? "#ffffff" : control.theme.muted
            if (control.variant === "primary")
                return "#ffffff"
            if (control.variant === "danger")
                return control.theme.errorRed
            if (control.variant === "text")
                return control.theme.actionBlue
            return control.theme.ink
        }
        font.family: control.theme.sansFont
        font.pixelSize: control.compact ? 12 : 13
        font.weight: Font.DemiBold
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: control.variant === "primary" ? control.height / 2 : control.theme.radiusSmall
        color: {
            if (!control.enabled)
                return control.variant === "primary" ? control.theme.deepGreen : control.theme.canvas
            if (control.variant === "primary")
                return control.pressed ? "#002f29" : control.theme.deepGreen
            if (control.variant === "danger")
                return control.hovered ? control.theme.errorSoft : control.theme.canvas
            if (control.variant === "text")
                return control.hovered ? control.theme.paleBlue : "transparent"
            return control.pressed ? control.theme.paleGreen : (control.hovered ? control.theme.paleBlue : control.theme.canvas)
        }
        border.color: {
            if (control.activeFocus)
                return control.theme.focusBlue
            if (control.variant === "primary")
                return control.theme.deepGreen
            if (control.variant === "danger")
                return control.theme.errorRed
            if (control.variant === "text")
                return "transparent"
            return control.hovered ? control.theme.actionBlue : control.theme.hairline
        }
        border.width: control.activeFocus ? 2 : (control.variant === "text" ? 0 : 1)
        opacity: control.enabled ? 1.0 : 0.48
    }
}
