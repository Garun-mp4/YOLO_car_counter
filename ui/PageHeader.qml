import QtQuick 2.15
import QtQuick.Layouts 1.15

// Shared page heading.  It owns the page inset and vertical rhythm so the
// three application tabs cannot drift apart as the UI evolves.
Item {
    id: root

    property var theme
    property bool mobile: false
    property string title: ""
    property string subtitle: ""
    property int horizontalInset: mobile
                                    ? (theme ? theme.pageInsetMobile : 16)
                                    : (theme ? theme.pageInsetDesktop : 32)
    property int topInset: theme ? theme.pageTopInset : 24
    property int bottomInset: theme ? theme.space16 : 16

    Layout.fillWidth: true
    implicitHeight: headerLayout.implicitHeight + root.topInset + root.bottomInset

    ColumnLayout {
        id: headerLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.horizontalInset
        anchors.rightMargin: root.horizontalInset
        anchors.topMargin: root.topInset
        spacing: root.theme ? root.theme.space8 : 8

        Text {
            Layout.fillWidth: true
            text: root.title
            color: root.theme ? root.theme.ink : "#17171c"
            font.family: root.theme ? root.theme.sansFont : "Segoe UI"
            font.pixelSize: root.mobile ? 27 : 32
            font.weight: Font.Normal
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: root.subtitle
            color: root.theme ? root.theme.slate : "#75758a"
            font.family: root.theme ? root.theme.sansFont : "Segoe UI"
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }
    }
}
