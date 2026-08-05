import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs
import org.kde.kirigami as Kirigami
import "../../code/Theme.js" as ThemeHelper

Item {
    id: root

    property string cfg_ThemeMode
    property string cfg_BgColor
    property string cfg_FgColor
    property string cfg_BorderColor
    property alias cfg_BorderWidth: borderWidthSpin.value
    property alias cfg_CornerRadius: radiusSpin.value
    property alias cfg_Font: fontField.text
    property alias cfg_FontSize: fontSizeSpin.value
    property string cfg_SelectedBg
    property string cfg_SelectedFg
    property alias cfg_CategoryIconSize: catIconSpin.value
    property alias cfg_AppIconSize: appIconSpin.value
    property alias cfg_FollowColorScheme: followScheme.checked

    readonly property bool customMode: cfg_ThemeMode === "custom"
    readonly property bool lowContrast: ThemeHelper.hasLowContrast(cfg_FgColor, cfg_BgColor)

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            Kirigami.FormLayout {
                Layout.fillWidth: true

                QQC2.ComboBox {
                    id: themeMode
                    Kirigami.FormData.label: i18n("Theme mode:")
                    model: [i18n("Follow Plasma theme"), i18n("Custom theme")]
                    Component.onCompleted: currentIndex = cfg_ThemeMode === "custom" ? 1 : 0
                    onActivated: cfg_ThemeMode = currentIndex === 1 ? "custom" : "system"
                }

                QQC2.CheckBox {
                    id: followScheme
                    Kirigami.FormData.label: i18n("Color scheme:")
                    text: i18n("Follow Plasma light/dark mode")
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Background:")
                    enabled: customMode
                    QQC2.TextField { id: bgField; text: cfg_BgColor; onTextChanged: cfg_BgColor = text; Layout.fillWidth: true; placeholderText: "#RRGGBB" }
                    QQC2.Button { text: "…"; onClicked: { colorDialog.targetProp = "bg"; colorDialog.selectedColor = cfg_BgColor || "#ffffff"; colorDialog.open(); } }
                }
                RowLayout {
                    Kirigami.FormData.label: i18n("Foreground:")
                    enabled: customMode
                    QQC2.TextField { id: fgField; text: cfg_FgColor; onTextChanged: cfg_FgColor = text; Layout.fillWidth: true }
                    QQC2.Button { text: "…"; onClicked: { colorDialog.targetProp = "fg"; colorDialog.selectedColor = cfg_FgColor || "#000000"; colorDialog.open(); } }
                }
                RowLayout {
                    Kirigami.FormData.label: i18n("Border color:")
                    enabled: customMode
                    QQC2.TextField { text: cfg_BorderColor; onTextChanged: cfg_BorderColor = text; Layout.fillWidth: true }
                    QQC2.Button { text: "…"; onClicked: { colorDialog.targetProp = "border"; colorDialog.selectedColor = cfg_BorderColor || "#888888"; colorDialog.open(); } }
                }

                QQC2.SpinBox {
                    id: borderWidthSpin
                    Kirigami.FormData.label: i18n("Border width:")
                    from: 0
                    to: 8
                }

                QQC2.SpinBox {
                    id: radiusSpin
                    Kirigami.FormData.label: i18n("Corner radius:")
                    from: -1
                    to: 32
                    textFromValue: (v) => v < 0 ? i18n("Follow theme") : (v + " px")
                }

                QQC2.TextField {
                    id: fontField
                    Kirigami.FormData.label: i18n("Font:")
                    enabled: customMode
                    placeholderText: i18n("Leave empty to follow Plasma")
                }

                QQC2.SpinBox {
                    id: fontSizeSpin
                    Kirigami.FormData.label: i18n("Font size:")
                    from: -1
                    to: 32
                    textFromValue: (v) => v < 0 ? i18n("Follow theme") : (v + " pt")
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Selected background:")
                    enabled: customMode
                    QQC2.TextField { text: cfg_SelectedBg; onTextChanged: cfg_SelectedBg = text; Layout.fillWidth: true }
                    QQC2.Button { text: "…"; onClicked: { colorDialog.targetProp = "selBg"; colorDialog.selectedColor = cfg_SelectedBg || "#3daee9"; colorDialog.open(); } }
                }
                RowLayout {
                    Kirigami.FormData.label: i18n("Selected foreground:")
                    enabled: customMode
                    QQC2.TextField { text: cfg_SelectedFg; onTextChanged: cfg_SelectedFg = text; Layout.fillWidth: true }
                    QQC2.Button { text: "…"; onClicked: { colorDialog.targetProp = "selFg"; colorDialog.selectedColor = cfg_SelectedFg || "#ffffff"; colorDialog.open(); } }
                }

                QQC2.SpinBox {
                    id: catIconSpin
                    Kirigami.FormData.label: i18n("Category icon size:")
                    from: 16
                    to: 64
                }
                QQC2.SpinBox {
                    id: appIconSpin
                    Kirigami.FormData.label: i18n("Application icon size:")
                    from: 16
                    to: 96
                }

                QQC2.Button {
                    text: i18n("Reset to defaults")
                    onClicked: {
                        cfg_ThemeMode = "system";
                        cfg_BgColor = "";
                        cfg_FgColor = "";
                        cfg_BorderColor = "";
                        cfg_BorderWidth = 1;
                        cfg_CornerRadius = -1;
                        cfg_Font = "";
                        cfg_FontSize = -1;
                        cfg_SelectedBg = "";
                        cfg_SelectedFg = "";
                        cfg_CategoryIconSize = 24;
                        cfg_AppIconSize = 24;
                        cfg_FollowColorScheme = true;
                        themeMode.currentIndex = 0;
                    }
                }
            }

            // Live preview
            Rectangle {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                Layout.preferredHeight: Kirigami.Units.gridUnit * 18
                radius: cfg_CornerRadius < 0 ? Kirigami.Units.cornerRadius : cfg_CornerRadius
                color: customMode && cfg_BgColor ? cfg_BgColor : Kirigami.Theme.backgroundColor
                border.width: cfg_BorderWidth
                border.color: customMode && cfg_BorderColor ? cfg_BorderColor : Kirigami.Theme.disabledTextColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        text: i18n("Preview")
                        font.bold: true
                        color: customMode && cfg_FgColor ? cfg_FgColor : Kirigami.Theme.textColor
                        font.family: cfg_Font || Kirigami.Theme.defaultFont.family
                        font.pointSize: cfg_FontSize > 0 ? cfg_FontSize : Kirigami.Theme.defaultFont.pointSize
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        radius: 4
                        color: customMode && cfg_SelectedBg ? cfg_SelectedBg : Kirigami.Theme.highlightColor
                        QQC2.Label {
                            anchors.centerIn: parent
                            text: i18n("Selected item")
                            color: customMode && cfg_SelectedFg ? cfg_SelectedFg : Kirigami.Theme.highlightedTextColor
                        }
                    }

                    QQC2.Label {
                        text: i18n("Application name")
                        color: customMode && cfg_FgColor ? cfg_FgColor : Kirigami.Theme.textColor
                        font.family: cfg_Font || Kirigami.Theme.defaultFont.family
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: customMode && lowContrast
            type: Kirigami.MessageType.Warning
            text: i18n("Foreground/background contrast appears below WCAG AA. Saving is still allowed, but readability may suffer.")
        }
    }

    Dialogs.ColorDialog {
        id: colorDialog
        property string targetProp: "bg"
        onAccepted: {
            var c = selectedColor.toString();
            if (targetProp === "bg") cfg_BgColor = c;
            else if (targetProp === "fg") cfg_FgColor = c;
            else if (targetProp === "border") cfg_BorderColor = c;
            else if (targetProp === "selBg") cfg_SelectedBg = c;
            else if (targetProp === "selFg") cfg_SelectedFg = c;
        }
    }
}
