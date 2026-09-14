import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property var backend
    property var theme
    property bool compact: false
    property string modeLabel: "Весь поток"

    implicitHeight: compact ? 342 : 478

    Rectangle {
        anchors.fill: parent
        color: root.theme.softStone
        radius: root.theme.radiusPanel

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: root.compact ? 18 : 22
            anchors.rightMargin: root.compact ? 18 : 22
            anchors.topMargin: root.compact ? 18 : 22
            anchors.bottomMargin: root.compact ? 16 : 20
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Результаты анализа"
                    color: root.theme.deepGreen
                    font.family: root.theme.sansFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.modeLabel
                    color: root.theme.slate
                    font.family: root.theme.monoFont
                    font.pixelSize: 9
                    elide: Text.ElideLeft
                }
            }

            Text {
                Layout.topMargin: 22
                text: "Всего прошло"
                color: root.theme.slate
                font.family: root.theme.sansFont
                font.pixelSize: 13
            }

            Text {
                id: totalNumber
                Layout.topMargin: -3
                text: Math.round(animatedTotal).toString()
                color: root.theme.ink
                font.family: root.theme.sansFont
                font.pixelSize: root.compact ? 54 : 62
                font.weight: Font.Normal
                property real animatedTotal: root.backend.totalCount
                Behavior on animatedTotal { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 12
                Layout.bottomMargin: 0
                color: root.theme.hairline
            }

            MetricRow {
                theme: root.theme
                label: "Легковые автомобили"
                value: root.backend.carsCount
                markerColor: root.theme.deepGreen
            }
            MetricRow {
                theme: root.theme
                label: "Двухколёсные"
                value: root.backend.twoWheelersCount
                markerColor: root.theme.coral
            }
            MetricRow {
                theme: root.theme
                label: "Тяжёлый транспорт"
                value: root.backend.heavyCount
                markerColor: root.theme.actionBlue
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: root.backend.running ? "Счётчик обновляется по мере пересечения FINISH." : "Учитываются уникальные треки, прошедшие START и FINISH."
                color: root.theme.slate
                font.family: root.theme.sansFont
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }
        }
    }
}
