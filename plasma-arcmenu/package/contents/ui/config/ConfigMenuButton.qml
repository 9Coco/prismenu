import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Distro.js" as Distro
import "../../code/Locale.js" as Locale

/**
 * Menu Button — panel icon, click actions, and chrome style.
 */
Item {
    id: root

    property string cfg_ButtonIcon
    property string cfg_CustomButtonIcon
    property string cfg_MenuButtonAppearance
    property string cfg_ButtonLabelText
    property bool cfg_ButtonLabelVisible
    property int cfg_PanelButtonIconSize
    property int cfg_PanelButtonPadding
    property int cfg_PanelButtonPositionOffset
    property string cfg_LeftClickAction
    property string cfg_RightClickAction
    property string cfg_MiddleClickAction

    property bool cfg_ButtonStyleFgEnabled
    property string cfg_ButtonStyleFg
    property bool cfg_ButtonStyleBgEnabled
    property string cfg_ButtonStyleBg
    property bool cfg_ButtonStyleHoverBgEnabled
    property string cfg_ButtonStyleHoverBg
    property bool cfg_ButtonStyleHoverFgEnabled
    property string cfg_ButtonStyleHoverFg
    property bool cfg_ButtonStyleActiveBgEnabled
    property string cfg_ButtonStyleActiveBg
    property bool cfg_ButtonStyleActiveFgEnabled
    property string cfg_ButtonStyleActiveFg
    property bool cfg_ButtonStyleRadiusEnabled
    property int cfg_ButtonStyleRadius
    property bool cfg_ButtonStyleBorderWidthEnabled
    property int cfg_ButtonStyleBorderWidth
    property bool cfg_ButtonStyleBorderColorEnabled
    property string cfg_ButtonStyleBorderColor

    // ---- camelCase compatibility aliases ---------------------------------
    // Plasma hosts inject and read cfg_<key> using the lowercase-first names
    // from KConfigPropertyMap. Without these, injection silently fails and
    // a save-time read-back can wipe live-edited values back to defaults.
    property alias cfg_buttonIcon: root.cfg_ButtonIcon
    property alias cfg_customButtonIcon: root.cfg_CustomButtonIcon
    property alias cfg_menuButtonAppearance: root.cfg_MenuButtonAppearance
    property alias cfg_buttonLabelText: root.cfg_ButtonLabelText
    property alias cfg_buttonLabelVisible: root.cfg_ButtonLabelVisible
    property alias cfg_panelButtonIconSize: root.cfg_PanelButtonIconSize
    property alias cfg_panelButtonPadding: root.cfg_PanelButtonPadding
    property alias cfg_panelButtonPositionOffset: root.cfg_PanelButtonPositionOffset
    property alias cfg_leftClickAction: root.cfg_LeftClickAction
    property alias cfg_rightClickAction: root.cfg_RightClickAction
    property alias cfg_middleClickAction: root.cfg_MiddleClickAction
    property alias cfg_buttonStyleFgEnabled: root.cfg_ButtonStyleFgEnabled
    property alias cfg_buttonStyleFg: root.cfg_ButtonStyleFg
    property alias cfg_buttonStyleBgEnabled: root.cfg_ButtonStyleBgEnabled
    property alias cfg_buttonStyleBg: root.cfg_ButtonStyleBg
    property alias cfg_buttonStyleHoverBgEnabled: root.cfg_ButtonStyleHoverBgEnabled
    property alias cfg_buttonStyleHoverBg: root.cfg_ButtonStyleHoverBg
    property alias cfg_buttonStyleHoverFgEnabled: root.cfg_ButtonStyleHoverFgEnabled
    property alias cfg_buttonStyleHoverFg: root.cfg_ButtonStyleHoverFg
    property alias cfg_buttonStyleActiveBgEnabled: root.cfg_ButtonStyleActiveBgEnabled
    property alias cfg_buttonStyleActiveBg: root.cfg_ButtonStyleActiveBg
    property alias cfg_buttonStyleActiveFgEnabled: root.cfg_ButtonStyleActiveFgEnabled
    property alias cfg_buttonStyleActiveFg: root.cfg_ButtonStyleActiveFg
    property alias cfg_buttonStyleRadiusEnabled: root.cfg_ButtonStyleRadiusEnabled
    property alias cfg_buttonStyleRadius: root.cfg_ButtonStyleRadius
    property alias cfg_buttonStyleBorderWidthEnabled: root.cfg_ButtonStyleBorderWidthEnabled
    property alias cfg_buttonStyleBorderWidth: root.cfg_ButtonStyleBorderWidth
    property alias cfg_buttonStyleBorderColorEnabled: root.cfg_ButtonStyleBorderColorEnabled
    property alias cfg_buttonStyleBorderColor: root.cfg_ButtonStyleBorderColor

    property string _colorTarget: ""

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.UiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }

    function resolveIconSource(iconId, customPath) {
        var raw = Distro.resolveButtonIcon(iconId || "auto-distro", customPath || "", "", "");
        if (String(raw).indexOf("preset:") === 0)
            return Qt.resolvedUrl("../../icons/menu-button/" + String(raw).slice(7) + ".svg");
        if (Distro.isLikelyImagePath(raw)) {
            if (String(raw).indexOf("file://") === 0)
                return raw;
            if (String(raw).indexOf("/") === 0)
                return "file://" + raw;
        }
        return raw;
    }

    readonly property string previewIconSource: resolveIconSource(cfg_ButtonIcon, cfg_CustomButtonIcon)
    function writeLive(key, value) { try { plasmoid.configuration[key] = value; } catch (e) {} }

    readonly property var appearanceKeys: ["icon", "text", "icon-text", "text-icon", "hidden"]
    readonly property var appearanceLabels: [
        tr("Icon"),
        tr("Text"),
        tr("Icon and Text"),
        tr("Text and Icon"),
        tr("Hidden")
    ]

    readonly property bool appearanceShowsText: {
        var a = cfg_MenuButtonAppearance || "icon";
        return a === "text" || a === "icon-text" || a === "text-icon";
    }
    readonly property bool appearanceShowsChrome: {
        var a = cfg_MenuButtonAppearance || "icon";
        return a !== "hidden";
    }
    readonly property bool appearanceShowsIcon: {
        var a = cfg_MenuButtonAppearance || "icon";
        return a === "icon" || a === "icon-text" || a === "text-icon";
    }

    function syncLabelVisibleFromAppearance() {
        var a = cfg_MenuButtonAppearance || "icon";
        cfg_ButtonLabelVisible = (a === "text" || a === "icon-text" || a === "text-icon");
        writeLive("ButtonLabelVisible", cfg_ButtonLabelVisible);
    }

    function applyAppearance(key) {
        cfg_MenuButtonAppearance = key;
        writeLive("MenuButtonAppearance", key);
        syncLabelVisibleFromAppearance();
    }

    function restoreAppearanceDefaults() {
        applyAppearance("icon");
        cfg_ButtonLabelText = "Applications";
        writeLive("ButtonLabelText", "Applications");
        cfg_PanelButtonPadding = -1;
        writeLive("PanelButtonPadding", -1);
        paddingSpin.value = -1;
        cfg_PanelButtonPositionOffset = 0;
        writeLive("PanelButtonPositionOffset", 0);
        offsetSpin.value = 0;
        appearanceCombo.currentIndex = 0;
    }

    readonly property var clickKeys: ["arcmenu", "context", "overview", "configure", "show-desktop", "nothing"]
    readonly property var clickLabels: [
        "ArcMenu",
        tr("Context Menu"),
        tr("Activities Overview"),
        tr("ArcMenu Settings"),
        tr("Show Desktop"),
        tr("Nothing")
    ]

    function clickIndex(key) {
        var i = clickKeys.indexOf(key || "arcmenu");
        return i >= 0 ? i : 0;
    }

    component StyleColorRow: ConfigSettingRow {
        id: srow
        property bool enabledFlag: false
        property string colorValue: ""
        property string enabledKey: ""
        property string colorKey: ""
        signal styleEnabledToggled(bool on)

        QQC2.Switch {
            checked: srow.enabledFlag
            onToggled: {
                srow.styleEnabledToggled(checked);
                root.writeLive(srow.enabledKey, checked);
            }
        }
        Rectangle {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.8
            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
            radius: 3
            border.width: 1
            border.color: Kirigami.Theme.disabledTextColor
            opacity: srow.enabledFlag ? 1 : 0.45
            color: {
                if (!srow.colorValue || srow.colorValue === "" || srow.colorValue === "transparent")
                    return "transparent";
                try { return srow.colorValue; } catch (e) { return "transparent"; }
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                visible: !srow.colorValue || srow.colorValue === "" || srow.colorValue === "transparent"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#bbb" }
                    GradientStop { position: 1; color: "#666" }
                }
                opacity: 0.45
            }
            MouseArea {
                anchors.fill: parent
                enabled: srow.enabledFlag
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root._colorTarget = srow.colorKey;
                    colorDialog.selectedColor = srow.colorValue || "#808080";
                    colorDialog.open();
                }
            }
        }
    }

    component StyleSpinRow: ConfigSettingRow {
        id: nrow
        property string hint: ""
        property bool enabledFlag: false
        property int spinValue: 0
        property int from: 0
        property int to: 48
        property string enabledKey: ""
        property string valueKey: ""
        signal styleEnabledToggled(bool on)
        signal spinEdited(int v)

        subtitle: hint
        QQC2.Switch {
            checked: nrow.enabledFlag
            onToggled: {
                nrow.styleEnabledToggled(checked);
                root.writeLive(nrow.enabledKey, checked);
            }
        }
        QQC2.SpinBox {
            from: nrow.from
            to: nrow.to
            enabled: nrow.enabledFlag
            value: nrow.spinValue
            onValueModified: {
                nrow.spinEdited(value);
                root.writeLive(nrow.valueKey, value);
            }
        }
    }

    ConfigPage {
        title: root.tr("Menu Button")
        tip: root.tr("Customize the panel button appearance, click actions, and colors. Changes are applied immediately.")

        ConfigGroup {
            title: root.tr("Appearance")
            ConfigSettingRow {
                title: root.tr("Display Style")
                iconName: "view-list-details"
                accent: "blue"
                QQC2.ComboBox {
                    id: appearanceCombo
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    model: root.appearanceLabels
                    Component.onCompleted: {
                        var i = root.appearanceKeys.indexOf(cfg_MenuButtonAppearance || "icon");
                        currentIndex = i >= 0 ? i : 0;
                    }
                    onActivated: root.applyAppearance(root.appearanceKeys[currentIndex])
                }
                QQC2.ToolButton {
                    icon.name: "view-refresh-symbolic"
                    QQC2.ToolTip.text: root.tr("Reset settings")
                    QQC2.ToolTip.visible: hovered
                    onClicked: restoreConfirm.open()
                }
            }
            ConfigSep { visible: root.appearanceShowsText }
            ConfigSettingRow {
                visible: root.appearanceShowsText
                title: root.tr("Text")
                iconName: "draw-text"
                accent: "purple"
                QQC2.TextField {
                    id: buttonTextField
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    text: cfg_ButtonLabelText
                    onTextEdited: {
                        cfg_ButtonLabelText = text;
                        writeLive("ButtonLabelText", text);
                    }
                }
            }
            ConfigSep { visible: root.appearanceShowsChrome }
            ConfigSettingRow {
                visible: root.appearanceShowsChrome
                title: root.tr("Padding")
                subtitle: root.tr("%1 Default Theme Value").replace("%1", "-1")
                iconName: "transform-move-horizontal"
                accent: "teal"
                QQC2.SpinBox {
                    id: paddingSpin
                    from: -1; to: 25
                    value: cfg_PanelButtonPadding
                    onValueModified: {
                        cfg_PanelButtonPadding = value;
                        writeLive("PanelButtonPadding", value);
                    }
                }
            }
            ConfigSep { visible: root.appearanceShowsChrome }
            ConfigSettingRow {
                visible: root.appearanceShowsChrome
                title: root.tr("Position in Panel")
                iconName: "align-horizontal-left"
                accent: "orange"
                QQC2.SpinBox {
                    id: offsetSpin
                    from: 0; to: 10
                    value: cfg_PanelButtonPositionOffset
                    onValueModified: {
                        cfg_PanelButtonPositionOffset = value;
                        writeLive("PanelButtonPositionOffset", value);
                    }
                }
            }
        }

        ConfigGroup {
            visible: root.appearanceShowsIcon
            title: root.tr("Icon")
            ConfigSettingRow {
                title: root.tr("Select a new icon")
                iconName: "preferences-desktop-icons"
                accent: "indigo"
                Kirigami.Icon {
                    source: root.previewIconSource
                    isMask: Distro.buttonIconIsMask(cfg_ButtonIcon || "auto-distro", cfg_CustomButtonIcon || "")
                    color: Kirigami.Theme.textColor
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }
                QQC2.Button {
                    text: root.tr("Browse...")
                    onClicked: iconChooser.openFor(cfg_ButtonIcon || "auto-distro")
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Icon size")
                iconName: "zoom-fit-best"
                accent: "cyan"
                QQC2.SpinBox {
                    from: 14; to: 64
                    value: cfg_PanelButtonIconSize > 0 ? cfg_PanelButtonIconSize : 20
                    onValueModified: {
                        cfg_PanelButtonIconSize = value;
                        writeLive("PanelButtonIconSize", value);
                    }
                }
            }
        }

        ConfigGroup {
            title: root.tr("Click Options")
            ConfigSettingRow {
                title: root.tr("Left click")
                iconName: "input-mouse"
                accent: "blue"
                QQC2.ComboBox {
                    model: root.clickLabels
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    Component.onCompleted: currentIndex = root.clickIndex(cfg_LeftClickAction)
                    onActivated: {
                        cfg_LeftClickAction = root.clickKeys[currentIndex];
                        writeLive("LeftClickAction", cfg_LeftClickAction);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Right click")
                iconName: "input-mouse-click-right"
                accent: "purple"
                QQC2.ComboBox {
                    model: root.clickLabels
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    Component.onCompleted: currentIndex = root.clickIndex(cfg_RightClickAction)
                    onActivated: {
                        cfg_RightClickAction = root.clickKeys[currentIndex];
                        writeLive("RightClickAction", cfg_RightClickAction);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Middle click")
                iconName: "input-mouse-click-middle"
                accent: "teal"
                QQC2.ComboBox {
                    model: root.clickLabels
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    Component.onCompleted: currentIndex = root.clickIndex(cfg_MiddleClickAction)
                    onActivated: {
                        cfg_MiddleClickAction = root.clickKeys[currentIndex];
                        writeLive("MiddleClickAction", cfg_MiddleClickAction);
                    }
                }
            }
        }

        ConfigGroup {
            title: root.tr("Style")
            ConfigSettingRow {
                title: root.tr("Theme note")
                subtitle: root.tr("Results may vary depending on third-party themes.")
                iconName: "dialog-information"
                accent: "yellow"
            }
            ConfigSep {}
            StyleColorRow {
                title: root.tr("Foreground color")
                iconName: "format-text-color"
                accent: "blue"
                enabledFlag: cfg_ButtonStyleFgEnabled
                colorValue: cfg_ButtonStyleFg
                enabledKey: "ButtonStyleFgEnabled"
                colorKey: "ButtonStyleFg"
                onStyleEnabledToggled: (on) => cfg_ButtonStyleFgEnabled = on
            }
            ConfigSep {}
            StyleColorRow {
                title: root.tr("Background color")
                iconName: "fill-color"
                accent: "purple"
                enabledFlag: cfg_ButtonStyleBgEnabled
                colorValue: cfg_ButtonStyleBg
                enabledKey: "ButtonStyleBgEnabled"
                colorKey: "ButtonStyleBg"
                onStyleEnabledToggled: (on) => cfg_ButtonStyleBgEnabled = on
            }
            ConfigSep {}
            StyleColorRow {
                title: root.tr("Hover Background color")
                iconName: "fill-color"
                accent: "teal"
                enabledFlag: cfg_ButtonStyleHoverBgEnabled
                colorValue: cfg_ButtonStyleHoverBg
                enabledKey: "ButtonStyleHoverBgEnabled"
                colorKey: "ButtonStyleHoverBg"
                onStyleEnabledToggled: (on) => cfg_ButtonStyleHoverBgEnabled = on
            }
            ConfigSep {}
            StyleColorRow {
                title: root.tr("Hover Foreground color")
                iconName: "format-text-color"
                accent: "cyan"
                enabledFlag: cfg_ButtonStyleHoverFgEnabled
                colorValue: cfg_ButtonStyleHoverFg
                enabledKey: "ButtonStyleHoverFgEnabled"
                colorKey: "ButtonStyleHoverFg"
                onStyleEnabledToggled: (on) => cfg_ButtonStyleHoverFgEnabled = on
            }
            ConfigSep {}
            StyleColorRow {
                title: root.tr("Active Background color")
                iconName: "fill-color"
                accent: "orange"
                enabledFlag: cfg_ButtonStyleActiveBgEnabled
                colorValue: cfg_ButtonStyleActiveBg
                enabledKey: "ButtonStyleActiveBgEnabled"
                colorKey: "ButtonStyleActiveBg"
                onStyleEnabledToggled: (on) => cfg_ButtonStyleActiveBgEnabled = on
            }
            ConfigSep {}
            StyleColorRow {
                title: root.tr("Active Foreground color")
                iconName: "format-text-color"
                accent: "pink"
                enabledFlag: cfg_ButtonStyleActiveFgEnabled
                colorValue: cfg_ButtonStyleActiveFg
                enabledKey: "ButtonStyleActiveFgEnabled"
                colorKey: "ButtonStyleActiveFg"
                onStyleEnabledToggled: (on) => cfg_ButtonStyleActiveFgEnabled = on
            }
            ConfigSep {}
            StyleSpinRow {
                title: root.tr("Border radius")
                iconName: "draw-square-rounded"
                accent: "indigo"
                enabledFlag: cfg_ButtonStyleRadiusEnabled
                spinValue: cfg_ButtonStyleRadius
                enabledKey: "ButtonStyleRadiusEnabled"
                valueKey: "ButtonStyleRadius"
                onStyleEnabledToggled: (on) => cfg_ButtonStyleRadiusEnabled = on
                onSpinEdited: (v) => cfg_ButtonStyleRadius = v
            }
            ConfigSep {}
            StyleSpinRow {
                title: root.tr("Border width")
                hint: root.tr("If set to 0, a background color is required.")
                iconName: "object-stroke-style"
                accent: "green"
                enabledFlag: cfg_ButtonStyleBorderWidthEnabled
                spinValue: cfg_ButtonStyleBorderWidth
                to: 12
                enabledKey: "ButtonStyleBorderWidthEnabled"
                valueKey: "ButtonStyleBorderWidth"
                onStyleEnabledToggled: (on) => cfg_ButtonStyleBorderWidthEnabled = on
                onSpinEdited: (v) => cfg_ButtonStyleBorderWidth = v
            }
            ConfigSep {}
            StyleColorRow {
                title: root.tr("Border color")
                iconName: "color-picker"
                accent: "red"
                enabledFlag: cfg_ButtonStyleBorderColorEnabled
                colorValue: cfg_ButtonStyleBorderColor
                enabledKey: "ButtonStyleBorderColorEnabled"
                colorKey: "ButtonStyleBorderColor"
                onStyleEnabledToggled: (on) => cfg_ButtonStyleBorderColorEnabled = on
            }
        }
    }

    IconChooserDialog {
        id: iconChooser
        uiLang: root.uiLang
        onIconChosen: (iconId, kind, filePath) => {
            if (kind === "file") {
                cfg_CustomButtonIcon = filePath;
                cfg_ButtonIcon = "custom";
                writeLive("CustomButtonIcon", filePath);
                writeLive("ButtonIcon", "custom");
                return;
            }
            cfg_ButtonIcon = iconId;
            writeLive("ButtonIcon", iconId);
        }
    }

    Dialogs.ColorDialog {
        id: colorDialog
        title: root.tr("Choose color")
        onAccepted: {
            var c = selectedColor.toString();
            var key = root._colorTarget;
            if (!key)
                return;
            if (key === "ButtonStyleFg") { cfg_ButtonStyleFg = c; writeLive(key, c); }
            else if (key === "ButtonStyleBg") { cfg_ButtonStyleBg = c; writeLive(key, c); }
            else if (key === "ButtonStyleHoverBg") { cfg_ButtonStyleHoverBg = c; writeLive(key, c); }
            else if (key === "ButtonStyleHoverFg") { cfg_ButtonStyleHoverFg = c; writeLive(key, c); }
            else if (key === "ButtonStyleActiveBg") { cfg_ButtonStyleActiveBg = c; writeLive(key, c); }
            else if (key === "ButtonStyleActiveFg") { cfg_ButtonStyleActiveFg = c; writeLive(key, c); }
            else if (key === "ButtonStyleBorderColor") { cfg_ButtonStyleBorderColor = c; writeLive(key, c); }
        }
    }

    QQC2.Dialog {
        id: restoreConfirm
        title: root.tr("Reset settings")
        modal: true
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No
        QQC2.Label {
            text: root.tr("Reset Appearance settings to defaults?")
            wrapMode: Text.WordWrap
            width: restoreConfirm.availableWidth
        }
        onAccepted: root.restoreAppearanceDefaults()
    }

    Component.onCompleted: {
        if (!cfg_MenuButtonAppearance) {
            if (cfg_ButtonLabelVisible)
                applyAppearance("icon-text");
            else
                applyAppearance("icon");
        }
        if (!cfg_PanelButtonIconSize) cfg_PanelButtonIconSize = 20;
        if (cfg_PanelButtonPadding === undefined || cfg_PanelButtonPadding === null)
            cfg_PanelButtonPadding = -1;
        if (cfg_PanelButtonPositionOffset === undefined || cfg_PanelButtonPositionOffset === null)
            cfg_PanelButtonPositionOffset = 0;
        paddingSpin.value = cfg_PanelButtonPadding;
        offsetSpin.value = cfg_PanelButtonPositionOffset;
        if (!cfg_ButtonLabelText) cfg_ButtonLabelText = "Applications";
        buttonTextField.text = cfg_ButtonLabelText;
        if (!cfg_LeftClickAction) cfg_LeftClickAction = "arcmenu";
        if (!cfg_RightClickAction) cfg_RightClickAction = "context";
        if (!cfg_MiddleClickAction) cfg_MiddleClickAction = "arcmenu";
        if (cfg_ButtonStyleRadius === undefined || cfg_ButtonStyleRadius === null) cfg_ButtonStyleRadius = 20;
        if (cfg_ButtonStyleBorderWidth === undefined || cfg_ButtonStyleBorderWidth === null) cfg_ButtonStyleBorderWidth = 3;
    }
}
