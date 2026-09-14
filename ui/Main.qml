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
    property int pageInset: app.mobile ? theme.pageInsetMobile : theme.pageInsetDesktop
    property int sectionGap: theme.sectionGap

    property var modeItems: [
        { key: "all", label: "Весь поток", minWidth: 104 },
        { key: "cars", label: "Легковые", minWidth: 96 },
        { key: "two_wheelers", label: "Двухколёсные", minWidth: 118 },
        // The short filter label keeps the control row readable; the full
        // category name remains in the results panel and exported summary.
        { key: "heavy", label: "Тяжёлые", minWidth: 104 }
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
            return "Источник, модель и линия подсчёта"
        if (currentPage === 2)
            return "Последний сохранённый запуск"
        return "Видео, режим и линия подсчёта"
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
            Layout.preferredWidth: app.tablet ? 80 : 208
            color: theme.canvas
            border.color: theme.hairline
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: app.tablet ? 16 : 24
                anchors.rightMargin: app.tablet ? 16 : 24
                anchors.topMargin: 24
                anchors.bottomMargin: 24
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
                        indexOnly: app.tablet
                        active: app.currentPage === 0
                        onClicked: app.currentPage = 0
                    }
                    NavItem {
                        Layout.fillWidth: true
                        theme: app.tokens
                        text: "Настройки"
                        indexLabel: "02"
                        compact: app.tablet
                        indexOnly: app.tablet
                        active: app.currentPage === 1
                        onClicked: app.currentPage = 1
                    }
                    NavItem {
                        Layout.fillWidth: true
                        theme: app.tokens
                        text: "Результаты"
                        indexLabel: "03"
                        compact: app.tablet
                        indexOnly: app.tablet
                        active: app.currentPage === 2
                        onClicked: app.currentPage = 2
                    }
                }

                Item { Layout.preferredHeight: 28 }

                ColumnLayout {
                    visible: !app.tablet
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: theme.hairline
                    }
                    Text {
                        text: "YOLO26"
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
                    anchors.leftMargin: app.mobile ? 16 : 24
                    anchors.rightMargin: app.mobile ? 16 : 24
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

                        PageHeader {
                            theme: app.tokens
                            mobile: app.mobile
                            title: "Подсчёт транспорта"
                            subtitle: "Выберите источник и режим. Подсчёт — у нижней линии."
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: app.mobile ? 170 : (app.tablet ? 148 : 112)
                            Layout.leftMargin: app.pageInset
                            Layout.rightMargin: app.pageInset

                            RowLayout {
                                anchors.fill: parent
                                visible: !app.mobile && !app.tablet
                                spacing: app.sectionGap

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: "Режим подсчёта"
                                        color: theme.slate
                                        font.family: theme.sansFont
                                        font.pixelSize: 12
                                    }
                                    Flow {
                                        id: desktopModeFlow
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Repeater {
                                            model: app.modeItems
                                            delegate: FilterButton {
                                                id: desktopModeButton
                                                theme: app.tokens
                                                width: Math.max(modelData.minWidth, implicitWidth)
                                                text: modelData.label
                                                active: app.backendObject.selectedMode === modelData.key
                                                enabled: !app.backendObject.running
                                                onClicked: app.backendObject.selectMode(modelData.key)
                                            }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.preferredWidth: 430
                                    Layout.maximumWidth: 440
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

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
                                visible: app.mobile || app.tablet
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
                                    spacing: 8
                                    Repeater {
                                        model: app.modeItems
                                        delegate: FilterButton {
                                            id: mobileModeButton
                                            theme: app.tokens
                                            width: Math.max(modelData.minWidth, implicitWidth)
                                            text: modelData.label
                                            active: app.backendObject.selectedMode === modelData.key
                                            enabled: !app.backendObject.running
                                            onClicked: app.backendObject.selectMode(modelData.key)
                                        }
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    AppButton {
                                        id: mobileOpenVideoButton
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        theme: app.tokens
                                        text: app.mobile ? "Открыть" : "Открыть видео"
                                        compact: true
                                        variant: app.hasVideo ? "secondary" : "primary"
                                        enabled: !app.backendObject.running
                                        onClicked: app.backendObject.chooseVideo()
                                    }
                                    AppButton {
                                        id: mobileStartButton
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        theme: app.tokens
                                        text: app.mobile ? "Запустить" : "Начать анализ"
                                        compact: true
                                        variant: app.hasVideo ? "primary" : "secondary"
                                        enabled: !app.backendObject.running && app.hasVideo
                                        onClicked: app.backendObject.startAnalysis()
                                    }
                                    AppButton {
                                        id: mobileStopButton
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
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
                            Layout.leftMargin: app.pageInset
                            Layout.rightMargin: app.pageInset
                            Layout.preferredHeight: 1
                            color: theme.hairline
                        }

                        RowLayout {
                            id: desktopWorkArea
                            visible: !app.mobile
                            Layout.fillWidth: true
                            Layout.preferredHeight: app.tablet ? 406 : 478
                            Layout.leftMargin: app.tablet ? theme.space24 : app.pageInset
                            Layout.rightMargin: app.tablet ? theme.space24 : app.pageInset
                            Layout.topMargin: app.sectionGap
                            Layout.bottomMargin: app.sectionGap
                            spacing: app.sectionGap

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
                            Layout.leftMargin: app.pageInset
                            Layout.rightMargin: app.pageInset
                            Layout.topMargin: app.sectionGap
                            Layout.bottomMargin: app.sectionGap
                            spacing: app.sectionGap

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
                            Layout.leftMargin: app.pageInset
                            Layout.rightMargin: app.pageInset
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

                        PageHeader {
                            theme: app.tokens
                            mobile: app.mobile
                            title: "Параметры запуска"
                            subtitle: "Настройте источник, модель и границы, если их нужно изменить."
                        }

                        GridLayout {
                            id: settingsPanels
                            Layout.fillWidth: true
                            Layout.leftMargin: app.pageInset
                            Layout.rightMargin: app.pageInset
                            columns: app.mobile || app.tablet ? 1 : 2
                            columnSpacing: app.sectionGap
                            rowSpacing: app.sectionGap

                            SurfaceCard {
                                id: sourceModelCard
                                theme: app.tokens
                                mobile: app.mobile
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Text {
                                    Layout.fillWidth: true
                                    text: "Источник и модель"
                                    color: theme.ink
                                    font.family: theme.sansFont
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: "Пути используются для следующего запуска."
                                    color: theme.slate
                                    font.family: theme.sansFont
                                    font.pixelSize: 11
                                }
                                Text { text: "Видео"; color: theme.slate; font.family: theme.sansFont; font.pixelSize: 12 }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: theme.space8
                                    TextField {
                                        id: settingsVideoField
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        Layout.preferredHeight: theme.controlHeight
                                        text: app.backendObject.videoPath
                                        selectByMouse: true
                                        color: theme.ink
                                        font.family: theme.monoFont
                                        font.pixelSize: 9
                                        onEditingFinished: {
                                            app.backendObject.setVideoPath(text)
                                            text = app.backendObject.videoPath
                                        }
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
                                Connections {
                                    target: app.backendObject
                                    function onVideoPathChanged() {
                                        if (!settingsVideoField.activeFocus)
                                            settingsVideoField.text = app.backendObject.videoPath
                                    }
                                }
                                Text { text: "Модель YOLO"; color: theme.slate; font.family: theme.sansFont; font.pixelSize: 12 }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: theme.space8
                                    TextField {
                                        id: settingsModelField
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        Layout.preferredHeight: theme.controlHeight
                                        text: app.backendObject.modelPath
                                        selectByMouse: true
                                        color: theme.ink
                                        font.family: theme.monoFont
                                        font.pixelSize: 9
                                        onEditingFinished: {
                                            app.backendObject.setModelPath(text)
                                            text = app.backendObject.modelPath
                                        }
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
                                Connections {
                                    target: app.backendObject
                                    function onModelPathChanged() {
                                        if (!settingsModelField.activeFocus)
                                            settingsModelField.text = app.backendObject.modelPath
                                    }
                                }
                            }

                            SurfaceCard {
                                id: linesCard
                                theme: app.tokens
                                mobile: app.mobile
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Text {
                                    Layout.fillWidth: true
                                    text: "Контрольные линии"
                                    color: theme.ink
                                    font.family: theme.sansFont
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: "Используется одна линия у нижнего края. Потерянный рядом трек засчитывается только при подтверждённом движении к выходу."
                                    color: theme.slate
                                    font.family: theme.sansFont
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: theme.space8
                                    spacing: theme.space8
                                    Text {
                                        Layout.minimumWidth: 0
                                        text: "Линия подсчёта"
                                        color: theme.slate
                                        font.family: theme.sansFont
                                        font.pixelSize: 11
                                    }
                                    TextField {
                                        id: finishLineField
                                        Layout.preferredWidth: 64
                                        Layout.preferredHeight: theme.controlHeight
                                        text: Math.round(app.backendObject.finishLinePercent).toString()
                                        selectByMouse: true
                                        color: theme.ink
                                        font.family: theme.monoFont
                                        font.pixelSize: 12
                                        horizontalAlignment: Text.AlignRight
                                        validator: DoubleValidator { bottom: 70; top: 97; decimals: 1 }
                                        onEditingFinished: app.backendObject.setFinishLinePercent(Number(text))
                                        background: Rectangle {
                                            radius: theme.radiusSmall
                                            color: theme.canvas
                                            border.color: finishLineField.activeFocus ? theme.deepGreen : theme.border
                                            border.width: finishLineField.activeFocus ? 2 : 1
                                        }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        text: app.mobile ? "% сверху" : "% от верхнего края"
                                        color: theme.deepGreen
                                        font.family: theme.monoFont
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }
                                Item { Layout.fillHeight: true; Layout.minimumHeight: theme.space8 }
                                Text {
                                    Layout.fillWidth: true
                                    text: "ЛИНИЯ " + Math.round(app.backendObject.finishLinePercent) + "%   ·   ПРОГНОЗ ВЫХОДА ВКЛЮЧЁН"
                                    color: theme.deepGreen
                                    font.family: theme.monoFont
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: app.pageInset
                            Layout.rightMargin: app.pageInset
                            Layout.topMargin: app.sectionGap
                            implicitHeight: Math.max(app.mobile ? 104 : 76, modeInfoCopy.implicitHeight + 32)
                            Layout.preferredHeight: implicitHeight
                            color: theme.paleBlue
                            radius: theme.radiusSmall
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: theme.space16
                                anchors.rightMargin: theme.space16
                                spacing: theme.space12
                                Text { text: "Режимы"; color: theme.actionBlue; font.family: theme.monoFont; font.pixelSize: 10; font.weight: Font.DemiBold }
                                Text { id: modeInfoCopy; Layout.fillWidth: true; text: "Фильтр выбирает классы COCO, переданные в текущий запуск YOLO. В режиме «Весь поток» итог дополнительно раскладывается по категориям."; color: theme.ink; font.family: theme.sansFont; font.pixelSize: 12; wrapMode: Text.WordWrap }
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

                        PageHeader {
                            theme: app.tokens
                            mobile: app.mobile
                            title: "Результаты запуска"
                            subtitle: "Счётчики и путь к размеченному видео последнего завершённого анализа."
                        }

                        GridLayout {
                            id: resultPanels
                            Layout.fillWidth: true
                            Layout.leftMargin: app.pageInset
                            Layout.rightMargin: app.pageInset
                            columns: app.mobile || app.tablet ? 1 : 2
                            columnSpacing: app.sectionGap
                            rowSpacing: app.sectionGap

                            SurfaceCard {
                                id: outputCard
                                theme: app.tokens
                                mobile: app.mobile
                                surfaceColor: app.backendObject.outputVideoPath.length > 0 ? theme.paleGreen : theme.softStone
                                strokeColor: "transparent"
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Text {
                                    Layout.fillWidth: true
                                    text: "Выходной файл"
                                    color: theme.deepGreen
                                    font.family: theme.monoFont
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.7
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: app.backendObject.outputVideoPath.length > 0 ? "Размеченное видео готово" : "Анализ ещё не запускался"
                                    color: theme.ink
                                    font.family: theme.sansFont
                                    font.pixelSize: 20
                                    font.weight: Font.Normal
                                    wrapMode: Text.WordWrap
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: app.backendObject.outputVideoPath.length > 0 ? app.compactPath(app.backendObject.outputVideoPath) : "После завершения здесь появится путь к файлу."
                                    color: theme.slate
                                    font.family: theme.monoFont
                                    font.pixelSize: 10
                                    wrapMode: Text.WrapAnywhere
                                    maximumLineCount: 3
                                }
                                Item { Layout.fillHeight: true; Layout.minimumHeight: theme.space8 }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: theme.space8
                                    AppButton {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        theme: app.tokens
                                        text: app.mobile ? "Открыть" : "Открыть папку"
                                        compact: true
                                        variant: "primary"
                                        enabled: app.backendObject.outputVideoPath.length > 0
                                        onClicked: app.backendObject.openOutputFolder()
                                    }
                                    AppButton {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        theme: app.tokens
                                        text: "Сбросить"
                                        compact: true
                                        variant: "secondary"
                                        enabled: !app.backendObject.running
                                        onClicked: app.backendObject.resetSession()
                                    }
                                }
                            }

                            SurfaceCard {
                                id: summaryCard
                                theme: app.tokens
                                mobile: app.mobile
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Text {
                                    Layout.fillWidth: true
                                    text: "Сводка"
                                    color: theme.deepGreen
                                    font.family: theme.sansFont
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    Layout.topMargin: theme.space8
                                    text: "Всего прошло"
                                    color: theme.slate
                                    font.family: theme.sansFont
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: app.backendObject.totalCount
                                    color: theme.ink
                                    font.family: theme.monoFont
                                    font.pixelSize: 34
                                    font.weight: Font.Normal
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 1
                                    color: theme.hairline
                                }
                                MetricRow { theme: app.tokens; label: "Легковые"; value: app.backendObject.carsCount; markerColor: app.tokens.deepGreen }
                                MetricRow { theme: app.tokens; label: "Двухколёсные"; value: app.backendObject.twoWheelersCount; markerColor: app.tokens.coral }
                                MetricRow { theme: app.tokens; label: "Тяжёлые"; value: app.backendObject.heavyCount; markerColor: app.tokens.actionBlue }
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
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8
                    NavItem { Layout.fillWidth: true; theme: app.tokens; text: "Наблюдение"; indexLabel: "01"; compact: true; active: app.currentPage === 0; onClicked: app.currentPage = 0 }
                    NavItem { Layout.fillWidth: true; theme: app.tokens; text: "Настройки"; indexLabel: "02"; compact: true; active: app.currentPage === 1; onClicked: app.currentPage = 1 }
                    NavItem { Layout.fillWidth: true; theme: app.tokens; text: "Результаты"; indexLabel: "03"; compact: true; active: app.currentPage === 2; onClicked: app.currentPage = 2 }
                }
            }
        }
    }
}
