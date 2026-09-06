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
 * General settings — shared ConfigPage / ConfigGroup chrome.
 */
Item {
    id: root

    property alias cfg_MenuHotkey: hotkeyField.text
    property string cfg_PopupAnimation
    property alias cfg_ShareConfigAcrossInstances: shareConfig.checked
    property alias cfg_FilterByActivity: filterActivity.checked
    property string cfg_UiLanguage

    // ---- camelCase compatibility aliases ---------------------------------
    // Plasma hosts inject and read cfg_<key> using the lowercase-first names
    // from KConfigPropertyMap. Without these, injection silently fails and
    // a save-time read-back can wipe live-edited values back to defaults.
    property alias cfg_menuHotkey: root.cfg_MenuHotkey
    property alias cfg_popupAnimation: root.cfg_PopupAnimation
    property alias cfg_shareConfigAcrossInstances: root.cfg_ShareConfigAcrossInstances
    property alias cfg_filterByActivity: root.cfg_FilterByActivity
    property alias cfg_uiLanguage: root.cfg_UiLanguage

    readonly property string uiLang: Locale.resolveLanguage(cfg_UiLanguage || "zh_CN", Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    // Live apply: every cfg_* write must also land in plasmoid.configuration,
    // otherwise Plasma's cfg-vs-config diff flags the page as "unsaved".
    function writeLive(key, value) { try { plasmoid.configuration[key] = value; } catch (e) {} }

    property string _ioMode: ""
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
            cfg_UiLanguage = plasmoid.configuration.UiLanguage || cfg_UiLanguage;
            cfg_MenuHotkey = plasmoid.configuration.MenuHotkey || cfg_MenuHotkey;
            cfg_PopupAnimation = plasmoid.configuration.PopupAnimation || cfg_PopupAnimation;
            cfg_ShareConfigAcrossInstances = !!plasmoid.configuration.ShareConfigAcrossInstances;
            cfg_FilterByActivity = !!plasmoid.configuration.FilterByActivity;
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
        _statusText = root.tr("Imported %1 settings. Changes are applied immediately.").replace("%1", String(n));
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

    ConfigPage {
        title: root.tr("General")
        tip: root.tr("Changes are applied immediately. Some settings take effect after reopening the menu.")

        ConfigGroup {
            title: root.tr("Language")
            ConfigSettingRow {
                title: root.tr("Menu language")
                subtitle: root.tr("Applies to the settings dialog and menu labels.")
                iconName: "preferences-desktop-locale"
                accent: "blue"
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
                        currentIndex = Math.max(0, ids.indexOf(cfg_UiLanguage || "zh_CN"));
                    }
                    onActivated: {
                        cfg_UiLanguage = currentValue;
                        try { plasmoid.configuration.UiLanguage = currentValue; } catch (e) {}
                    }
                }
            }
        }

        ConfigGroup {
            title: root.tr("Behavior")
            ConfigSettingRow {
                title: root.tr("Menu hotkey")
                subtitle: root.tr("Must not conflict with Plasma global shortcuts.")
                iconName: "input-keyboard-symbolic"
                accent: "purple"
                QQC2.TextField {
                    id: hotkeyField
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    placeholderText: "Meta"
                    onEditingFinished: root.writeLive("MenuHotkey", text)
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Popup animation")
                subtitle: root.tr("Animation when opening the menu")
                iconName: "preferences-desktop-effects"
                accent: "teal"
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
                    onActivated: {
                        cfg_PopupAnimation = currentValue;
                        root.writeLive("PopupAnimation", currentValue);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Multi-instance")
                subtitle: root.tr("Share configuration across panel instances")
                iconName: "window-duplicate"
                accent: "green"
                QQC2.Switch {
                    id: shareConfig
                    onToggled: root.writeLive("ShareConfigAcrossInstances", checked)
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Activities")
                subtitle: root.tr("Filter favorites/recent by Plasma Activity (optional)")
                iconName: "preferences-desktop-activities"
                accent: "orange"
                QQC2.Switch {
                    id: filterActivity
                    onToggled: root.writeLive("FilterByActivity", checked)
                }
            }
        }

        ConfigGroup {
            title: root.tr("Backup")
            ConfigSettingRow {
                title: root.tr("Export configuration")
                subtitle: root.tr("Save all Prismenu settings to a JSON file.")
                iconName: "document-export"
                accent: "cyan"
                QQC2.Button {
                    text: root.tr("Export…")
                    onClicked: exportDialog.open()
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Import configuration")
                subtitle: root.tr("Load settings from a JSON file. Existing values are overwritten.")
                iconName: "document-import"
                accent: "pink"
                QQC2.Button {
                    text: root.tr("Import…")
                    onClicked: importDialog.open()
                }
            }
        }

        ConfigGroup {
            title: root.tr("Reset")
            ConfigSettingRow {
                title: root.tr("Reset to defaults")
                subtitle: root.tr("Restore all Prismenu settings to their default values.")
                iconName: "edit-undo"
                accent: "red"
                QQC2.Button {
                    text: root.tr("Reset…")
                    onClicked: resetConfirm.open()
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
        id: resetConfirm
        title: root.tr("Reset to defaults")
        modal: true
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No
        QQC2.Label {
            text: root.tr("Reset all Prismenu settings to their default values? This cannot be undone.")
            wrapMode: Text.WordWrap
            width: resetConfirm.availableWidth
        }
        onAccepted: {
            var n = ConfigBackup.resetToDefaults(plasmoid.configuration);
            root.syncLocalCfgFromConfig();
            root._statusIsError = false;
            root._statusText = root.tr("Restored %1 settings to defaults.").replace("%1", String(n));
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
