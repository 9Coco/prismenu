import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Distro.js" as Distro
import "../../code/Locale.js" as Locale

/**
 * Menu Button — panel icon, click actions, and chrome style (ArcMenu 菜单按钮).
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

    property string _colorTarget: ""

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
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

    function syncLabelVisibleFromAppearance() {
        var a = cfg_MenuButtonAppearance || "icon";
        cfg_ButtonLabelVisible = (a === "text" || a === "icon-text" || a === "text-icon");
        writeLive("buttonLabelVisible", cfg_ButtonLabelVisible);
    }

    function applyAppearance(key) {
        cfg_MenuButtonAppearance = key;
        writeLive("menuButtonAppearance", key);
        syncLabelVisibleFromAppearance();
    }

    function restoreAppearanceDefaults() {
        applyAppearance("icon");
        cfg_ButtonLabelText = "Applications";
        writeLive("buttonLabelText", "Applications");
        cfg_PanelButtonPadding = -1;
        writeLive("panelButtonPadding", -1);
        paddingSpin.value = -1;
        cfg_PanelButtonPositionOffset = 0;
        writeLive("panelButtonPositionOffset", 0);
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

    component StyleColorRow: RowLayout {
        id: srow
        property string label: ""
        property bool enabledFlag: false
        property string colorValue: ""
        property string enabledKey: ""
        property string colorKey: ""
        signal styleEnabledToggled(bool on)
        signal colorEdited(string value)

        Layout.fillWidth: true
        QQC2.Label { text: srow.label; Layout.fillWidth: true }
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

    component StyleSpinRow: RowLayout {
        id: nrow
        property string label: ""
        property string hint: ""
        property bool enabledFlag: false
        property int spinValue: 0
        property int from: 0
        property int to: 48
        property string enabledKey: ""
        property string valueKey: ""
        signal styleEnabledToggled(bool on)
        signal spinEdited(int v)

        Layout.fillWidth: true
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            QQC2.Label { text: nrow.label; Layout.fillWidth: true }
            QQC2.Label {
                visible: nrow.hint.length > 0
                text: nrow.hint
                opacity: 0.6
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
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

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.height
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            // ---- Appearance ----
            RowLayout {
                Layout.fillWidth: true
                QQC2.Label { text: root.tr("Appearance"); font.bold: true; Layout.fillWidth: true }
                QQC2.ToolButton {
                    icon.name: "view-refresh-symbolic"
                    QQC2.ToolTip.text: root.tr("Reset settings")
                    QQC2.ToolTip.visible: hovered
                    onClicked: restoreConfirm.open()
                }
            }

            GroupCard {
                SettingRow {
                    title: root.tr("Display Style")
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
                }
                Kirigami.Separator {
                    Layout.fillWidth: true; opacity: 0.2
                    visible: root.appearanceShowsText
                }
                SettingRow {
                    visible: root.appearanceShowsText
                    title: root.tr("Text")
                    QQC2.TextField {
                        id: buttonTextField
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                        text: cfg_ButtonLabelText
                        onTextEdited: {
                            cfg_ButtonLabelText = text;
                            writeLive("buttonLabelText", text);
                        }
                    }
                }
                Kirigami.Separator {
                    Layout.fillWidth: true; opacity: 0.2
                    visible: root.appearanceShowsChrome
                }
                SettingRow {
                    visible: root.appearanceShowsChrome
                    title: root.tr("Padding")
                    subtitle: root.tr("%1 Default Theme Value").replace("%1", "-1")
                    QQC2.SpinBox {
                        id: paddingSpin
                        from: -1; to: 25
                        value: cfg_PanelButtonPadding
                        onValueModified: {
                            cfg_PanelButtonPadding = value;
                            writeLive("panelButtonPadding", value);
                        }
                    }
                }
                Kirigami.Separator {
                    Layout.fillWidth: true; opacity: 0.2
                    visible: root.appearanceShowsChrome
                }
                SettingRow {
                    visible: root.appearanceShowsChrome
                    title: root.tr("Position in Panel")
                    QQC2.SpinBox {
                        id: offsetSpin
                        from: 0; to: 10
                        value: cfg_PanelButtonPositionOffset
                        onValueModified: {
                            cfg_PanelButtonPositionOffset = value;
                            writeLive("panelButtonPositionOffset", value);
                        }
                    }
                }
            }

            // ---- Icon ----
            QQC2.Label {
                text: root.tr("Icon")
                font.bold: true
                visible: {
                    var a = cfg_MenuButtonAppearance || "icon";
                    return a === "icon" || a === "icon-text" || a === "text-icon";
                }
            }

            GroupCard {
                visible: {
                    var a = cfg_MenuButtonAppearance || "icon";
                    return a === "icon" || a === "icon-text" || a === "text-icon";
                }
                SettingRow {
                    title: root.tr("Select a new icon")
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
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2 }
                SettingRow {
                    title: root.tr("Icon size")
                    QQC2.SpinBox {
                        from: 14; to: 64
                        value: cfg_PanelButtonIconSize > 0 ? cfg_PanelButtonIconSize : 20
                        onValueModified: {
                            cfg_PanelButtonIconSize = value;
                            writeLive("panelButtonIconSize", value);
                        }
                    }
                }
            }

            // ---- Click options ----
            QQC2.Label { text: root.tr("Click Options"); font.bold: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: clickCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                ColumnLayout {
                    id: clickCol
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label { text: root.tr("Left click"); Layout.fillWidth: true }
                        QQC2.ComboBox {
                            model: root.clickLabels
                            Component.onCompleted: currentIndex = root.clickIndex(cfg_LeftClickAction)
                            onActivated: {
                                cfg_LeftClickAction = root.clickKeys[currentIndex];
                                writeLive("leftClickAction", cfg_LeftClickAction);
                            }
                        }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label { text: root.tr("Right click"); Layout.fillWidth: true }
                        QQC2.ComboBox {
                            model: root.clickLabels
                            Component.onCompleted: currentIndex = root.clickIndex(cfg_RightClickAction)
                            onActivated: {
                                cfg_RightClickAction = root.clickKeys[currentIndex];
                                writeLive("rightClickAction", cfg_RightClickAction);
                            }
                        }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label { text: root.tr("Middle click"); Layout.fillWidth: true }
                        QQC2.ComboBox {
                            model: root.clickLabels
                            Component.onCompleted: currentIndex = root.clickIndex(cfg_MiddleClickAction)
                            onActivated: {
                                cfg_MiddleClickAction = root.clickKeys[currentIndex];
                                writeLive("middleClickAction", cfg_MiddleClickAction);
                            }
                        }
                    }
                }
            }

            // ---- Style ----
            QQC2.Label { text: root.tr("Style"); font.bold: true }
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.65
                text: root.tr("Results may vary depending on third-party themes.")
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: styleCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)

                ColumnLayout {
                    id: styleCol
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    StyleColorRow {
                        label: root.tr("Foreground color")
                        enabledFlag: cfg_ButtonStyleFgEnabled
                        colorValue: cfg_ButtonStyleFg
                        enabledKey: "buttonStyleFgEnabled"
                        colorKey: "buttonStyleFg"
                        onStyleEnabledToggled: (on) => cfg_ButtonStyleFgEnabled = on
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    StyleColorRow {
                        label: root.tr("Background color")
                        enabledFlag: cfg_ButtonStyleBgEnabled
                        colorValue: cfg_ButtonStyleBg
                        enabledKey: "buttonStyleBgEnabled"
                        colorKey: "buttonStyleBg"
                        onStyleEnabledToggled: (on) => cfg_ButtonStyleBgEnabled = on
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    StyleColorRow {
                        label: root.tr("Hover Background color")
                        enabledFlag: cfg_ButtonStyleHoverBgEnabled
                        colorValue: cfg_ButtonStyleHoverBg
                        enabledKey: "buttonStyleHoverBgEnabled"
                        colorKey: "buttonStyleHoverBg"
                        onStyleEnabledToggled: (on) => cfg_ButtonStyleHoverBgEnabled = on
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    StyleColorRow {
                        label: root.tr("Hover Foreground color")
                        enabledFlag: cfg_ButtonStyleHoverFgEnabled
                        colorValue: cfg_ButtonStyleHoverFg
                        enabledKey: "buttonStyleHoverFgEnabled"
                        colorKey: "buttonStyleHoverFg"
                        onStyleEnabledToggled: (on) => cfg_ButtonStyleHoverFgEnabled = on
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    StyleColorRow {
                        label: root.tr("Active Background color")
                        enabledFlag: cfg_ButtonStyleActiveBgEnabled
                        colorValue: cfg_ButtonStyleActiveBg
                        enabledKey: "buttonStyleActiveBgEnabled"
                        colorKey: "buttonStyleActiveBg"
                        onStyleEnabledToggled: (on) => cfg_ButtonStyleActiveBgEnabled = on
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    StyleColorRow {
                        label: root.tr("Active Foreground color")
                        enabledFlag: cfg_ButtonStyleActiveFgEnabled
                        colorValue: cfg_ButtonStyleActiveFg
                        enabledKey: "buttonStyleActiveFgEnabled"
                        colorKey: "buttonStyleActiveFg"
                        onStyleEnabledToggled: (on) => cfg_ButtonStyleActiveFgEnabled = on
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    StyleSpinRow {
                        label: root.tr("Border radius")
                        enabledFlag: cfg_ButtonStyleRadiusEnabled
                        spinValue: cfg_ButtonStyleRadius
                        enabledKey: "buttonStyleRadiusEnabled"
                        valueKey: "buttonStyleRadius"
                        onStyleEnabledToggled: (on) => cfg_ButtonStyleRadiusEnabled = on
                        onSpinEdited: (v) => cfg_ButtonStyleRadius = v
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    StyleSpinRow {
                        label: root.tr("Border width")
                        hint: root.tr("If set to 0, a background color is required.")
                        enabledFlag: cfg_ButtonStyleBorderWidthEnabled
                        spinValue: cfg_ButtonStyleBorderWidth
                        to: 12
                        enabledKey: "buttonStyleBorderWidthEnabled"
                        valueKey: "buttonStyleBorderWidth"
                        onStyleEnabledToggled: (on) => cfg_ButtonStyleBorderWidthEnabled = on
                        onSpinEdited: (v) => cfg_ButtonStyleBorderWidth = v
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.25 }
                    StyleColorRow {
                        label: root.tr("Border color")
                        enabledFlag: cfg_ButtonStyleBorderColorEnabled
                        colorValue: cfg_ButtonStyleBorderColor
                        enabledKey: "buttonStyleBorderColorEnabled"
                        colorKey: "buttonStyleBorderColor"
                        onStyleEnabledToggled: (on) => cfg_ButtonStyleBorderColorEnabled = on
                    }
                }
            }

            Item { Layout.preferredHeight: Kirigami.Units.largeSpacing }
        }
    }

    IconChooserDialog {
        id: iconChooser
        uiLang: root.uiLang
        onIconChosen: (iconId, kind, filePath) => {
            if (kind === "file") {
                cfg_CustomButtonIcon = filePath;
                cfg_ButtonIcon = "custom";
                writeLive("customButtonIcon", filePath);
                writeLive("buttonIcon", "custom");
                return;
            }
            cfg_ButtonIcon = iconId;
            writeLive("buttonIcon", iconId);
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
            if (key === "buttonStyleFg") { cfg_ButtonStyleFg = c; writeLive(key, c); }
            else if (key === "buttonStyleBg") { cfg_ButtonStyleBg = c; writeLive(key, c); }
            else if (key === "buttonStyleHoverBg") { cfg_ButtonStyleHoverBg = c; writeLive(key, c); }
            else if (key === "buttonStyleHoverFg") { cfg_ButtonStyleHoverFg = c; writeLive(key, c); }
            else if (key === "buttonStyleActiveBg") { cfg_ButtonStyleActiveBg = c; writeLive(key, c); }
            else if (key === "buttonStyleActiveFg") { cfg_ButtonStyleActiveFg = c; writeLive(key, c); }
            else if (key === "buttonStyleBorderColor") { cfg_ButtonStyleBorderColor = c; writeLive(key, c); }
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
