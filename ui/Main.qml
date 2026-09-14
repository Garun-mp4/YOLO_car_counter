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

    Theme { id: theme }
    property var tokens: theme

    // The context property is intentionally kept behind a local alias.  This
    // avoids Qt Quick Layout scope shadowing and preserves the Python bridge.
    property var backendObject: appController
    property int currentPage: 0
    property bool mobile: width < 720
    property bool tablet: width >= 720 && width < 1120
    property bool hasVideo: app.backendObject && app.backendObject.videoPath && app.backendObject.videoPath.length > 0

    property var modeItems: [
        { key: "all", label: "Весь поток", width: 104 },
        { key: "cars", label: "Легковые", width: 96 },
        { key: "two_wheelers", label: "Двухколёсные", width: 118 },
        { key: "heavy", label: "Тяжёлый транспорт", width: 142 }
    ]

    function compactPath(path) {
        if (!path || path.length < 58)
            return path || ""
        return path.slice(0, 24) + "…" + path.slice(-28)
    }

    function fileName(path) {
        if (!path)
            return ""
        var normalized = path.replace(/\\/g, "/")
        var parts = normalized.split("/")
        return parts.length > 0 ? parts[parts.length - 1] : normalized
    }

    function modeLabel(key) {
        if (key === "cars")
            return "Легковые"
        if (key === "two_wheelers")
            return "Двухколёсные"
        if (key === "heavy")
            return "Тяжёлый транспорт"
        return "Весь поток"
    }

    function pageTitle() {
        if (currentPage === 1)
            return "Настройки"
        if (currentPage === 2)
            return "Результаты"
        return "Наблюдение"
    }

    function pageDescription() {
        if (currentPage === 1)
            return "Источник видео, модель и контрольные линии"
        if (currentPage === 2)
            return "Последний сохранённый запуск"
        return "Подсчёт транспорта по пересечению контрольных линий"
    }

    function statusColor() {
        if (app.backendObject.statusText === "ОШИБКА")
            return theme.errorRed
        if (app.backendObject.running)
            return theme.deepGreen
        return theme.slate
    }

    color: theme.canvas

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: sideRail
            visible: !app.mobile
            Layout.fillHeight: true
            Layout.preferredWidth: app.tablet ? 78 : 204
            color: theme.canvas
            border.color: theme.hairline
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: app.tablet ? 12 : 20
                anchors.rightMargin: app.tablet ? 12 : 20
                anchors.topMargin: 22
                anchors.bottomMargin: 20
                spacing: 0

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: app.tablet ? "TC" : "TRAFFIC"
                        color: theme.deepGreen
                        font.family: theme.monoFont
                        font.pixelSize: app.tablet ? 15 : 11
                        font.weight: Font.DemiBold
                        font.letterSpacing: app.tablet ? 0 : 1.6
                        horizontalAlignment: app.tablet ? Text.AlignHCenter : Text.AlignLeft
                    }
                    Text {
                        visible: !app.tablet
                        text: "COUNTER"
                        color: theme.ink
                        font.family: theme.sansFont
                        font.pixelSize: 24
                        font.weight: Font.Normal
                    }
                    Text {
                        visible: !app.tablet
                        text: "YOLO · AGTU"
                        color: theme.muted
                        font.family: theme.monoFont
                        font.pixelSize: 9
                        font.letterSpacing: 0.7
                    }
                }

                Item { Layout.fillHeight: true }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    NavItem {
                        Layout.fillWidth: true
                        theme: app.tokens
                        text: "Наблюдение"
                        indexLabel: "01"
                        compact: app.tablet
                        active: app.currentPage === 0
                        onClicked: app.currentPage = 0
                    }
                    NavItem {
                        Layout.fillWidth: true
                        theme: app.tokens
                        text: "Настройки"
                        indexLabel: "02"
                        compact: app.tablet
                        active: app.currentPage === 1
                        onClicked: app.currentPage = 1
                    }
                    NavItem {
                        Layout.fillWidth: true
                        theme: app.tokens
                        text: "Результаты"
                        indexLabel: "03"
                        compact: app.tablet
                        active: app.currentPage === 2
                        onClicked: app.currentPage = 2
                    }
                }

                Item { Layout.preferredHeight: 28 }

                ColumnLayout {
                    visible: !app.tablet
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: theme.hairline
                    }
                    Text {
                        text: "YOLO26N"
                        color: theme.muted
                        font.family: theme.monoFont
                        font.pixelSize: 9
                    }
                    Text {
                        text: "BYTE TRACK"
                        color: theme.muted
                        font.family: theme.monoFont
                        font.pixelSize: 9
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
                Layout.preferredHeight: app.mobile ? 64 : 72
                color: theme.canvas
                border.color: theme.hairline
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: app.mobile ? 18 : 28
                    anchors.rightMargin: app.mobile ? 18 : 28
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: app.pageTitle()
                            color: theme.ink
                            font.family: theme.sansFont
                            font.pixelSize: app.mobile ? 19 : 22
                            font.weight: Font.Normal
                        }
                        Text {
                            visible: !app.mobile
                            text: app.pageDescription()
                            color: theme.slate
                            font.family: theme.sansFont
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Rectangle {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 2
                            color: app.statusColor()
                        }
                        Text {
                            text: app.backendObject.statusText
                            color: theme.ink
                            font.family: theme.monoFont
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
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
                            Layout.preferredHeight: app.mobile ? 104 : 100

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: app.mobile ? 20 : 32
                                anchors.rightMargin: app.mobile ? 20 : 32
                                anchors.topMargin: app.mobile ? 24 : 28
                                spacing: 5

                                Text {
                                    text: "Подсчёт транспорта"
                                    color: theme.ink
                                    font.family: theme.sansFont
                                    font.pixelSize: app.mobile ? 27 : 32
                                    font.weight: Font.Normal
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: "Выберите режим и источник. Уникальный трек считается после пересечения START и FINISH."
                                    color: theme.slate
                                    font.family: theme.sansFont
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: app.mobile ? 170 : 82
                            anchors.leftMargin: app.mobile ? 20 : 32
                            anchors.rightMargin: app.mobile ? 20 : 32

                            RowLayout {
                                anchors.fill: parent
                                visible: !app.mobile
                                spacing: 20

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 7

                                    Text {
                                        text: "Режим подсчёта"
                                        color: theme.slate
                                        font.family: theme.sansFont
                                        font.pixelSize: 12
                                    }
                                    Flow {
                                        id: desktopModeFlow
                                        Layout.fillWidth: true
                                        spacing: 7

                                        Repeater {
                                            model: app.modeItems
                                            delegate: FilterButton {
                                                id: desktopModeButton
                                                theme: app.tokens
                                                width: modelData.width
                                                text: modelData.label
                                                active: app.backendObject.selectedMode === modelData.key
                                                enabled: !app.backendObject.running
                                                onClicked: app.backendObject.selectMode(modelData.key)
                                            }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.preferredWidth: app.tablet ? 360 : 430
                                    Layout.maximumWidth: 460
                                    spacing: 7

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 7

                                        AppButton {
                                            id: desktopOpenVideoButton
                                            theme: app.tokens
                                            text: "Открыть видео"
                                            compact: true
                                            variant: app.hasVideo ? "secondary" : "primary"
                                            enabled: !app.backendObject.running
                                            onClicked: app.backendObject.chooseVideo()
                                        }
                                        AppButton {
                                            id: desktopStartButton
                                            theme: app.tokens
                                            text: "Начать анализ"
                                            compact: true
                                            variant: app.hasVideo ? "primary" : "secondary"
                                            enabled: !app.backendObject.running && app.hasVideo
                                            onClicked: app.backendObject.startAnalysis()
                                        }
                                        AppButton {
                                            id: desktopStopButton
                                            theme: app.tokens
                                            text: "Остановить"
                                            compact: true
                                            variant: "secondary"
                                            visible: app.backendObject.running
                                            enabled: app.backendObject.running
                                            onClicked: app.backendObject.stopAnalysis()
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: app.fileName(app.backendObject.videoPath) + (app.backendObject.modelPath.length > 0 ? "   ·   " + app.fileName(app.backendObject.modelPath) : "")
                                        color: theme.muted
                                        font.family: theme.monoFont
                                        font.pixelSize: 9
                                        elide: Text.ElideMiddle
                                        ToolTip.visible: desktopPathHover.containsMouse && app.backendObject.videoPath.length > 0
                                        ToolTip.text: app.backendObject.videoPath
                                        MouseArea {
                                            id: desktopPathHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                visible: app.mobile
                                spacing: 8

                                Text {
                                    text: "Режим подсчёта"
                                    color: theme.slate
                                    font.family: theme.sansFont
                                    font.pixelSize: 12
                                }
                                Flow {
                                    id: mobileModeFlow
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Repeater {
                                        model: app.modeItems
                                        delegate: FilterButton {
                                            id: mobileModeButton
                                            theme: app.tokens
                                            width: modelData.width
                                            text: modelData.label
                                            active: app.backendObject.selectedMode === modelData.key
                                            enabled: !app.backendObject.running
                                            onClicked: app.backendObject.selectMode(modelData.key)
                                        }
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    AppButton {
                                        id: mobileOpenVideoButton
                                        Layout.fillWidth: true
                                        theme: app.tokens
                                        text: "Открыть видео"
                                        compact: true
                                        variant: app.hasVideo ? "secondary" : "primary"
                                        enabled: !app.backendObject.running
                                        onClicked: app.backendObject.chooseVideo()
                                    }
                                    AppButton {
                                        id: mobileStartButton
                                        Layout.fillWidth: true
                                        theme: app.tokens
                                        text: "Начать анализ"
                                        compact: true
                                        variant: app.hasVideo ? "primary" : "secondary"
                                        enabled: !app.backendObject.running && app.hasVideo
                                        onClicked: app.backendObject.startAnalysis()
                                    }
                                    AppButton {
                                        id: mobileStopButton
                                        Layout.fillWidth: true
                                        theme: app.tokens
                                        text: "Стоп"
                                        compact: true
                                        variant: "secondary"
                                        visible: app.backendObject.running
                                        enabled: app.backendObject.running
                                        onClicked: app.backendObject.stopAnalysis()
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: app.fileName(app.backendObject.videoPath) + (app.backendObject.modelPath.length > 0 ? "   ·   " + app.fileName(app.backendObject.modelPath) : "")
                                    color: theme.muted
                                    font.family: theme.monoFont
                                    font.pixelSize: 9
                                    elide: Text.ElideMiddle
                                    ToolTip.visible: mobilePathHover.containsMouse && app.backendObject.videoPath.length > 0
                                    ToolTip.text: app.backendObject.videoPath
                                    MouseArea {
                                        id: mobilePathHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: app.mobile ? 20 : 32
                            Layout.rightMargin: app.mobile ? 20 : 32
                            Layout.preferredHeight: 1
                            color: theme.hairline
                        }

                        RowLayout {
                            id: desktopWorkArea
                            visible: !app.mobile
                            Layout.fillWidth: true
                            Layout.preferredHeight: app.tablet ? 406 : 478
                            Layout.leftMargin: app.tablet ? 24 : 32
                            Layout.rightMargin: app.tablet ? 24 : 32
                            Layout.topMargin: 18
                            Layout.bottomMargin: 18
                            spacing: 16

                            LiveMedia {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumWidth: 0
                                backend: app.backendObject
                                theme: app.tokens
                                compact: app.tablet
                            }
                            ResultsPanel {
                                Layout.preferredWidth: app.tablet ? 288 : 326
                                Layout.preferredHeight: app.tablet ? 360 : 414
                                Layout.alignment: Qt.AlignTop
                                Layout.minimumWidth: 248
                                backend: app.backendObject
                                theme: app.tokens
                                compact: app.tablet
                                modeLabel: app.modeLabel(app.backendObject.selectedMode)
                            }
                        }

                        ColumnLayout {
                            id: mobileWorkArea
                            visible: app.mobile
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            Layout.topMargin: 14
                            Layout.bottomMargin: 14
                            spacing: 12

                            LiveMedia {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 258
                                backend: app.backendObject
                                theme: app.tokens
                                compact: true
                            }
                            ResultsPanel {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 342
                                backend: app.backendObject
                                theme: app.tokens
                                compact: true
                                modeLabel: app.modeLabel(app.backendObject.selectedMode)
                            }
                        }

                        Rectangle {
                            id: errorBanner
                            Layout.fillWidth: true
                            Layout.leftMargin: app.mobile ? 20 : 32
                            Layout.rightMargin: app.mobile ? 20 : 32
                            Layout.preferredHeight: app.backendObject.errorText.length > 0 ? errorCopy.implicitHeight + 24 : 0
                            visible: app.backendObject.errorText.length > 0
                            color: theme.errorSoft
                            border.color: "#ffc7bd"
                            border.width: 1
                            radius: theme.radiusSmall
                            Text {
                                id: errorCopy
                                anchors.fill: parent
                                anchors.margins: 12
                                text: app.backendObject.errorText
                                color: theme.errorRed
                                font.family: theme.sansFont
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Item { Layout.preferredHeight: app.mobile ? 18 : 22 }
                    }
                }

                ScrollView {
                    id: settingsScroll
                    clip: true
                    contentWidth: width
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        id: settingsContent
                        width: settingsScroll.width
                        spacing: 0

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: app.mobile ? 94 : 92
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: app.mobile ? 20 : 32
                                anchors.rightMargin: app.mobile ? 20 : 32
                                anchors.topMargin: 24
                                spacing: 5
                                Text {
                                    text: "Параметры запуска"
                                    color: theme.ink
                                    font.family: theme.sansFont
                                    font.pixelSize: app.mobile ? 27 : 32
                                    font.weight: Font.Normal
                                }
                                Text {
                                    text: "Настройте источник, модель и границы, если их нужно изменить."
                                    color: theme.slate
                                    font.family: theme.sansFont
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Flow {
                            id: settingsPanels
                            Layout.fillWidth: true
                            Layout.leftMargin: app.mobile ? 20 : 32
                            Layout.rightMargin: app.mobile ? 20 : 32
                            spacing: 16

                            Rectangle {
                                width: app.mobile ? settingsScroll.width - 40 : (settingsScroll.width - 64 - settingsPanels.spacing) / 2
                                height: app.mobile ? 278 : 246
                                color: theme.canvas
                                border.color: theme.hairline
                                border.width: 1
                                radius: theme.radiusPanel

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: app.mobile ? 16 : 20
                                    spacing: 10
                                    Text {
                                        text: "Источник и модель"
                                        color: theme.ink
                                        font.family: theme.sansFont
                                        font.pixelSize: 15
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        text: "Пути используются для следующего запуска."
                                        color: theme.slate
                                        font.family: theme.sansFont
                                        font.pixelSize: 11
                                    }
                                    Text { text: "Видео"; color: theme.slate; font.family: theme.sansFont; font.pixelSize: 12 }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 7
                                        TextField {
                                            id: settingsVideoField
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 36
                                            text: app.backendObject.videoPath
                                            selectByMouse: true
                                            color: theme.ink
                                            font.family: theme.monoFont
                                            font.pixelSize: 9
                                            onEditingFinished: app.backendObject.setVideoPath(text)
                                            background: Rectangle {
                                                radius: theme.radiusSmall
                                                color: theme.canvas
                                                border.color: settingsVideoField.activeFocus ? theme.actionBlue : theme.border
                                                border.width: settingsVideoField.activeFocus ? 2 : 1
                                            }
                                        }
                                        AppButton {
                                            theme: app.tokens
                                            text: "Обзор"
                                            compact: true
                                            variant: "secondary"
                                            onClicked: app.backendObject.chooseVideo()
                                        }
                                    }
                                    Text { text: "Модель YOLO"; color: theme.slate; font.family: theme.sansFont; font.pixelSize: 12 }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 7
                                        TextField {
                                            id: settingsModelField
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 36
                                            text: app.backendObject.modelPath
                                            selectByMouse: true
                                            color: theme.ink
                                            font.family: theme.monoFont
                                            font.pixelSize: 9
                                            onEditingFinished: app.backendObject.setModelPath(text)
                                            background: Rectangle {
                                                radius: theme.radiusSmall
                                                color: theme.canvas
                                                border.color: settingsModelField.activeFocus ? theme.actionBlue : theme.border
                                                border.width: settingsModelField.activeFocus ? 2 : 1
                                            }
                                        }
                                        AppButton {
                                            theme: app.tokens
                                            text: "Обзор"
                                            compact: true
                                            variant: "secondary"
                                            onClicked: app.backendObject.chooseModel()
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: app.mobile ? settingsScroll.width - 40 : (settingsScroll.width - 64 - settingsPanels.spacing) / 2
                                height: app.mobile ? 278 : 246
                                color: theme.canvas
                                border.color: theme.hairline
                                border.width: 1
                                radius: theme.radiusPanel

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: app.mobile ? 16 : 20
                                    spacing: 10
                                    Text {
                                        text: "Контрольные линии"
                                        color: theme.ink
                                        font.family: theme.sansFont
                                        font.pixelSize: 15
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Трек попадает в итог, если его центр пересекает START, затем FINISH."
                                        color: theme.slate
                                        font.family: theme.sansFont
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.topMargin: 4
                                        spacing: 12
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 5
                                            Text { text: "START · от верхнего края"; color: theme.slate; font.family: theme.sansFont; font.pixelSize: 11; elide: Text.ElideRight }
                                            RowLayout {
                                                spacing: 5
                                                TextField {
                                                    id: startLineField
                                                    Layout.preferredWidth: 60
                                                    Layout.preferredHeight: 36
                                                    text: Math.round(app.backendObject.startLinePercent).toString()
                                                    selectByMouse: true
                                                    color: theme.ink
                                                    font.family: theme.monoFont
                                                    font.pixelSize: 12
                                                    horizontalAlignment: Text.AlignRight
                                                    validator: DoubleValidator { bottom: 5; top: 90; decimals: 1 }
                                                    onEditingFinished: app.backendObject.setStartLinePercent(Number(text))
                                                    background: Rectangle { radius: theme.radiusSmall; color: theme.canvas; border.color: startLineField.activeFocus ? theme.deepGreen : theme.border; border.width: startLineField.activeFocus ? 2 : 1 }
                                                }
                                                Text { text: "%"; color: theme.deepGreen; font.family: theme.monoFont; font.pixelSize: 12 }
                                            }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 5
                                            Text { text: "FINISH · к нижнему краю"; color: theme.slate; font.family: theme.sansFont; font.pixelSize: 11; elide: Text.ElideRight }
                                            RowLayout {
                                                spacing: 5
                                                TextField {
                                                    id: finishLineField
                                                    Layout.preferredWidth: 60
                                                    Layout.preferredHeight: 36
                                                    text: Math.round(app.backendObject.finishLinePercent).toString()
                                                    selectByMouse: true
                                                    color: theme.ink
                                                    font.family: theme.monoFont
                                                    font.pixelSize: 12
                                                    horizontalAlignment: Text.AlignRight
                                                    validator: DoubleValidator { bottom: 10; top: 95; decimals: 1 }
                                                    onEditingFinished: app.backendObject.setFinishLinePercent(Number(text))
                                                    background: Rectangle { radius: theme.radiusSmall; color: theme.canvas; border.color: finishLineField.activeFocus ? theme.deepGreen : theme.border; border.width: finishLineField.activeFocus ? 2 : 1 }
                                                }
                                                Text { text: "%"; color: theme.deepGreen; font.family: theme.monoFont; font.pixelSize: 12 }
                                            }
                                        }
                                    }
                                    Item { Layout.fillHeight: true }
                                    Text {
                                        text: "START " + Math.round(app.backendObject.startLinePercent) + "%   →   FINISH " + Math.round(app.backendObject.finishLinePercent) + "%"
                                        color: theme.deepGreen
                                        font.family: theme.monoFont
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: app.mobile ? 20 : 32
                            Layout.rightMargin: app.mobile ? 20 : 32
                            Layout.topMargin: 16
                            Layout.preferredHeight: 76
                            color: theme.paleBlue
                            radius: theme.radiusSmall
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12
                                Text { text: "Режимы"; color: theme.actionBlue; font.family: theme.monoFont; font.pixelSize: 10; font.weight: Font.DemiBold }
                                Text { Layout.fillWidth: true; text: "Фильтр выбирает классы COCO, переданные в текущий запуск YOLO. В режиме «Весь поток» итог дополнительно раскладывается по категориям."; color: theme.ink; font.family: theme.sansFont; font.pixelSize: 12; wrapMode: Text.WordWrap }
                            }
                        }

                        Item { Layout.preferredHeight: 22 }
                    }
                }

                ScrollView {
                    id: resultsScroll
                    clip: true
                    contentWidth: width
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        id: resultsContent
                        width: resultsScroll.width
                        spacing: 0

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: app.mobile ? 94 : 92
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: app.mobile ? 20 : 32
                                anchors.rightMargin: app.mobile ? 20 : 32
                                anchors.topMargin: 24
                                spacing: 5
                                Text { text: "Результаты запуска"; color: theme.ink; font.family: theme.sansFont; font.pixelSize: app.mobile ? 27 : 32; font.weight: Font.Normal }
                                Text { text: "Счётчики и путь к размеченному видео последнего завершённого анализа."; color: theme.slate; font.family: theme.sansFont; font.pixelSize: 13; wrapMode: Text.WordWrap }
                            }
                        }

                        Flow {
                            id: resultPanels
                            Layout.fillWidth: true
                            Layout.leftMargin: app.mobile ? 20 : 32
                            Layout.rightMargin: app.mobile ? 20 : 32
                            spacing: 16

                            Rectangle {
                                width: app.mobile ? resultsScroll.width - 40 : (resultsScroll.width - 64 - resultPanels.spacing) * 0.58
                                height: app.mobile ? 282 : 260
                                color: app.backendObject.outputVideoPath.length > 0 ? theme.paleGreen : theme.softStone
                                radius: theme.radiusPanel

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: app.mobile ? 18 : 22
                                    spacing: 8
                                    Text { text: "Выходной файл"; color: theme.deepGreen; font.family: theme.monoFont; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 0.7 }
                                    Text { text: app.backendObject.outputVideoPath.length > 0 ? "Размеченное видео готово" : "Анализ ещё не запускался"; color: theme.ink; font.family: theme.sansFont; font.pixelSize: 20; font.weight: Font.Normal; wrapMode: Text.WordWrap }
                                    Text { text: app.backendObject.outputVideoPath.length > 0 ? app.compactPath(app.backendObject.outputVideoPath) : "После завершения здесь появится путь к файлу."; color: theme.slate; font.family: theme.monoFont; font.pixelSize: 10; wrapMode: Text.WrapAnywhere; maximumLineCount: 3 }
                                    Item { Layout.fillHeight: true }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        AppButton { theme: app.tokens; text: "Открыть папку"; compact: true; variant: "primary"; enabled: app.backendObject.outputVideoPath.length > 0; onClicked: app.backendObject.openOutputFolder() }
                                        AppButton { theme: app.tokens; text: "Сбросить"; compact: true; variant: "secondary"; enabled: !app.backendObject.running; onClicked: app.backendObject.resetSession() }
                                    }
                                }
                            }

                            Rectangle {
                                width: app.mobile ? resultsScroll.width - 40 : (resultsScroll.width - 64 - resultPanels.spacing) * 0.42
                                height: app.mobile ? 282 : 260
                                color: theme.canvas
                                border.color: theme.hairline
                                border.width: 1
                                radius: theme.radiusPanel

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: app.mobile ? 18 : 22
                                    anchors.rightMargin: app.mobile ? 18 : 22
                                    anchors.topMargin: app.mobile ? 18 : 22
                                    anchors.bottomMargin: app.mobile ? 12 : 16
                                    spacing: 0
                                    Text { text: "Сводка"; color: theme.deepGreen; font.family: theme.sansFont; font.pixelSize: 14; font.weight: Font.DemiBold }
                                    Text { Layout.topMargin: 16; text: "Всего прошло"; color: theme.slate; font.family: theme.sansFont; font.pixelSize: 12 }
                                    Text { text: app.backendObject.totalCount; color: theme.ink; font.family: theme.monoFont; font.pixelSize: 34; font.weight: Font.Normal }
                                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: theme.hairline; Layout.topMargin: 6 }
                                    MetricRow { theme: app.tokens; label: "Легковые"; value: app.backendObject.carsCount; markerColor: app.tokens.deepGreen }
                                    MetricRow { theme: app.tokens; label: "Двухколёсные"; value: app.backendObject.twoWheelersCount; markerColor: app.tokens.coral }
                                    MetricRow { theme: app.tokens; label: "Тяжёлые"; value: app.backendObject.heavyCount; markerColor: app.tokens.actionBlue }
                                }
                            }
                        }

                        Item { Layout.preferredHeight: 22 }
                    }
                }
            }

            Rectangle {
                id: bottomNav
                visible: app.mobile
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                color: theme.canvas
                border.color: theme.hairline
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 4
                    NavItem { Layout.fillWidth: true; theme: app.tokens; text: "Наблюдение"; indexLabel: "01"; compact: true; active: app.currentPage === 0; onClicked: app.currentPage = 0 }
                    NavItem { Layout.fillWidth: true; theme: app.tokens; text: "Настройки"; indexLabel: "02"; compact: true; active: app.currentPage === 1; onClicked: app.currentPage = 1 }
                    NavItem { Layout.fillWidth: true; theme: app.tokens; text: "Результаты"; indexLabel: "03"; compact: true; active: app.currentPage === 2; onClicked: app.currentPage = 2 }
                }
            }
        }
    }
}
