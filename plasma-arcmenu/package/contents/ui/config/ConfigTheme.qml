import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Theme.js" as ThemeHelper
import "../../code/Locale.js" as Locale

/**
 * Menu Theme settings — mirrors GNOME ArcMenu:
 * Override toggle → preset picker → Menu Style / Menu Item Style + Save as Theme
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

    function tr(msgid) {
        return Locale.tr(msgid, uiLang);
    }

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
        if (ThemeHelper.isBuiltinName(name)) {
            // Saving over a built-in name → store as custom copy with suffix
            name = name + " (custom)";
        }
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
    }

    component ColorRow: RowLayout {
        id: colorRow
        property string label: ""
        property string colorValue: ""
        property string propKey: ""
        signal colorEdited(string value)

        Kirigami.FormData.label: colorRow.label
        enabled: root.overrideOn
        spacing: Kirigami.Units.smallSpacing

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
            // Checkerboard hint when empty / transparent-looking
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
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    colorDialog.targetProp = colorRow.propKey;
                    colorDialog.selectedColor = colorRow.colorValue || "#808080";
                    colorDialog.open();
                }
            }
        }

        QQC2.TextField {
            Layout.fillWidth: true
            text: colorRow.colorValue
            placeholderText: "rgb() / #RRGGBB"
            onEditingFinished: colorRow.colorEdited(text)
            onTextChanged: {
                if (activeFocus)
                    colorRow.colorEdited(text);
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Kirigami.FormLayout {
            Layout.fillWidth: true

            QQC2.Switch {
                id: overrideSwitch
                Kirigami.FormData.label: root.tr("Override theme")
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

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.65
                text: root.tr("Results may vary with third-party Plasma themes.")
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        Kirigami.FormLayout {
            Layout.fillWidth: true
            enabled: root.overrideOn

            QQC2.ComboBox {
                id: themeCombo
                Kirigami.FormData.label: root.tr("Current theme:")
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
        }

        // ---- Menu Style ----
        RowLayout {
            Layout.fillWidth: true
            QQC2.Label {
                text: root.tr("Menu style")
                font.bold: true
                Layout.fillWidth: true
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

        Kirigami.FormLayout {
            Layout.fillWidth: true
            enabled: root.overrideOn

            ColorRow {
                label: root.tr("Background color:")
                colorValue: cfg_BgColor
                propKey: "bg"
                onColorEdited: (v) => { cfg_BgColor = v; writeLive("bgColor", v); }
            }
            ColorRow {
                label: root.tr("Foreground color:")
                colorValue: cfg_FgColor
                propKey: "fg"
                onColorEdited: (v) => { cfg_FgColor = v; writeLive("fgColor", v); }
            }
            ColorRow {
                label: root.tr("Border color:")
                colorValue: cfg_BorderColor
                propKey: "border"
                onColorEdited: (v) => { cfg_BorderColor = v; writeLive("borderColor", v); }
            }

            QQC2.SpinBox {
                id: borderWidthSpin
                Kirigami.FormData.label: root.tr("Border width:")
                from: 0
                to: 8
                value: cfg_BorderWidth
                onValueModified: {
                    cfg_BorderWidth = value;
                    writeLive("borderWidth", value);
                }
            }

            QQC2.SpinBox {
                id: radiusSpin
                Kirigami.FormData.label: root.tr("Border corner radius:")
                from: -1
                to: 32
                value: cfg_CornerRadius
                textFromValue: (v) => v < 0 ? root.tr("Follow theme") : String(v)
                onValueModified: {
                    cfg_CornerRadius = value;
                    writeLive("cornerRadius", value);
                }
            }

            QQC2.SpinBox {
                id: fontSizeSpin
                Kirigami.FormData.label: root.tr("Font size:")
                from: -1
                to: 32
                value: cfg_FontSize
                textFromValue: (v) => v < 0 ? root.tr("Follow theme") : String(v)
                onValueModified: {
                    cfg_FontSize = value;
                    writeLive("fontSize", value);
                }
            }

            ColorRow {
                label: root.tr("Separator color:")
                colorValue: cfg_SeparatorColor
                propKey: "sep"
                onColorEdited: (v) => { cfg_SeparatorColor = v; writeLive("separatorColor", v); }
            }
        }

        // ---- Menu Item Style ----
        QQC2.Label {
            text: root.tr("Menu item style")
            font.bold: true
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true
            enabled: root.overrideOn

            ColorRow {
                label: root.tr("Hover background color:")
                colorValue: cfg_HoverBg
                propKey: "hoverBg"
                onColorEdited: (v) => { cfg_HoverBg = v; writeLive("hoverBg", v); }
            }
            ColorRow {
                label: root.tr("Hover foreground color:")
                colorValue: cfg_HoverFg
                propKey: "hoverFg"
                onColorEdited: (v) => { cfg_HoverFg = v; writeLive("hoverFg", v); }
            }
            ColorRow {
                label: root.tr("Active background color:")
                colorValue: cfg_ActiveBg
                propKey: "activeBg"
                onColorEdited: (v) => {
                    cfg_ActiveBg = v;
                    cfg_SelectedBg = v;
                    writeLive("activeBg", v);
                    writeLive("selectedBg", v);
                }
            }
            ColorRow {
                label: root.tr("Active foreground color:")
                colorValue: cfg_ActiveFg
                propKey: "activeFg"
                onColorEdited: (v) => {
                    cfg_ActiveFg = v;
                    cfg_SelectedFg = v;
                    writeLive("activeFg", v);
                    writeLive("selectedFg", v);
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // Icons (kept from previous settings)
        Kirigami.FormLayout {
            Layout.fillWidth: true

            QQC2.SpinBox {
                id: catIconSpin
                Kirigami.FormData.label: root.tr("Category icon size:")
                from: 16
                to: 64
                value: cfg_CategoryIconSize
                onValueModified: {
                    cfg_CategoryIconSize = value;
                    writeLive("categoryIconSize", value);
                }
            }
            QQC2.SpinBox {
                id: appIconSpin
                Kirigami.FormData.label: root.tr("Application icon size:")
                from: 16
                to: 96
                value: cfg_AppIconSize
                onValueModified: {
                    cfg_AppIconSize = value;
                    writeLive("appIconSize", value);
                }
            }
        }

        // Preview
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 8
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
                    color: {
                        if (root.overrideOn && cfg_HoverBg)
                            return cfg_HoverBg;
                        return Kirigami.Theme.highlightColor;
                    }
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
                    color: {
                        if (root.overrideOn && cfg_ActiveBg)
                            return cfg_ActiveBg;
                        return Kirigami.Theme.highlightColor;
                    }
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

        Item { Layout.fillHeight: true }
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
        // Migrate legacy selected → active
        if ((!cfg_ActiveBg || cfg_ActiveBg === "") && cfg_SelectedBg)
            cfg_ActiveBg = cfg_SelectedBg;
        if ((!cfg_ActiveFg || cfg_ActiveFg === "") && cfg_SelectedFg)
            cfg_ActiveFg = cfg_SelectedFg;
    }
}
