import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Distro.js" as Distro
import "../../code/Locale.js" as Locale

Item {
    id: root

    property string cfg_ButtonIcon
    property alias cfg_CustomButtonIcon: customIconField.text
    property alias cfg_ButtonLabelVisible: labelVisible.checked
    property alias cfg_ButtonLabelText: labelText.text
    property alias cfg_MenuHotkey: hotkeyField.text
    property string cfg_PopupAnimation
    property alias cfg_ShareConfigAcrossInstances: shareConfig.checked
    property alias cfg_FilterByActivity: filterActivity.checked
    property string cfg_UiLanguage

    readonly property string uiLang: Locale.resolveLanguage(cfg_UiLanguage || "system", Qt.locale().name)

    function tr(msgid) {
        return Locale.tr(msgid, uiLang);
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.ComboBox {
            id: langCombo
            Kirigami.FormData.label: root.tr("Menu language:")
            textRole: "label"
            valueRole: "id"
            model: [
                { id: "zh_CN", label: root.tr("Chinese (Simplified)") },
                { id: "en", label: root.tr("English") },
                { id: "system", label: root.tr("Follow system") }
            ]
            Component.onCompleted: {
                var ids = ["zh_CN", "en", "system"];
                var cur = cfg_UiLanguage || "zh_CN";
                currentIndex = Math.max(0, ids.indexOf(cur));
            }
            onActivated: {
                cfg_UiLanguage = currentValue;
                try { plasmoid.configuration.uiLanguage = currentValue; } catch (e) {}
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: root.tr("UI language applies to menu labels (categories, places, actions).")
        }

        QQC2.ComboBox {
            id: iconCombo
            Kirigami.FormData.label: i18n("Button icon:")
            textRole: "name"
            valueRole: "id"
            model: Distro.builtinIcons()
            Component.onCompleted: {
                var ids = Distro.builtinIcons().map(function (i) { return i.id; });
                var idx = ids.indexOf(cfg_ButtonIcon);
                currentIndex = idx >= 0 ? idx : 0;
            }
            onActivated: cfg_ButtonIcon = currentValue
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Custom icon path:")
            enabled: iconCombo.currentValue === "custom"
            QQC2.TextField {
                id: customIconField
                Layout.fillWidth: true
                placeholderText: i18n("/path/to/icon.svg")
            }
            QQC2.Button {
                text: i18n("Browse…")
                onClicked: fileDialog.open()
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: iconCombo.currentValue === "custom" && customIconField.text.length > 0 && !Distro.isLikelyImagePath(customIconField.text)
            type: Kirigami.MessageType.Warning
            text: i18n("Custom icon path looks invalid or is not an image. The distribution logo will be used as fallback.")
        }

        QQC2.CheckBox {
            id: labelVisible
            Kirigami.FormData.label: i18n("Show text label:")
            text: i18n("Display label next to the icon")
        }

        QQC2.TextField {
            id: labelText
            Kirigami.FormData.label: i18n("Label text:")
            enabled: labelVisible.checked
        }

        QQC2.TextField {
            id: hotkeyField
            Kirigami.FormData.label: i18n("Menu hotkey:")
            placeholderText: "Meta"
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18n("Hotkeys must not conflict with Plasma global shortcuts. Rebind if Plasma reports a conflict.")
        }

        QQC2.ComboBox {
            id: animCombo
            Kirigami.FormData.label: i18n("Popup animation:")
            textRole: "label"
            valueRole: "value"
            model: [
                { label: i18n("Expand from button"), value: "expand" },
                { label: i18n("Fade"), value: "fade" },
                { label: i18n("Slide"), value: "slide" },
                { label: i18n("None"), value: "none" }
            ]
            Component.onCompleted: {
                var values = ["expand", "fade", "slide", "none"];
                currentIndex = Math.max(0, values.indexOf(cfg_PopupAnimation));
            }
            onActivated: cfg_PopupAnimation = currentValue
        }

        QQC2.CheckBox {
            id: shareConfig
            Kirigami.FormData.label: i18n("Multi-instance:")
            text: i18n("Share configuration across panel instances")
        }

        QQC2.CheckBox {
            id: filterActivity
            Kirigami.FormData.label: i18n("Activities:")
            text: i18n("Filter favorites/recent by Plasma Activity (optional)")
        }
    }

    Dialogs.FileDialog {
        id: fileDialog
        title: i18n("Choose custom icon")
        nameFilters: [i18n("Images (*.png *.svg *.jpg *.jpeg *.webp)"), i18n("All files (*)")]
        onAccepted: customIconField.text = selectedFile.toString().replace("file://", "")
    }
}
