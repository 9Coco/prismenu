import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../code/LayoutRegistry.js" as LayoutRegistry

Item {
    id: root

    property string cfg_CurrentLayout
    property alias cfg_FlipHorizontal: flipBox.checked
    property string cfg_SearchbarLocation
    property alias cfg_MenuWidth: widthSpin.value
    property alias cfg_MenuHeight: heightSpin.value

    property var layouts: LayoutRegistry.allLayouts()

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        anchors.fill: parent

        Kirigami.Heading {
            text: i18n("Menu Layout")
            level: 2
        }

        GridView {
            id: layoutGrid
            Layout.fillWidth: true
            Layout.preferredHeight: cellHeight * 3.2
            cellWidth: Kirigami.Units.gridUnit * 12
            cellHeight: Kirigami.Units.gridUnit * 9
            model: root.layouts
            clip: true

            delegate: Item {
                width: layoutGrid.cellWidth
                height: layoutGrid.cellHeight
                required property var modelData

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    radius: Kirigami.Units.smallSpacing
                    color: cfg_CurrentLayout === modelData.id ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                    border.width: 1
                    border.color: cfg_CurrentLayout === modelData.id ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                    opacity: cfg_CurrentLayout === modelData.id ? 0.25 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        // Mini wireframe preview
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 3
                            color: Kirigami.Theme.alternateBackgroundColor

                            Column {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 3
                                Rectangle { width: parent.width * 0.9; height: 6; radius: 2; color: Kirigami.Theme.disabledTextColor; opacity: 0.5 }
                                Row {
                                    spacing: 3
                                    width: parent.width
                                    height: parent.height - 20
                                    Rectangle {
                                        visible: modelData.hasCategories
                                        width: parent.width * 0.32
                                        height: parent.height
                                        radius: 2
                                        color: Kirigami.Theme.disabledTextColor
                                        opacity: 0.35
                                    }
                                    Rectangle {
                                        width: modelData.hasCategories ? parent.width * 0.62 : parent.width * 0.95
                                        height: parent.height
                                        radius: 2
                                        color: Kirigami.Theme.disabledTextColor
                                        opacity: 0.2
                                    }
                                }
                            }
                        }

                        QQC2.Label {
                            text: modelData.name
                            font.bold: true
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            color: cfg_CurrentLayout === modelData.id ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                        }
                        QQC2.Label {
                            text: modelData.description
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.8
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            color: cfg_CurrentLayout === modelData.id ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            cfg_CurrentLayout = modelData.id;
                            // Apply layout default size hints when switching
                            widthSpin.value = modelData.defaultWidth;
                            heightSpin.value = modelData.defaultHeight;
                        }
                    }
                }
            }
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true

            QQC2.CheckBox {
                id: flipBox
                Kirigami.FormData.label: i18n("Horizontal flip:")
                text: i18n("Swap categories and applications columns")
                enabled: LayoutRegistry.supportsOption(cfg_CurrentLayout, "flip")
            }

            Kirigami.InlineMessage {
                Layout.fillWidth: true
                visible: !LayoutRegistry.supportsOption(cfg_CurrentLayout, "flip")
                type: Kirigami.MessageType.Information
                text: i18n("Current layout does not support this option.")
            }

            QQC2.ComboBox {
                id: searchLoc
                Kirigami.FormData.label: i18n("Search bar location:")
                enabled: LayoutRegistry.supportsOption(cfg_CurrentLayout, "searchbarLocation")
                model: [i18n("Top"), i18n("Bottom")]
                Component.onCompleted: currentIndex = cfg_SearchbarLocation === "bottom" ? 1 : 0
                onActivated: cfg_SearchbarLocation = currentIndex === 1 ? "bottom" : "top"
            }

            QQC2.SpinBox {
                id: widthSpin
                Kirigami.FormData.label: i18n("Menu width:")
                from: 400
                to: 900
                stepSize: 10
                textFromValue: (v) => v + " px"
            }

            QQC2.SpinBox {
                id: heightSpin
                Kirigami.FormData.label: i18n("Menu height:")
                from: 400
                to: 800
                stepSize: 10
                textFromValue: (v) => v + " px"
            }
        }
    }

}
