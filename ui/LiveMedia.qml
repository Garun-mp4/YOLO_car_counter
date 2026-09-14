import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property var backend
    property var theme
    property bool compact: false

    implicitHeight: compact ? 258 : 478
    Accessible.name: "Кадр видео с разметкой YOLO"

    Rectangle {
        id: mediaFrame
        anchors.fill: parent
        color: root.theme.deepNavy
        radius: root.theme.radiusMedia
        clip: true

        Image {
            anchors.fill: parent
            source: root.backend.hasFrame ? "image://frames/live?revision=" + root.backend.frameRevision : ""
            fillMode: Image.PreserveAspectFit
            cache: false
            asynchronous: true
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: root.compact ? 16 : 20
            anchors.rightMargin: root.compact ? 16 : 20
            anchors.topMargin: root.compact ? 14 : 18
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "КАДР АНАЛИЗА"
                    color: "#d7e5e2"
                    font.family: root.theme.monoFont
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.9
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "YOLO26N  ·  TRACKING"
                    color: "#8faeab"
                    font.family: root.theme.monoFont
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignRight
                }
            }

            Text {
                Layout.fillWidth: true
                text: "START " + Math.round(root.backend.startLinePercent) + "%   ·   FINISH " + Math.round(root.backend.finishLinePercent) + "%"
                color: "#8faeab"
                font.family: root.theme.monoFont
                font.pixelSize: 8
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8
            visible: !root.backend.hasFrame

            Text {
                text: root.backend.running ? "Подготавливаем кадр…" : "Видео появится здесь после запуска"
                color: "#eef5f3"
                font.family: root.theme.sansFont
                font.pixelSize: root.compact ? 14 : 16
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                text: root.backend.running ? "Поток обрабатывается в фоне" : "Выберите источник и начните анализ"
                color: "#8faeab"
                font.family: root.theme.sansFont
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: root.compact ? 16 : 20
            anchors.rightMargin: root.compact ? 16 : 20
            anchors.bottomMargin: root.compact ? 14 : 18
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.backend.statusText
                    color: "#d7e5e2"
                    font.family: root.theme.sansFont
                    font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.backend.progressText
                    color: "#a9c5c3"
                    font.family: root.theme.monoFont
                    font.pixelSize: 9
                    elide: Text.ElideLeft
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 2
                color: "#2d4654"
                Rectangle {
                    width: parent.width * root.backend.progress
                    height: parent.height
                    color: root.theme.coral
                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
