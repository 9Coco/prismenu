import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Theme.js" as ThemeHelper
import "../../code/Locale.js" as Locale

/**
 * Menu Theme settings — ConfigPage chrome.
 */
Item {
    id: root

    property string cfg_ThemeMode
    property bool cfg_OverrideMenuTheme
    property string cfg_MenuThemeName
    property string cfg_CustomThemes
    property string cfg_BgColor
    property string cfg_FgColor
    property string cfg_BorderColor
    property int cfg_BorderWidth
    property int cfg_CornerRadius
    property string cfg_Font
    property int cfg_FontSize
    property string cfg_SeparatorColor
    property string cfg_HoverBg
    property string cfg_HoverFg
    property string cfg_ActiveBg
    property string cfg_ActiveFg
    property string cfg_SelectedBg
    property string cfg_SelectedFg
    property int cfg_CategoryIconSize
    property int cfg_AppIconSize
    property bool cfg_FollowColorScheme

    readonly property bool overrideOn: cfg_OverrideMenuTheme || cfg_ThemeMode === "custom"
    readonly property bool lowContrast: ThemeHelper.hasLowContrast(cfg_FgColor, cfg_BgColor)

    readonly property var presetList: ThemeHelper.allPresets(cfg_CustomThemes || "[]")
    readonly property var presetNames: {
        var names = [];
        for (var i = 0; i < presetList.length; ++i)
            names.push(presetList[i].name);
        return names;
    }

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    function syncOverride(on) {
        cfg_OverrideMenuTheme = on;
        cfg_ThemeMode = on ? "custom" : "system";
        try {
            plasmoid.configuration.overrideMenuTheme = on;
            plasmoid.configuration.themeMode = cfg_ThemeMode;
        } catch (e) {}
    }

    function writeLive(key, value) {
        try { plasmoid.configuration[key] = value; } catch (e) {}
    }

    function applyPreset(theme) {
        if (!theme)
            return;
        cfg_MenuThemeName = theme.name || "";
        cfg_BgColor = theme.bg || "";
        cfg_FgColor = theme.fg || "";
        cfg_BorderColor = theme.border || "";
        cfg_BorderWidth = theme.borderWidth !== undefined ? theme.borderWidth : 1;
        cfg_CornerRadius = theme.cornerRadius !== undefined ? theme.cornerRadius : 14;
        cfg_FontSize = theme.fontSize !== undefined ? theme.fontSize : 11;
        cfg_SeparatorColor = theme.separator || "";
        cfg_HoverBg = theme.hoverBg || "";
        cfg_HoverFg = theme.hoverFg || "";
        cfg_ActiveBg = theme.activeBg || "";
        cfg_ActiveFg = theme.activeFg || "";
        cfg_SelectedBg = cfg_ActiveBg;
        cfg_SelectedFg = cfg_ActiveFg;
        borderWidthSpin.value = cfg_BorderWidth;
        radiusSpin.value = cfg_CornerRadius;
        fontSizeSpin.value = cfg_FontSize;
        syncOverride(true);
        writeLive("menuThemeName", cfg_MenuThemeName);
        writeLive("bgColor", cfg_BgColor);
        writeLive("fgColor", cfg_FgColor);
        writeLive("borderColor", cfg_BorderColor);
        writeLive("borderWidth", cfg_BorderWidth);
        writeLive("cornerRadius", cfg_CornerRadius);
        writeLive("fontSize", cfg_FontSize);
        writeLive("separatorColor", cfg_SeparatorColor);
        writeLive("hoverBg", cfg_HoverBg);
        writeLive("hoverFg", cfg_HoverFg);
        writeLive("activeBg", cfg_ActiveBg);
        writeLive("activeFg", cfg_ActiveFg);
        writeLive("selectedBg", cfg_SelectedBg);
        writeLive("selectedFg", cfg_SelectedFg);
    }

    function currentColorsAsTheme(name) {
        return {
            name: name,
            bg: cfg_BgColor,
            fg: cfg_FgColor,
            border: cfg_BorderColor,
            borderWidth: cfg_BorderWidth,
            cornerRadius: cfg_CornerRadius,
            fontSize: cfg_FontSize,
            separator: cfg_SeparatorColor,
            hoverBg: cfg_HoverBg,
            hoverFg: cfg_HoverFg,
            activeBg: cfg_ActiveBg,
            activeFg: cfg_ActiveFg
        };
    }

    function saveAsTheme(name) {
        name = String(name || "").trim();
        if (!name)
            return;
        if (ThemeHelper.isBuiltinName(name))
            name = name + " (custom)";
        var customs = ThemeHelper.parseCustomThemesJson(cfg_CustomThemes || "[]");
        var next = [];
        var replaced = false;
        for (var i = 0; i < customs.length; ++i) {
            if (customs[i].name === name) {
                next.push(currentColorsAsTheme(name));
                replaced = true;
            } else {
                next.push(customs[i]);
            }
        }
        if (!replaced)
            next.push(currentColorsAsTheme(name));
        cfg_CustomThemes = ThemeHelper.customThemesToJson(next);
        cfg_MenuThemeName = name;
        writeLive("customThemes", cfg_CustomThemes);
        writeLive("menuThemeName", cfg_MenuThemeName);
        themeCombo.model = root.presetNames;
        themeCombo.currentIndex = Math.max(0, root.presetNames.indexOf(name));
    }

    function deleteCurrentCustom() {
        var name = cfg_MenuThemeName;
        if (!name || ThemeHelper.isBuiltinName(name))
            return;
        var customs = ThemeHelper.parseCustomThemesJson(cfg_CustomThemes || "[]");
        var next = [];
        for (var i = 0; i < customs.length; ++i) {
            if (customs[i].name !== name)
                next.push(customs[i]);
        }
        cfg_CustomThemes = ThemeHelper.customThemesToJson(next);
        writeLive("customThemes", cfg_CustomThemes);
        applyPreset(ThemeHelper.builtinPresets()[0]);
        themeCombo.model = root.presetNames;
        themeCombo.currentIndex = 0;
    }

    function resetToDefaults() {
        syncOverride(false);
        cfg_MenuThemeName = "ArcMenu Style";
        cfg_BgColor = "";
        cfg_FgColor = "";
        cfg_BorderColor = "";
        cfg_BorderWidth = 1;
        cfg_CornerRadius = -1;
        cfg_Font = "";
        cfg_FontSize = -1;
        cfg_SeparatorColor = "";
        cfg_HoverBg = "";
        cfg_HoverFg = "";
        cfg_ActiveBg = "";
        cfg_ActiveFg = "";
        cfg_SelectedBg = "";
        cfg_SelectedFg = "";
        cfg_CategoryIconSize = 24;
        cfg_AppIconSize = 24;
        cfg_FollowColorScheme = true;
        borderWidthSpin.value = 1;
        radiusSpin.value = -1;
        fontSizeSpin.value = -1;
        catIconSpin.value = 24;
        appIconSpin.value = 24;
        themeCombo.currentIndex = Math.max(0, root.presetNames.indexOf("ArcMenu Style"));
        writeLive("menuThemeName", cfg_MenuThemeName);
        writeLive("bgColor", cfg_BgColor);
        writeLive("fgColor", cfg_FgColor);
        writeLive("borderColor", cfg_BorderColor);
        writeLive("borderWidth", cfg_BorderWidth);
        writeLive("cornerRadius", cfg_CornerRadius);
        writeLive("font", cfg_Font);
        writeLive("fontSize", cfg_FontSize);
        writeLive("separatorColor", cfg_SeparatorColor);
        writeLive("hoverBg", cfg_HoverBg);
        writeLive("hoverFg", cfg_HoverFg);
        writeLive("activeBg", cfg_ActiveBg);
        writeLive("activeFg", cfg_ActiveFg);
        writeLive("selectedBg", cfg_SelectedBg);
        writeLive("selectedFg", cfg_SelectedFg);
        writeLive("categoryIconSize", cfg_CategoryIconSize);
        writeLive("appIconSize", cfg_AppIconSize);
        writeLive("followColorScheme", cfg_FollowColorScheme);
    }

    component ColorRow: ConfigSettingRow {
        id: colorRow
        property string colorValue: ""
        property string propKey: ""
        property bool rowEnabled: true
        signal colorEdited(string value)

        enabled: colorRow.rowEnabled
        opacity: rowEnabled ? 1 : 0.45

        Rectangle {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
            radius: 3
            border.width: 1
            border.color: Kirigami.Theme.disabledTextColor
            color: {
                if (!colorRow.colorValue || colorRow.colorValue === "")
                    return "transparent";
                try { return colorRow.colorValue; } catch (e) { return "transparent"; }
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                visible: !colorRow.colorValue || colorRow.colorValue === ""
                gradient: Gradient {
                    GradientStop { position: 0; color: "#cccccc" }
                    GradientStop { position: 1; color: "#888888" }
                }
                opacity: 0.5
            }
            MouseArea {
                anchors.fill: parent
                enabled: colorRow.rowEnabled
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    colorDialog.targetProp = colorRow.propKey;
                    colorDialog.selectedColor = colorRow.colorValue || "#808080";
                    colorDialog.open();
                }
            }
        }
        QQC2.TextField {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            enabled: colorRow.rowEnabled
            text: colorRow.colorValue
            placeholderText: "rgb() / #RRGGBB"
            onEditingFinished: colorRow.colorEdited(text)
            onTextChanged: {
                if (activeFocus)
                    colorRow.colorEdited(text);
            }
        }
    }

    ConfigPage {
        title: root.tr("Menu Theme")
        tip: root.tr("Modify menu colors, font size, and border")

        ConfigGroup {
            title: root.tr("Theme")
            ConfigSettingRow {
                title: root.tr("Override theme")
                subtitle: root.tr("Results may vary with third-party Plasma themes.")
                iconName: "preferences-desktop-theme"
                accent: "blue"
                QQC2.Switch {
                    id: overrideSwitch
                    checked: root.overrideOn
                    onToggled: {
                        syncOverride(checked);
                        if (checked && (!cfg_BgColor || cfg_BgColor === "")) {
                            var t = ThemeHelper.findPreset(cfg_MenuThemeName || "ArcMenu Style", cfg_CustomThemes);
                            if (t)
                                applyPreset(t);
                        }
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Current theme:")
                iconName: "color-management"
                accent: "purple"
                opacity: root.overrideOn ? 1 : 0.45
                QQC2.ComboBox {
                    id: themeCombo
                    enabled: root.overrideOn
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                    model: root.presetNames
                    Component.onCompleted: {
                        var idx = root.presetNames.indexOf(cfg_MenuThemeName || "ArcMenu Style");
                        currentIndex = idx >= 0 ? idx : 0;
                    }
                    onActivated: {
                        var name = model[currentIndex];
                        var t = ThemeHelper.findPreset(name, cfg_CustomThemes);
                        if (t)
                            applyPreset(t);
                    }
                }
                QQC2.Button {
                    text: root.tr("Save as theme")
                    enabled: root.overrideOn
                    onClicked: {
                        saveNameField.text = cfg_MenuThemeName && !ThemeHelper.isBuiltinName(cfg_MenuThemeName)
                            ? cfg_MenuThemeName : "";
                        saveDialog.open();
                    }
                }
                QQC2.Button {
                    text: root.tr("Delete theme")
                    enabled: root.overrideOn && cfg_MenuThemeName && !ThemeHelper.isBuiltinName(cfg_MenuThemeName)
                    onClicked: deleteCurrentCustom()
                }
            }
        }

        ConfigGroup {
            title: root.tr("Menu style")
            ColorRow {
                title: root.tr("Background color:")
                iconName: "fill-color"
                accent: "blue"
                colorValue: cfg_BgColor
                propKey: "bg"
                rowEnabled: root.overrideOn
                onColorEdited: (v) => { cfg_BgColor = v; writeLive("bgColor", v); }
            }
            ConfigSep {}
            ColorRow {
                title: root.tr("Foreground color:")
                iconName: "format-text-color"
                accent: "purple"
                colorValue: cfg_FgColor
                propKey: "fg"
                rowEnabled: root.overrideOn
                onColorEdited: (v) => { cfg_FgColor = v; writeLive("fgColor", v); }
            }
            ConfigSep {}
            ColorRow {
                title: root.tr("Border color:")
                iconName: "object-stroke-style"
                accent: "teal"
                colorValue: cfg_BorderColor
                propKey: "border"
                rowEnabled: root.overrideOn
                onColorEdited: (v) => { cfg_BorderColor = v; writeLive("borderColor", v); }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Border width:")
                iconName: "resizecol"
                accent: "orange"
                opacity: root.overrideOn ? 1 : 0.45
                QQC2.SpinBox {
                    id: borderWidthSpin
                    enabled: root.overrideOn
                    from: 0; to: 8
                    value: cfg_BorderWidth
                    onValueModified: {
                        cfg_BorderWidth = value;
                        writeLive("borderWidth", value);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Border corner radius:")
                iconName: "draw-square-rounded"
                accent: "green"
                opacity: root.overrideOn ? 1 : 0.45
                QQC2.SpinBox {
                    id: radiusSpin
                    enabled: root.overrideOn
                    from: -1; to: 32
                    value: cfg_CornerRadius
                    textFromValue: (v) => v < 0 ? root.tr("Follow theme") : String(v)
                    onValueModified: {
                        cfg_CornerRadius = value;
                        writeLive("cornerRadius", value);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Font size:")
                iconName: "font-size"
                accent: "cyan"
                opacity: root.overrideOn ? 1 : 0.45
                QQC2.SpinBox {
                    id: fontSizeSpin
                    enabled: root.overrideOn
                    from: -1; to: 32
                    value: cfg_FontSize
                    textFromValue: (v) => v < 0 ? root.tr("Follow theme") : String(v)
                    onValueModified: {
                        cfg_FontSize = value;
                        writeLive("fontSize", value);
                    }
                }
            }
            ConfigSep {}
            ColorRow {
                title: root.tr("Separator color:")
                iconName: "view-split-left-right"
                accent: "indigo"
                colorValue: cfg_SeparatorColor
                propKey: "sep"
                rowEnabled: root.overrideOn
                onColorEdited: (v) => { cfg_SeparatorColor = v; writeLive("separatorColor", v); }
            }
        }

        ConfigGroup {
            title: root.tr("Menu item style")
            ColorRow {
                title: root.tr("Hover background color:")
                iconName: "fill-color"
                accent: "blue"
                colorValue: cfg_HoverBg
                propKey: "hoverBg"
                rowEnabled: root.overrideOn
                onColorEdited: (v) => { cfg_HoverBg = v; writeLive("hoverBg", v); }
            }
            ConfigSep {}
            ColorRow {
                title: root.tr("Hover foreground color:")
                iconName: "format-text-color"
                accent: "purple"
                colorValue: cfg_HoverFg
                propKey: "hoverFg"
                rowEnabled: root.overrideOn
                onColorEdited: (v) => { cfg_HoverFg = v; writeLive("hoverFg", v); }
            }
            ConfigSep {}
            ColorRow {
                title: root.tr("Active background color:")
                iconName: "fill-color"
                accent: "teal"
                colorValue: cfg_ActiveBg
                propKey: "activeBg"
                rowEnabled: root.overrideOn
                onColorEdited: (v) => {
                    cfg_ActiveBg = v;
                    cfg_SelectedBg = v;
                    writeLive("activeBg", v);
                    writeLive("selectedBg", v);
                }
            }
            ConfigSep {}
            ColorRow {
                title: root.tr("Active foreground color:")
                iconName: "format-text-color"
                accent: "orange"
                colorValue: cfg_ActiveFg
                propKey: "activeFg"
                rowEnabled: root.overrideOn
                onColorEdited: (v) => {
                    cfg_ActiveFg = v;
                    cfg_SelectedFg = v;
                    writeLive("activeFg", v);
                    writeLive("selectedFg", v);
                }
            }
        }

        ConfigGroup {
            title: root.tr("Icons")
            ConfigSettingRow {
                title: root.tr("Category icon size:")
                iconName: "view-categories"
                accent: "green"
                QQC2.SpinBox {
                    id: catIconSpin
                    from: 16; to: 64
                    value: cfg_CategoryIconSize
                    onValueModified: {
                        cfg_CategoryIconSize = value;
                        writeLive("categoryIconSize", value);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Application icon size:")
                iconName: "applications-all"
                accent: "pink"
                QQC2.SpinBox {
                    id: appIconSpin
                    from: 16; to: 96
                    value: cfg_AppIconSize
                    onValueModified: {
                        cfg_AppIconSize = value;
                        writeLive("appIconSize", value);
                    }
                }
            }
        }

        ConfigGroup {
            title: root.tr("Preview")
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 8 + Kirigami.Units.largeSpacing * 2
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    radius: cfg_CornerRadius < 0 ? Kirigami.Units.cornerRadius : cfg_CornerRadius
                    color: root.overrideOn && cfg_BgColor ? cfg_BgColor : Kirigami.Theme.backgroundColor
                    border.width: cfg_BorderWidth
                    border.color: root.overrideOn && cfg_BorderColor ? cfg_BorderColor : Kirigami.Theme.disabledTextColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing / 2

                        QQC2.Label {
                            text: root.tr("Preview")
                            font.bold: true
                            color: root.overrideOn && cfg_FgColor ? cfg_FgColor : Kirigami.Theme.textColor
                            font.pointSize: cfg_FontSize > 0 ? cfg_FontSize : Kirigami.Theme.defaultFont.pointSize
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.8
                            radius: 4
                            color: root.overrideOn && cfg_HoverBg ? cfg_HoverBg : Kirigami.Theme.highlightColor
                            QQC2.Label {
                                anchors.centerIn: parent
                                text: root.tr("Hover item")
                                color: root.overrideOn && cfg_HoverFg ? cfg_HoverFg : Kirigami.Theme.highlightedTextColor
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.8
                            radius: 4
                            color: root.overrideOn && cfg_ActiveBg ? cfg_ActiveBg : Kirigami.Theme.highlightColor
                            QQC2.Label {
                                anchors.centerIn: parent
                                text: root.tr("Active item")
                                color: root.overrideOn && cfg_ActiveFg ? cfg_ActiveFg : Kirigami.Theme.highlightedTextColor
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: root.overrideOn && cfg_SeparatorColor ? cfg_SeparatorColor : Kirigami.Theme.disabledTextColor
                            opacity: root.overrideOn && cfg_SeparatorColor ? 1 : 0.4
                        }
                    }
                }
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: root.overrideOn && root.lowContrast
            type: Kirigami.MessageType.Warning
            text: root.tr("Foreground/background contrast appears below WCAG AA. Saving is still allowed, but readability may suffer.")
        }

        QQC2.Button {
            text: root.tr("Reset to defaults")
            onClicked: resetToDefaults()
        }
    }

    Dialogs.ColorDialog {
        id: colorDialog
        property string targetProp: "bg"
        onAccepted: {
            var c = selectedColor.toString();
            if (targetProp === "bg") { cfg_BgColor = c; writeLive("bgColor", c); }
            else if (targetProp === "fg") { cfg_FgColor = c; writeLive("fgColor", c); }
            else if (targetProp === "border") { cfg_BorderColor = c; writeLive("borderColor", c); }
            else if (targetProp === "sep") { cfg_SeparatorColor = c; writeLive("separatorColor", c); }
            else if (targetProp === "hoverBg") { cfg_HoverBg = c; writeLive("hoverBg", c); }
            else if (targetProp === "hoverFg") { cfg_HoverFg = c; writeLive("hoverFg", c); }
            else if (targetProp === "activeBg") {
                cfg_ActiveBg = c; cfg_SelectedBg = c;
                writeLive("activeBg", c); writeLive("selectedBg", c);
            } else if (targetProp === "activeFg") {
                cfg_ActiveFg = c; cfg_SelectedFg = c;
                writeLive("activeFg", c); writeLive("selectedFg", c);
            }
        }
    }

    QQC2.Dialog {
        id: saveDialog
        title: root.tr("Save as theme")
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        modal: true
        anchors.centerIn: parent

        ColumnLayout {
            anchors.fill: parent
            QQC2.Label { text: root.tr("Theme name:") }
            QQC2.TextField {
                id: saveNameField
                Layout.fillWidth: true
                placeholderText: root.tr("My theme")
            }
        }

        onAccepted: root.saveAsTheme(saveNameField.text)
    }

    Component.onCompleted: {
        if (cfg_OverrideMenuTheme || cfg_ThemeMode === "custom")
            syncOverride(true);
        borderWidthSpin.value = cfg_BorderWidth >= 0 ? cfg_BorderWidth : 1;
        radiusSpin.value = cfg_CornerRadius;
        fontSizeSpin.value = cfg_FontSize;
        catIconSpin.value = cfg_CategoryIconSize || 24;
        appIconSpin.value = cfg_AppIconSize || 24;
        if ((!cfg_ActiveBg || cfg_ActiveBg === "") && cfg_SelectedBg) {
            cfg_ActiveBg = cfg_SelectedBg;
            writeLive("activeBg", cfg_ActiveBg);
        }
        if ((!cfg_ActiveFg || cfg_ActiveFg === "") && cfg_SelectedFg) {
            cfg_ActiveFg = cfg_SelectedFg;
            writeLive("activeFg", cfg_ActiveFg);
        }
    }
}
