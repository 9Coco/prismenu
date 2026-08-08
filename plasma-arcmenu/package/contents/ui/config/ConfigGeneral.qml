import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import "../../code/Locale.js" as Locale
import "../../code/ConfigBackup.js" as ConfigBackup

/**
 * General settings — Adw.ActionRow style (title/subtitle left, control right).
 */
Item {
    id: root

    property alias cfg_MenuHotkey: hotkeyField.text
    property string cfg_PopupAnimation
    property alias cfg_ShareConfigAcrossInstances: shareConfig.checked
    property alias cfg_FilterByActivity: filterActivity.checked
    property string cfg_UiLanguage

    readonly property string uiLang: Locale.resolveLanguage(cfg_UiLanguage || "zh_CN", Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    property string _ioMode: "" // export | import
    property string _statusText: ""
    property bool _statusIsError: false

    function filePathFromUrl(url) {
        var s = String(url || "");
        if (s.indexOf("file://") === 0)
            s = decodeURIComponent(s.substring(7));
        return s;
    }

    function syncLocalCfgFromConfig() {
        try {
            cfg_UiLanguage = plasmoid.configuration.uiLanguage || cfg_UiLanguage;
            cfg_MenuHotkey = plasmoid.configuration.menuHotkey || cfg_MenuHotkey;
            cfg_PopupAnimation = plasmoid.configuration.popupAnimation || cfg_PopupAnimation;
            cfg_ShareConfigAcrossInstances = !!plasmoid.configuration.shareConfigAcrossInstances;
            cfg_FilterByActivity = !!plasmoid.configuration.filterByActivity;
            var ids = ["zh_CN", "en", "system"];
            langCombo.currentIndex = Math.max(0, ids.indexOf(cfg_UiLanguage || "zh_CN"));
            var anims = ["expand", "fade", "slide", "none"];
            animCombo.currentIndex = Math.max(0, anims.indexOf(cfg_PopupAnimation || "expand"));
            hotkeyField.text = cfg_MenuHotkey;
            shareConfig.checked = cfg_ShareConfigAcrossInstances;
            filterActivity.checked = cfg_FilterByActivity;
        } catch (e) {}
    }

    function startExport(path) {
        _ioMode = "export";
        _statusText = "";
        _statusIsError = false;
        try {
            var jsonText = ConfigBackup.stringifyExport(plasmoid.configuration);
            ioExec.connectSource(ConfigBackup.writeFileCommand(path, jsonText));
        } catch (e) {
            _statusIsError = true;
            _statusText = root.tr("Export failed.") + " " + e;
        }
    }

    function startImport(path) {
        _ioMode = "import";
        _statusText = "";
        _statusIsError = false;
        try {
            ioExec.connectSource(ConfigBackup.readFileCommand(path));
        } catch (e) {
            _statusIsError = true;
            _statusText = root.tr("Import failed.") + " " + e;
        }
    }

    function applyImportedJson(text) {
        var parsed = ConfigBackup.parseImportText(text);
        var n = ConfigBackup.applySettings(plasmoid.configuration, parsed.settings);
        syncLocalCfgFromConfig();
        _statusIsError = false;
        _statusText = root.tr("Imported %1 settings. Click Apply to save.").replace("%1", String(n));
    }

    P5Support.DataSource {
        id: ioExec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            ioExec.disconnectSource(sourceName);
            var err = String((data && data.stderr) || "").trim();
            var out = String((data && data.stdout) || "");
            var exitCode = data && data["exit code"] !== undefined ? data["exit code"] : 0;
            if (root._ioMode === "export") {
                if (exitCode && Number(exitCode) !== 0) {
                    root._statusIsError = true;
                    root._statusText = root.tr("Export failed.") + (err ? (" " + err) : "");
                } else {
                    root._statusIsError = false;
                    root._statusText = root.tr("Configuration exported.");
                }
                root._ioMode = "";
                return;
            }
            if (root._ioMode === "import") {
                try {
                    if (exitCode && Number(exitCode) !== 0)
                        throw new Error(err || ("exit " + exitCode));
                    var jsonText = ConfigBackup.extractJsonFromStdout(out);
                    root.applyImportedJson(jsonText);
                } catch (e) {
                    root._statusIsError = true;
                    root._statusText = root.tr("Import failed.") + " " + e;
                }
                root._ioMode = "";
            }
        }
    }

    component SettingRow: RowLayout {
        id: srow
        property string title: ""
        property string subtitle: ""
        default property alias trailing: trail.data

        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 8
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            QQC2.Label {
                text: srow.title
                Layout.fillWidth: true
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
            }
            QQC2.Label {
                visible: srow.subtitle.length > 0
                text: srow.subtitle
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.6
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }

        RowLayout {
            id: trail
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            spacing: Kirigami.Units.smallSpacing
        }
    }

    component GroupCard: Rectangle {
        id: card
        default property alias content: inner.data
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: Kirigami.Units.smallSpacing
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

        ColumnLayout {
            id: inner
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label { text: root.tr("Language"); font.bold: true }

            GroupCard {
                SettingRow {
                    title: root.tr("Menu language")
                    subtitle: root.tr("Applies to the settings dialog and menu labels.")
                    QQC2.ComboBox {
                        id: langCombo
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
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
                }
            }

            QQC2.Label { text: root.tr("Behavior"); font.bold: true }

            GroupCard {
                SettingRow {
                    title: root.tr("Menu hotkey")
                    subtitle: root.tr("Must not conflict with Plasma global shortcuts.")
                    QQC2.TextField {
                        id: hotkeyField
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        placeholderText: "Meta"
                    }
                }
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2 }
                SettingRow {
                    title: root.tr("Popup animation")
                    QQC2.ComboBox {
                        id: animCombo
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        textRole: "label"
                        valueRole: "value"
                        model: [
                            { label: root.tr("Expand from button"), value: "expand" },
                            { label: root.tr("Fade"), value: "fade" },
                            { label: root.tr("Slide"), value: "slide" },
                            { label: root.tr("None"), value: "none" }
                        ]
                        Component.onCompleted: {
                            var values = ["expand", "fade", "slide", "none"];
                            currentIndex = Math.max(0, values.indexOf(cfg_PopupAnimation));
                        }
                        onActivated: cfg_PopupAnimation = currentValue
                    }
                }
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2 }
                SettingRow {
                    title: root.tr("Multi-instance")
                    subtitle: root.tr("Share configuration across panel instances")
                    QQC2.Switch {
                        id: shareConfig
                    }
                }
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2 }
                SettingRow {
                    title: root.tr("Activities")
                    subtitle: root.tr("Filter favorites/recent by Plasma Activity (optional)")
                    QQC2.Switch {
                        id: filterActivity
                    }
                }
            }

            QQC2.Label { text: root.tr("Backup"); font.bold: true }

            GroupCard {
                SettingRow {
                    title: root.tr("Export configuration")
                    subtitle: root.tr("Save all Arc Menu settings to a JSON file.")
                    QQC2.Button {
                        text: root.tr("Export…")
                        onClicked: exportDialog.open()
                    }
                }
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2 }
                SettingRow {
                    title: root.tr("Import configuration")
                    subtitle: root.tr("Load settings from a JSON file. Existing values are overwritten.")
                    QQC2.Button {
                        text: root.tr("Import…")
                        onClicked: importDialog.open()
                    }
                }
            }

            Kirigami.InlineMessage {
                Layout.fillWidth: true
                visible: root._statusText.length > 0
                type: root._statusIsError ? Kirigami.MessageType.Error : Kirigami.MessageType.Positive
                text: root._statusText
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.55
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                text: root.tr("Display style, icon, click actions and button style are under Menu Button. Layout and content settings are under Menu.")
            }

            Item { Layout.preferredHeight: Kirigami.Units.largeSpacing }
        }
    }

    Dialogs.FileDialog {
        id: exportDialog
        title: root.tr("Export configuration")
        fileMode: Dialogs.FileDialog.SaveFile
        nameFilters: [root.tr("JSON files (*.json)"), root.tr("All files (*)")]
        defaultSuffix: "json"
        Component.onCompleted: {
            try { selectedFile = "file://" + ConfigBackup.defaultExportFileName(); } catch (e) {}
        }
        onAccepted: {
            var path = root.filePathFromUrl(selectedFile);
            if (!path)
                return;
            if (path.toLowerCase().indexOf(".json") < 0)
                path += ".json";
            root.startExport(path);
        }
    }

    Dialogs.FileDialog {
        id: importDialog
        title: root.tr("Import configuration")
        fileMode: Dialogs.FileDialog.OpenFile
        nameFilters: [root.tr("JSON files (*.json)"), root.tr("All files (*)")]
        onAccepted: {
            var path = root.filePathFromUrl(selectedFile);
            if (!path)
                return;
            importConfirm.path = path;
            importConfirm.open();
        }
    }

    QQC2.Dialog {
        id: importConfirm
        property string path: ""
        title: root.tr("Import configuration")
        modal: true
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No
        QQC2.Label {
            text: root.tr("Import settings from this file? Current values will be overwritten.")
            wrapMode: Text.WordWrap
            width: importConfirm.availableWidth
        }
        onAccepted: root.startImport(path)
    }
}
