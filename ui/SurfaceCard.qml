import QtQuick 2.15
import QtQuick.Layouts 1.15

// A predictable, content-sized surface for settings and result sections.
// The default property routes card children into one shared ColumnLayout.
Item {
    id: root

    property var theme
    property bool mobile: false
    property color surfaceColor: theme ? theme.canvas : "#ffffff"
    property color strokeColor: theme ? theme.hairline : "#d9d9dd"
    property int horizontalPadding: mobile
                                    ? (theme ? theme.cardPaddingMobile : 16)
                                    : (theme ? theme.cardPaddingDesktop : 24)
    property int verticalPadding: horizontalPadding

    default property alias contentData: contentColumn.data

    Layout.fillWidth: true
    Layout.minimumWidth: 0
    implicitHeight: contentColumn.implicitHeight + root.verticalPadding * 2

    Rectangle {
        anchors.fill: parent
        color: root.surfaceColor
        border.color: root.strokeColor
        border.width: root.strokeColor.a > 0 ? 1 : 0
        radius: root.theme ? root.theme.radiusPanel : 12
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        anchors.topMargin: root.verticalPadding
        anchors.bottomMargin: root.verticalPadding
        spacing: root.theme ? root.theme.space8 : 8
    }
}
