import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale
import "../../code/IconSizes.js" as IconSizes

/**
 * Menu Visual Appearance — ConfigPage chrome.
 */
Item {
    id: root

    property int cfg_MenuHeight
    property int cfg_LeftPanelWidth
    property int cfg_RightPanelWidth
    property int cfg_WidthOffset
    property int cfg_SidebarWidth
    property int cfg_MenuWidth
    property string cfg_OverrideMenuPosition
    property bool cfg_OverrideMenuRise
    property int cfg_MenuRiseDistance
    property int cfg_IconSizeGrid
    property int cfg_IconSizeApps
    property int cfg_IconSizeShortcuts
    property int cfg_IconSizeCategories
    property int cfg_IconSizeButtons
    property int cfg_IconSizeOther

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.UiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }
    function writeLive(key, value) { try { plasmoid.configuration[key] = value; } catch (e) {} }

    function syncWidthFromPanels() {
        var w = cfg_LeftPanelWidth + cfg_RightPanelWidth + 24 + cfg_WidthOffset;
        if (w < 400) w = 400;
        if (w > 900) w = 900;
        cfg_MenuWidth = w;
        cfg_SidebarWidth = cfg_RightPanelWidth;
        writeLive("MenuWidth", w);
        writeLive("SidebarWidth", cfg_RightPanelWidth);
        writeLive("LeftPanelWidth", cfg_LeftPanelWidth);
        writeLive("RightPanelWidth", cfg_RightPanelWidth);
        writeLive("WidthOffset", cfg_WidthOffset);
    }

    readonly property var iconLevelModel: [
        root.tr("Off"),
        root.tr("Extra Small"),
        root.tr("Small"),
        root.tr("Medium"),
        root.tr("Large"),
        root.tr("Extra Large")
    ]

    function levelToIndex(level) {
        var n = IconSizes.clampLevel(level);
        return n < 0 ? 0 : n + 1;
    }
    function indexToLevel(index) {
        return index <= 0 ? -1 : index - 1;
    }

    function resetDefaults() {
        cfg_MenuHeight = 540;
        cfg_LeftPanelWidth = 380;
        cfg_RightPanelWidth = 220;
        cfg_WidthOffset = 0;
        cfg_OverrideMenuPosition = "off";
        cfg_OverrideMenuRise = false;
        cfg_MenuRiseDistance = 6;
        cfg_IconSizeGrid = -1;
        cfg_IconSizeApps = -1;
        cfg_IconSizeShortcuts = -1;
        cfg_IconSizeCategories = -1;
        cfg_IconSizeButtons = -1;
        cfg_IconSizeOther = -1;
        heightSpin.value = 540;
        leftSpin.value = 380;
        rightSpin.value = 220;
        offsetSpin.value = 0;
        riseSwitch.checked = false;
        riseSpin.value = 6;
        posCombo.currentIndex = 0;
        syncWidthFromPanels();
        writeLive("MenuHeight", 540);
        writeLive("OverrideMenuPosition", "off");
        writeLive("OverrideMenuRise", false);
        writeLive("MenuRiseDistance", 6);
        writeLive("IconSizeGrid", -1);
        writeLive("IconSizeApps", -1);
        writeLive("IconSizeShortcuts", -1);
        writeLive("IconSizeCategories", -1);
        writeLive("IconSizeButtons", -1);
        writeLive("IconSizeOther", -1);
    }

    ConfigPage {
        title: root.tr("Menu Visual Appearance")
        tip: root.tr("Change menu height, width, location, and icon sizes")

        ConfigGroup {
            title: root.tr("Menu size")
            ConfigSettingRow {
                title: root.tr("Height")
                iconName: "resizecol"
                accent: "blue"
                QQC2.SpinBox {
                    id: heightSpin
                    from: 400; to: 800; stepSize: 10
                    value: cfg_MenuHeight
                    onValueModified: {
                        cfg_MenuHeight = value;
                        writeLive("MenuHeight", value);
                    }
                    textFromValue: (v) => v + " px"
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Left panel width")
                subtitle: root.tr("Traditional layouts")
                iconName: "view-split-left-right"
                accent: "purple"
                QQC2.SpinBox {
                    id: leftSpin
                    from: 180; to: 600; stepSize: 5
                    value: cfg_LeftPanelWidth
                    onValueModified: {
                        cfg_LeftPanelWidth = value;
                        root.syncWidthFromPanels();
                    }
                    textFromValue: (v) => v + " px"
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Right panel width")
                subtitle: root.tr("Traditional layouts")
                iconName: "view-split-left-right"
                accent: "teal"
                QQC2.SpinBox {
                    id: rightSpin
                    from: 160; to: 360; stepSize: 5
                    value: cfg_RightPanelWidth
                    onValueModified: {
                        cfg_RightPanelWidth = value;
                        root.syncWidthFromPanels();
                    }
                    textFromValue: (v) => v + " px"
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Width offset")
                subtitle: root.tr("Non-traditional layouts")
                iconName: "transform-move-horizontal"
                accent: "orange"
                QQC2.SpinBox {
                    id: offsetSpin
                    from: -200; to: 400; stepSize: 10
                    value: cfg_WidthOffset
                    onValueModified: {
                        cfg_WidthOffset = value;
                        root.syncWidthFromPanels();
                    }
                    textFromValue: (v) => v + " px"
                }
            }
        }

        ConfigGroup {
            title: root.tr("Menu position")
            ConfigSettingRow {
                title: root.tr("Override menu position")
                iconName: "preferences-desktop-display"
                accent: "indigo"
                QQC2.ComboBox {
                    id: posCombo
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    model: [
                        root.tr("Off"),
                        root.tr("Top centered"),
                        root.tr("Bottom centered"),
                        root.tr("Center")
                    ]
                    property var keys: ["off", "top-centered", "bottom-centered", "center"]
                    Component.onCompleted: {
                        var i = keys.indexOf(cfg_OverrideMenuPosition || "off");
                        currentIndex = i >= 0 ? i : 0;
                    }
                    onActivated: {
                        cfg_OverrideMenuPosition = keys[currentIndex];
                        writeLive("OverrideMenuPosition", cfg_OverrideMenuPosition);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Override menu rise")
                subtitle: root.tr("Distance between the menu and the panel or screen edge.")
                iconName: "go-up"
                accent: "green"
                QQC2.Switch {
                    id: riseSwitch
                    checked: cfg_OverrideMenuRise
                    onToggled: {
                        cfg_OverrideMenuRise = checked;
                        writeLive("OverrideMenuRise", checked);
                    }
                }
                QQC2.SpinBox {
                    id: riseSpin
                    from: 0; to: 64
                    enabled: cfg_OverrideMenuRise
                    value: cfg_MenuRiseDistance
                    onValueModified: {
                        cfg_MenuRiseDistance = value;
                        writeLive("MenuRiseDistance", value);
                    }
                    textFromValue: (v) => v + " px"
                }
            }
        }

        ConfigGroup {
            title: root.tr("Override icon size")
            ConfigSettingRow {
                title: root.tr("Grid menu items")
                subtitle: root.tr("Applications, pinned apps, shortcuts and grid search results (non-traditional layouts).")
                iconName: "view-app-grid-symbolic"
                accent: "blue"
                QQC2.ComboBox {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    model: root.iconLevelModel
                    currentIndex: root.levelToIndex(cfg_IconSizeGrid)
                    onActivated: {
                        cfg_IconSizeGrid = root.indexToLevel(currentIndex);
                        writeLive("IconSizeGrid", cfg_IconSizeGrid);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Applications")
                subtitle: root.tr("Applications, pinned apps, items in categories, and list search results.")
                iconName: "applications-all"
                accent: "purple"
                QQC2.ComboBox {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    model: root.iconLevelModel
                    currentIndex: root.levelToIndex(cfg_IconSizeApps)
                    onActivated: {
                        cfg_IconSizeApps = root.indexToLevel(currentIndex);
                        writeLive("IconSizeApps", cfg_IconSizeApps);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Shortcuts")
                subtitle: root.tr("Directories, application shortcuts, and the power menu.")
                iconName: "favorite"
                accent: "teal"
                QQC2.ComboBox {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    model: root.iconLevelModel
                    currentIndex: root.levelToIndex(cfg_IconSizeShortcuts)
                    onActivated: {
                        cfg_IconSizeShortcuts = root.indexToLevel(currentIndex);
                        writeLive("IconSizeShortcuts", cfg_IconSizeShortcuts);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Application categories")
                subtitle: root.tr("Category list.")
                iconName: "view-categories"
                accent: "orange"
                QQC2.ComboBox {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    model: root.iconLevelModel
                    currentIndex: root.levelToIndex(cfg_IconSizeCategories)
                    onActivated: {
                        cfg_IconSizeCategories = root.indexToLevel(currentIndex);
                        writeLive("IconSizeCategories", cfg_IconSizeCategories);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Button widgets")
                subtitle: root.tr("Power buttons, Unity-style bottom bar, and Mint-style sidebar buttons.")
                iconName: "system-shutdown"
                accent: "red"
                QQC2.ComboBox {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    model: root.iconLevelModel
                    currentIndex: root.levelToIndex(cfg_IconSizeButtons)
                    onActivated: {
                        cfg_IconSizeButtons = root.indexToLevel(currentIndex);
                        writeLive("IconSizeButtons", cfg_IconSizeButtons);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Other")
                subtitle: root.tr("User avatar, search icon, and navigation icons.")
                iconName: "preferences-desktop-icons"
                accent: "cyan"
                QQC2.ComboBox {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    model: root.iconLevelModel
                    currentIndex: root.levelToIndex(cfg_IconSizeOther)
                    onActivated: {
                        cfg_IconSizeOther = root.indexToLevel(currentIndex);
                        writeLive("IconSizeOther", cfg_IconSizeOther);
                    }
                }
            }
        }

        QQC2.Button {
            text: root.tr("Reset to defaults")
            onClicked: root.resetDefaults()
        }
    }

    Connections {
        target: plasmoid.configuration
        function onMenuHeightChanged() {
            var v = plasmoid.configuration.MenuHeight;
            if (heightSpin.value !== v) heightSpin.value = v;
            cfg_MenuHeight = v;
        }
        function onLeftPanelWidthChanged() {
            var v = plasmoid.configuration.LeftPanelWidth;
            if (leftSpin.value !== v) leftSpin.value = v;
            cfg_LeftPanelWidth = v;
        }
        function onRightPanelWidthChanged() {
            var v = plasmoid.configuration.RightPanelWidth;
            if (rightSpin.value !== v) rightSpin.value = v;
            cfg_RightPanelWidth = v;
        }
        function onSidebarWidthChanged() {
            var v = plasmoid.configuration.SidebarWidth;
            if (rightSpin.value !== v) {
                rightSpin.value = v;
                cfg_RightPanelWidth = v;
            }
        }
    }

    Component.onCompleted: {
        heightSpin.value = cfg_MenuHeight || 540;
        leftSpin.value = cfg_LeftPanelWidth || 380;
        rightSpin.value = cfg_RightPanelWidth || cfg_SidebarWidth || 220;
        offsetSpin.value = cfg_WidthOffset || 0;
        riseSpin.value = cfg_MenuRiseDistance >= 0 ? cfg_MenuRiseDistance : 6;
        if (!cfg_LeftPanelWidth)
            cfg_LeftPanelWidth = 380;
        if (!cfg_RightPanelWidth)
            cfg_RightPanelWidth = cfg_SidebarWidth || 220;
    }
}
