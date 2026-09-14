import QtQuick 2.15
import QtQuick.Controls 6.5
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: app
    visible: true
    width: 1440
    height: 920
    minimumWidth: 360
    minimumHeight: 600
    title: "YOLO Car Counter"
    color: canvas

    property int currentPage: 0
    property bool mobile: width < 720
    property bool tablet: width >= 720 && width < 1120
    property var backendObject: appController
    property string sansFont: "Segoe UI"
    property string monoFont: "Cascadia Mono"

    // Adapted from Design-system/DESIGN-cohere.md for an operator-style desktop tool.
    property color canvas: "#ffffff"
    property color ink: "#17171c"
    property color deepGreen: "#003c33"
    property color deepNavy: "#071829"
    property color stone: "#eeece7"
    property color paleGreen: "#edfce9"
    property color paleBlue: "#f1f5ff"
    property color hairline: "#d9d9dd"
    property color border: "#e5e7eb"
    property color muted: "#93939f"
    property color slate: "#75758a"
    property color actionBlue: "#1863dc"
    property color coral: "#ff7759"
    property color errorRed: "#b30000"
    property color errorSoft: "#fff0ed"

    property var modeItems: [
        { key: "all", label: "Весь поток", tag: "ALL TRAFFIC" },
        { key: "cars", label: "Легковые", tag: "PASSENGER CARS" },
        { key: "two_wheelers", label: "Двухколёсные", tag: "TWO-WHEELERS" },
        { key: "heavy", label: "Тяжёлый транспорт", tag: "HEAVY TRANSPORT" }
    ]

    function compactPath(path) {
        if (!path || path.length < 64)
            return path
        return path.slice(0, 28) + "…" + path.slice(-30)
    }

    function pageTitle() {
        if (currentPage === 1)
            return "Настройки"
        if (currentPage === 2)
            return "Результаты"
        return "Наблюдение"
    }

    function pageKicker() {
        if (currentPage === 1)
            return "CONFIGURATION / 02"
        if (currentPage === 2)
            return "LAST RUN / 03"
        return "LIVE ANALYSIS / 01"
    }

    function navTextColor(active) {
        return active ? canvas : ink
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: sideRail
            visible: !app.mobile
            Layout.fillHeight: true
            Layout.preferredWidth: app.tablet ? 82 : 232
            color: app.canvas
            border.color: app.hairline
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: app.tablet ? 12 : 20
                spacing: 0

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Text {
                        text: "TRAFFIC"
                        color: app.deepGreen
                        font.family: app.monoFont
                        font.pixelSize: app.tablet ? 13 : 15
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.8
                    }

                    Text {
                        text: "COUNTER"
                        color: app.ink
                        font.family: app.sansFont
                        font.pixelSize: app.tablet ? 19 : 25
                        font.weight: Font.DemiBold
                        visible: !app.tablet
                    }

                    Text {
                        text: "VISION ANALYTICS"
                        color: app.muted
                        font.family: app.monoFont
                        font.pixelSize: 9
                        font.letterSpacing: 1.1
                        visible: !app.tablet
                    }
                }

                Item { Layout.fillHeight: true }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Button {
                        id: observeNav
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        text: "01   Наблюдение"
                        hoverEnabled: true
                        onClicked: app.currentPage = 0
                        contentItem: Text {
                            text: observeNav.text
                            color: app.navTextColor(app.currentPage === 0)
                            font.family: app.monoFont
                            font.pixelSize: app.tablet ? 0 : 11
                            font.weight: Font.DemiBold
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: app.tablet ? 0 : 15
                            horizontalAlignment: app.tablet ? Text.AlignHCenter : Text.AlignLeft
                        }
                        background: Rectangle {
                            radius: 12
                            color: app.currentPage === 0 ? app.deepGreen : (observeNav.hovered ? app.paleGreen : "transparent")
                            border.color: app.currentPage === 0 ? app.deepGreen : app.border
                            border.width: app.currentPage === 0 ? 0 : 1
                        }
                    }

                    Button {
                        id: settingsNav
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        text: "02   Настройки"
                        hoverEnabled: true
                        onClicked: app.currentPage = 1
                        contentItem: Text {
                            text: settingsNav.text
                            color: app.navTextColor(app.currentPage === 1)
                            font.family: app.monoFont
                            font.pixelSize: app.tablet ? 0 : 11
                            font.weight: Font.DemiBold
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: app.tablet ? 0 : 15
                            horizontalAlignment: app.tablet ? Text.AlignHCenter : Text.AlignLeft
                        }
                        background: Rectangle {
                            radius: 12
                            color: app.currentPage === 1 ? app.deepGreen : (settingsNav.hovered ? app.paleGreen : "transparent")
                            border.color: app.currentPage === 1 ? app.deepGreen : app.border
                            border.width: app.currentPage === 1 ? 0 : 1
                        }
                    }

                    Button {
                        id: historyNav
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        text: "03   Результаты"
                        hoverEnabled: true
                        onClicked: app.currentPage = 2
                        contentItem: Text {
                            text: historyNav.text
                            color: app.navTextColor(app.currentPage === 2)
                            font.family: app.monoFont
                            font.pixelSize: app.tablet ? 0 : 11
                            font.weight: Font.DemiBold
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: app.tablet ? 0 : 15
                            horizontalAlignment: app.tablet ? Text.AlignHCenter : Text.AlignLeft
                        }
                        background: Rectangle {
                            radius: 12
                            color: app.currentPage === 2 ? app.deepGreen : (historyNav.hovered ? app.paleGreen : "transparent")
                            border.color: app.currentPage === 2 ? app.deepGreen : app.border
                            border.width: app.currentPage === 2 ? 0 : 1
                        }
                    }
                }

                Item { Layout.preferredHeight: 28 }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: !app.tablet

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: app.hairline
                    }

                    Text {
                        text: "YOLO26N  /  BYTE TRACK"
                        color: app.muted
                        font.family: app.monoFont
                        font.pixelSize: 9
                        font.letterSpacing: 0.6
                    }
                    Text {
                        text: "AGTU · AI SYSTEMS"
                        color: app.muted
                        font.family: app.monoFont
                        font.pixelSize: 9
                        font.letterSpacing: 0.6
                    }
                }
            }
        }

        ColumnLayout {
            id: mainColumn
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                id: topBar
                Layout.fillWidth: true
                Layout.preferredHeight: app.mobile ? 72 : 80
                color: app.canvas
                border.color: app.hairline
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: app.mobile ? 18 : 30
                    anchors.rightMargin: app.mobile ? 18 : 30
                    spacing: 16

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: app.pageKicker()
                            color: app.muted
                            font.family: app.monoFont
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.1
                        }
                        Text {
                            text: app.pageTitle()
                            color: app.ink
                            font.family: app.sansFont
                            font.pixelSize: app.mobile ? 20 : 23
                            font.weight: Font.DemiBold
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: app.mobile ? 118 : 146
                        Layout.preferredHeight: 34
                        radius: 17
                        color: app.backendObject.running ? app.paleGreen : (app.backendObject.statusText === "ОШИБКА" ? app.errorSoft : app.stone)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8
                            Rectangle {
                                Layout.preferredWidth: 7
                                Layout.preferredHeight: 7
                                radius: 4
                                color: app.backendObject.running ? app.deepGreen : (app.backendObject.statusText === "ОШИБКА" ? app.errorRed : app.slate)
                                SequentialAnimation on opacity {
                                    running: app.backendObject.running
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 1.0; to: 0.25; duration: 850 }
                                    NumberAnimation { from: 0.25; to: 1.0; duration: 850 }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: app.backendObject.statusText
                                color: app.ink
                                font.family: app.monoFont
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            StackLayout {
                id: pages
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: app.currentPage

                ScrollView {
                    id: dashboardScroll
                    clip: true
                    contentWidth: width
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        id: dashboardContent
                        width: dashboardScroll.width
                        spacing: 0

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: app.mobile ? 244 : 174

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: app.mobile ? 20 : 38
                                anchors.rightMargin: app.mobile ? 20 : 38
                                anchors.topMargin: app.mobile ? 28 : 36
                                anchors.bottomMargin: 22
                                spacing: 10

                                Text {
                                    text: "YOLO26N / VEHICLE ANALYTICS"
                                    color: app.deepGreen
                                    font.family: app.monoFont
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 1.2
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: app.mobile ? "Наблюдайте за потоком в движении." : "Наблюдайте за потоком в движении — кадр за кадром."
                                    color: app.ink
                                    font.family: app.sansFont
                                    font.pixelSize: app.mobile ? 28 : (app.tablet ? 33 : 39)
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Выберите видео, режим и две контрольные линии. Система покажет треки и итоговый проход транспорта в реальном времени."
                                    color: app.slate
                                    font.family: app.sansFont
                                    font.pixelSize: 14
                                    lineHeight: 1.15
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Flow {
                            id: modeFlow
                            Layout.fillWidth: true
                            Layout.leftMargin: app.mobile ? 20 : 38
                            Layout.rightMargin: app.mobile ? 20 : 38
                            Layout.preferredHeight: implicitHeight
                            spacing: 8

                            Repeater {
                                model: app.modeItems
                                delegate: Button {
                                    id: modeButton
                                    width: app.mobile ? (modeFlow.width - modeFlow.spacing) / 2 : 194
                                    height: 48
                                    text: modelData.label
                                    hoverEnabled: true
                                    enabled: !app.backendObject.running
                                    onClicked: app.backendObject.selectMode(modelData.key)
                                    contentItem: ColumnLayout {
                                        spacing: 2
                                        Text {
                                            Layout.fillWidth: true
                                            text: modeButton.text
                                            color: app.backendObject.selectedMode === modelData.key ? app.canvas : app.ink
                                            font.family: app.sansFont
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.tag
                                            color: app.backendObject.selectedMode === modelData.key ? "#c3e5dc" : app.muted
                                            font.family: app.monoFont
                                            font.pixelSize: 8
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                        }
                                    }
                                    background: Rectangle {
                                        radius: 24
                                        color: app.backendObject.selectedMode === modelData.key ? app.deepGreen : (modeButton.hovered ? app.paleGreen : app.canvas)
                                        border.color: app.backendObject.selectedMode === modelData.key ? app.deepGreen : app.border
                                        border.width: 1
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: app.mobile ? 20 : 38
                            Layout.rightMargin: app.mobile ? 20 : 38
                            Layout.topMargin: 18
                            Layout.bottomMargin: 22
                            spacing: 10

                            Button {
                                id: chooseVideoButton
                                Layout.preferredWidth: app.mobile ? 142 : 158
                                Layout.preferredHeight: 42
                                text: "Открыть видео"
                                hoverEnabled: true
                                enabled: !app.backendObject.running
                                onClicked: app.backendObject.chooseVideo()
                                contentItem: Text {
                                    text: chooseVideoButton.text
                                    color: app.actionBlue
                                    font.family: app.sansFont
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 21
                                    color: chooseVideoButton.hovered ? app.paleBlue : app.canvas
                                    border.color: app.actionBlue
                                    border.width: 1
                                }
                            }

                            Button {
                                id: runButton
                                Layout.preferredWidth: app.mobile ? 142 : 158
                                Layout.preferredHeight: 42
                                text: app.backendObject.running ? "Анализ идёт" : "Запустить анализ"
                                hoverEnabled: true
                                enabled: !app.backendObject.running
                                onClicked: app.backendObject.startAnalysis()
                                contentItem: Text {
                                    text: runButton.text
                                    color: app.canvas
                                    font.family: app.sansFont
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 21
                                    color: runButton.hovered ? "#075448" : app.deepGreen
                                }
                            }

                            Button {
                                id: stopButton
                                Layout.preferredWidth: 104
                                Layout.preferredHeight: 42
                                text: "Остановить"
                                hoverEnabled: true
                                enabled: app.backendObject.running
                                visible: !app.mobile || app.backendObject.running
                                onClicked: app.backendObject.stopAnalysis()
                                contentItem: Text {
                                    text: stopButton.text
                                    color: stopButton.enabled ? app.ink : app.muted
                                    font.family: app.sansFont
                                    font.pixelSize: 13
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 21
                                    color: stopButton.enabled && stopButton.hovered ? app.stone : "transparent"
                                    border.color: stopButton.enabled ? app.hairline : app.border
                                    border.width: 1
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                Layout.fillWidth: true
                                text: app.compactPath(app.backendObject.videoPath)
                                color: app.muted
                                font.family: app.monoFont
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideMiddle
                                visible: !app.mobile
                            }
                        }

                        GridLayout {
                            id: workGrid
                            Layout.fillWidth: true
                            Layout.leftMargin: app.mobile ? 20 : 38
                            Layout.rightMargin: app.mobile ? 20 : 38
                            columns: app.mobile || app.tablet ? 1 : 2
                            columnSpacing: 16
                            rowSpacing: 16

                            Rectangle {
                                id: videoPanel
                                Layout.fillWidth: true
                                Layout.minimumHeight: app.mobile ? 332 : 480
                                Layout.preferredHeight: app.mobile ? 350 : 500
                                color: app.deepNavy
                                radius: 22

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: app.mobile ? 14 : 20
                                    spacing: 12

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "LIVE / ANNOTATED FRAME"
                                            color: "#a9c5c3"
                                            font.family: app.monoFont
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 0.8
                                        }
                                        Item { Layout.fillWidth: true }
                                        Rectangle {
                                            Layout.preferredWidth: 68
                                            Layout.preferredHeight: 24
                                            radius: 12
                                            color: "#123248"
                                            Text {
                                                anchors.centerIn: parent
                                                text: "YOLO26N"
                                                color: "#d4e8e4"
                                                font.family: app.monoFont
                                                font.pixelSize: 8
                                            }
                                        }
                                    }

                                    Item {
                                        id: previewFrame
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.minimumHeight: app.mobile ? 230 : 350
                                        clip: true

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 14
                                            color: "#0d2537"
                                        }

                                        Image {
                                            anchors.fill: parent
                                            source: app.backendObject.hasFrame ? "image://frames/live?revision=" + app.backendObject.frameRevision : ""
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            cache: false
                                        }

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.margins: 12
                                            width: 128
                                            height: 28
                                            radius: 14
                                            color: "#b8071829"
                                            visible: app.backendObject.hasFrame
                                            Text {
                                                anchors.centerIn: parent
                                                text: "START  →  FINISH"
                                                color: "#f5fbfa"
                                                font.family: app.monoFont
                                                font.pixelSize: 8
                                                font.weight: Font.DemiBold
                                            }
                                        }

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 8
                                            visible: !app.backendObject.hasFrame
                                            Text {
                                                text: app.backendObject.running ? "Подключаем кадр…" : "Видео появится здесь после запуска"
                                                color: "#d7e5e2"
                                                font.family: app.sansFont
                                                font.pixelSize: app.mobile ? 14 : 16
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                            Text {
                                                text: app.backendObject.running ? "YOLO / BYTETRACK" : "Настройте режим и нажмите «Запустить анализ»"
                                                color: "#8faeab"
                                                font.family: app.monoFont
                                                font.pixelSize: 9
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 4
                                            radius: 2
                                            color: "#274050"
                                            clip: true
                                            Rectangle {
                                                width: parent.width * app.backendObject.progress
                                                height: parent.height
                                                radius: 2
                                                color: app.coral
                                                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                            }
                                        }
                                        Text {
                                            Layout.preferredWidth: 126
                                            text: app.backendObject.progressText
                                            color: "#a9c5c3"
                                            font.family: app.monoFont
                                            font.pixelSize: 9
                                            horizontalAlignment: Text.AlignRight
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: summaryPanel
                                Layout.fillWidth: true
                                Layout.minimumHeight: app.mobile ? 360 : 480
                                Layout.preferredHeight: app.mobile ? 382 : 500
                                color: app.stone
                                radius: 22

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: app.mobile ? 20 : 24
                                    spacing: 0

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "ПОДСЧЁТ"
                                            color: app.deepGreen
                                            font.family: app.monoFont
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 1.0
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: app.backendObject.selectedMode.toUpperCase()
                                            color: app.slate
                                            font.family: app.monoFont
                                            font.pixelSize: 8
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        Layout.topMargin: 18
                                        text: "Всего прошло"
                                        color: app.slate
                                        font.family: app.sansFont
                                        font.pixelSize: 14
                                    }

                                    Text {
                                        id: totalNumber
                                        Layout.topMargin: -4
                                        text: Math.round(animatedTotal).toString()
                                        color: app.ink
                                        font.family: app.sansFont
                                        font.pixelSize: app.mobile ? 58 : 70
                                        font.weight: Font.DemiBold
                                        property real animatedTotal: app.backendObject.totalCount
                                        Behavior on animatedTotal {
                                            NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 1
                                        Layout.topMargin: 14
                                        color: "#d4d1cb"
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 54
                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 12
                                            Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4; color: app.deepGreen }
                                            Text { Layout.fillWidth: true; text: "Легковые автомобили"; color: app.ink; font.family: app.sansFont; font.pixelSize: 13; elide: Text.ElideRight }
                                            Text { text: Math.round(carNumber).toString(); color: app.ink; font.family: app.monoFont; font.pixelSize: 20; font.weight: Font.DemiBold; property real carNumber: app.backendObject.carsCount; Behavior on carNumber { NumberAnimation { duration: 340 } } }
                                        }
                                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#d4d1cb" }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 54
                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 12
                                            Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4; color: app.coral }
                                            Text { Layout.fillWidth: true; text: "Двухколёсные"; color: app.ink; font.family: app.sansFont; font.pixelSize: 13; elide: Text.ElideRight }
                                            Text { text: Math.round(twoWheelNumber).toString(); color: app.ink; font.family: app.monoFont; font.pixelSize: 20; font.weight: Font.DemiBold; property real twoWheelNumber: app.backendObject.twoWheelersCount; Behavior on twoWheelNumber { NumberAnimation { duration: 340 } } }
                                        }
                                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#d4d1cb" }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 54
                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 12
                                            Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4; color: app.actionBlue }
                                            Text { Layout.fillWidth: true; text: "Тяжёлый транспорт"; color: app.ink; font.family: app.sansFont; font.pixelSize: 13; elide: Text.ElideRight }
                                            Text { text: Math.round(heavyNumber).toString(); color: app.ink; font.family: app.monoFont; font.pixelSize: 20; font.weight: Font.DemiBold; property real heavyNumber: app.backendObject.heavyCount; Behavior on heavyNumber { NumberAnimation { duration: 340 } } }
                                        }
                                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#d4d1cb" }
                                    }

                                    Item { Layout.fillHeight: true }

                                    Text {
                                        Layout.fillWidth: true
                                        Layout.topMargin: 14
                                        text: app.backendObject.running ? "Счётчик обновляется по мере пересечения FINISH." : "В итог входят только уникальные треки, прошедшие START и FINISH."
                                        color: app.slate
                                        font.family: app.sansFont
                                        font.pixelSize: 11
                                        lineHeight: 1.15
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: errorBanner
                            Layout.fillWidth: true
                            Layout.leftMargin: app.mobile ? 20 : 38
                            Layout.rightMargin: app.mobile ? 20 : 38
                            Layout.topMargin: 16
                            Layout.preferredHeight: app.backendObject.errorText.length > 0 ? errorCopy.implicitHeight + 28 : 0
                            visible: app.backendObject.errorText.length > 0
                            color: app.errorSoft
                            radius: 12
                            border.color: "#ffc7bd"
                            border.width: 1
                            Text {
                                id: errorCopy
                                anchors.fill: parent
                                anchors.margins: 14
                                text: app.backendObject.errorText
                                color: app.errorRed
                                font.family: app.sansFont
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Item { Layout.preferredHeight: 28 }
                    }
                }

                ScrollView {
                    id: settingsScroll
                    clip: true
                    contentWidth: width
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        width: settingsScroll.width
                        spacing: 18
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 130
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: app.mobile ? 20 : 38
                                anchors.rightMargin: app.mobile ? 20 : 38
                                anchors.topMargin: 30
                                spacing: 9
                                Text { text: "PIPELINE / INPUTS"; color: app.deepGreen; font.family: app.monoFont; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 1.1 }
                                Text { text: "Настройте источник и границы подсчёта."; color: app.ink; font.family: app.sansFont; font.pixelSize: app.mobile ? 27 : 36; font.weight: Font.DemiBold; wrapMode: Text.WordWrap }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: app.mobile ? 20 : 38
                            Layout.rightMargin: app.mobile ? 20 : 38
                            Layout.preferredHeight: app.mobile ? 344 : 296
                            color: app.stone
                            radius: 22
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: app.mobile ? 18 : 24
                                spacing: 14
                                Text { text: "ФАЙЛЫ"; color: app.deepGreen; font.family: app.monoFont; font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 1.0 }

                                Text { text: "Видео"; color: app.slate; font.family: app.sansFont; font.pixelSize: 12 }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    TextField {
                                        id: videoField
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 40
                                        text: app.backendObject.videoPath
                                        selectByMouse: true
                                        color: app.ink
                                        font.family: app.monoFont
                                        font.pixelSize: 10
                                        onEditingFinished: app.backendObject.setVideoPath(text)
                                        background: Rectangle { radius: 10; color: app.canvas; border.color: videoField.activeFocus ? app.actionBlue : app.border; border.width: 1 }
                                    }
                                    Button {
                                        id: videoChooseSettings
                                        Layout.preferredWidth: 108
                                        Layout.preferredHeight: 40
                                        text: "Обзор"
                                        onClicked: app.backendObject.chooseVideo()
                                        contentItem: Text { text: videoChooseSettings.text; color: app.actionBlue; font.family: app.sansFont; font.pixelSize: 12; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                        background: Rectangle { radius: 10; color: videoChooseSettings.hovered ? app.paleBlue : app.canvas; border.color: app.actionBlue; border.width: 1 }
                                    }
                                }

                                Text { text: "Модель"; color: app.slate; font.family: app.sansFont; font.pixelSize: 12 }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    TextField {
                                        id: modelField
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 40
                                        text: app.backendObject.modelPath
                                        selectByMouse: true
                                        color: app.ink
                                        font.family: app.monoFont
                                        font.pixelSize: 10
                                        onEditingFinished: app.backendObject.setModelPath(text)
                                        background: Rectangle { radius: 10; color: app.canvas; border.color: modelField.activeFocus ? app.actionBlue : app.border; border.width: 1 }
                                    }
                                    Button {
                                        id: modelChooseSettings
                                        Layout.preferredWidth: 108
                                        Layout.preferredHeight: 40
                                        text: "Обзор"
                                        onClicked: app.backendObject.chooseModel()
                                        contentItem: Text { text: modelChooseSettings.text; color: app.actionBlue; font.family: app.sansFont; font.pixelSize: 12; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                        background: Rectangle { radius: 10; color: modelChooseSettings.hovered ? app.paleBlue : app.canvas; border.color: app.actionBlue; border.width: 1 }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: app.mobile ? 20 : 38
                            Layout.rightMargin: app.mobile ? 20 : 38
                            Layout.preferredHeight: app.mobile ? 290 : 238
                            color: app.paleGreen
                            radius: 22
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: app.mobile ? 18 : 24
                                spacing: 16
                                Text { text: "КОНТРОЛЬНЫЕ ЛИНИИ"; color: app.deepGreen; font.family: app.monoFont; font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 1.0 }
                                Text { Layout.fillWidth: true; text: "Объект считается, когда его центр сначала пересекает START, а затем FINISH."; color: app.ink; font.family: app.sansFont; font.pixelSize: 13; wrapMode: Text.WordWrap }
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: app.mobile ? 1 : 2
                                    columnSpacing: 24
                                    rowSpacing: 12
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        Text { text: "START · от верхнего края"; color: app.slate; font.family: app.sansFont; font.pixelSize: 12 }
                                        RowLayout {
                                            Layout.fillWidth: true
                                            TextField {
                                                id: startLineField
                                                Layout.preferredWidth: 76
                                                Layout.preferredHeight: 40
                                                text: Math.round(app.backendObject.startLinePercent).toString()
                                                inputMethodHints: Qt.ImhDigitsOnly
                                                color: app.ink
                                                font.family: app.monoFont
                                                font.pixelSize: 14
                                                horizontalAlignment: TextInput.AlignHCenter
                                                onEditingFinished: app.backendObject.setStartLinePercent(Number(text))
                                                background: Rectangle { radius: 10; color: app.canvas; border.color: startLineField.activeFocus ? app.deepGreen : app.border; border.width: 1 }
                                            }
                                            Text { text: "%"; color: app.deepGreen; font.family: app.monoFont; font.pixelSize: 12 }
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        Text { text: "FINISH · к нижнему краю"; color: app.slate; font.family: app.sansFont; font.pixelSize: 12 }
                                        RowLayout {
                                            Layout.fillWidth: true
                                            TextField {
                                                id: finishLineField
                                                Layout.preferredWidth: 76
                                                Layout.preferredHeight: 40
                                                text: Math.round(app.backendObject.finishLinePercent).toString()
                                                inputMethodHints: Qt.ImhDigitsOnly
                                                color: app.ink
                                                font.family: app.monoFont
                                                font.pixelSize: 14
                                                horizontalAlignment: TextInput.AlignHCenter
                                                onEditingFinished: app.backendObject.setFinishLinePercent(Number(text))
                                                background: Rectangle { radius: 10; color: app.canvas; border.color: finishLineField.activeFocus ? app.deepGreen : app.border; border.width: 1 }
                                            }
                                            Text { text: "%"; color: app.deepGreen; font.family: app.monoFont; font.pixelSize: 12 }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: app.mobile ? 20 : 38
                            Layout.rightMargin: app.mobile ? 20 : 38
                            Layout.preferredHeight: app.mobile ? 276 : 228
                            color: app.paleBlue
                            radius: 22
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: app.mobile ? 18 : 24
                                spacing: 12
                                Text { text: "РЕЖИМЫ"; color: app.actionBlue; font.family: app.monoFont; font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 1.0 }
                                Text { Layout.fillWidth: true; text: "Режим влияет на классы, переданные YOLO в текущем запуске."; color: app.ink; font.family: app.sansFont; font.pixelSize: 13; wrapMode: Text.WordWrap }
                                Text { Layout.fillWidth: true; text: "В режиме «Весь поток» итоговая карточка дополнительно раскладывает результат на легковые, двухколёсные и тяжёлые транспортные средства."; color: app.slate; font.family: app.sansFont; font.pixelSize: 12; lineHeight: 1.15; wrapMode: Text.WordWrap }
                                Text { Layout.fillWidth: true; text: "COCO: bicycle · car · motorcycle · bus · truck"; color: app.actionBlue; font.family: app.monoFont; font.pixelSize: 9; wrapMode: Text.WordWrap }
                            }
                        }
                        Item { Layout.preferredHeight: 28 }
                    }
                }

                ScrollView {
                    id: historyScroll
                    clip: true
                    contentWidth: width
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        width: historyScroll.width
                        spacing: 18
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 164
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: app.mobile ? 20 : 38
                                anchors.rightMargin: app.mobile ? 20 : 38
                                anchors.topMargin: 34
                                spacing: 9
                                Text { text: "OUTPUT / 03"; color: app.deepGreen; font.family: app.monoFont; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 1.1 }
                                Text { text: "Последний результат."; color: app.ink; font.family: app.sansFont; font.pixelSize: app.mobile ? 28 : 39; font.weight: Font.DemiBold; wrapMode: Text.WordWrap }
                                Text { text: "Здесь сохраняется путь к размеченному видео после завершения анализа."; color: app.slate; font.family: app.sansFont; font.pixelSize: 14; wrapMode: Text.WordWrap }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: app.mobile ? 20 : 38
                            Layout.rightMargin: app.mobile ? 20 : 38
                            Layout.preferredHeight: app.backendObject.outputVideoPath.length > 0 ? (app.mobile ? 370 : 310) : 258
                            color: app.backendObject.outputVideoPath.length > 0 ? app.paleGreen : app.stone
                            radius: 22

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: app.mobile ? 20 : 26
                                spacing: 14

                                Text { text: app.backendObject.outputVideoPath.length > 0 ? "RUN COMPLETE" : "NO RUN YET"; color: app.deepGreen; font.family: app.monoFont; font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 1.0 }
                                Text {
                                    Layout.fillWidth: true
                                    text: app.backendObject.outputVideoPath.length > 0 ? "Размеченное видео готово" : "Запустите анализ, чтобы увидеть файл"
                                    color: app.ink
                                    font.family: app.sansFont
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.WordWrap
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 18
                                    visible: app.backendObject.outputVideoPath.length > 0
                                    Text { text: "ВСЕГО  " + app.backendObject.totalCount; color: app.ink; font.family: app.monoFont; font.pixelSize: 11; font.weight: Font.DemiBold }
                                    Text { text: "ЛЕГКОВЫЕ  " + app.backendObject.carsCount; color: app.slate; font.family: app.monoFont; font.pixelSize: 11 }
                                    Text { text: "2-КОЛЁСНЫЕ  " + app.backendObject.twoWheelersCount; color: app.slate; font.family: app.monoFont; font.pixelSize: 11; visible: !app.mobile }
                                    Text { text: "ТЯЖЁЛЫЕ  " + app.backendObject.heavyCount; color: app.slate; font.family: app.monoFont; font.pixelSize: 11; visible: !app.mobile }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: app.backendObject.outputVideoPath.length > 0 ? app.compactPath(app.backendObject.outputVideoPath) : ""
                                    color: app.slate
                                    font.family: app.monoFont
                                    font.pixelSize: 10
                                    wrapMode: Text.WrapAnywhere
                                    visible: app.backendObject.outputVideoPath.length > 0
                                }

                                Item { Layout.fillHeight: true }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Button {
                                        id: openOutputButton
                                        Layout.preferredWidth: 166
                                        Layout.preferredHeight: 42
                                        text: "Открыть папку"
                                        enabled: app.backendObject.outputVideoPath.length > 0
                                        onClicked: app.backendObject.openOutputFolder()
                                        contentItem: Text { text: openOutputButton.text; color: openOutputButton.enabled ? app.canvas : app.muted; font.family: app.sansFont; font.pixelSize: 13; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                        background: Rectangle { radius: 21; color: openOutputButton.enabled ? app.deepGreen : "#dedbd5" }
                                    }
                                    Button {
                                        id: resetButton
                                        Layout.preferredWidth: 140
                                        Layout.preferredHeight: 42
                                        text: "Новый запуск"
                                        enabled: !app.backendObject.running
                                        onClicked: app.backendObject.resetSession()
                                        contentItem: Text { text: resetButton.text; color: app.ink; font.family: app.sansFont; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                        background: Rectangle { radius: 21; color: resetButton.hovered ? app.canvas : "transparent"; border.color: app.hairline; border.width: 1 }
                                    }
                                    Item { Layout.fillWidth: true }
                                }
                            }
                        }
                        Item { Layout.preferredHeight: 28 }
                    }
                }
            }

            Rectangle {
                id: bottomNav
                visible: app.mobile
                Layout.fillWidth: true
                Layout.preferredHeight: 76
                color: app.canvas
                border.color: app.hairline
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    Button {
                        id: bottomObserve
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: "01\nНаблюдение"
                        onClicked: app.currentPage = 0
                        contentItem: Text { text: bottomObserve.text; color: app.currentPage === 0 ? app.deepGreen : app.slate; font.family: app.monoFont; font.pixelSize: 9; lineHeight: 1.15; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 12; color: app.currentPage === 0 ? app.paleGreen : "transparent" }
                    }
                    Button {
                        id: bottomSettings
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: "02\nНастройки"
                        onClicked: app.currentPage = 1
                        contentItem: Text { text: bottomSettings.text; color: app.currentPage === 1 ? app.deepGreen : app.slate; font.family: app.monoFont; font.pixelSize: 9; lineHeight: 1.15; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 12; color: app.currentPage === 1 ? app.paleGreen : "transparent" }
                    }
                    Button {
                        id: bottomHistory
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: "03\nРезультаты"
                        onClicked: app.currentPage = 2
                        contentItem: Text { text: bottomHistory.text; color: app.currentPage === 2 ? app.deepGreen : app.slate; font.family: app.monoFont; font.pixelSize: 9; lineHeight: 1.15; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 12; color: app.currentPage === 2 ? app.paleGreen : "transparent" }
                    }
                }
            }
        }
    }
}
