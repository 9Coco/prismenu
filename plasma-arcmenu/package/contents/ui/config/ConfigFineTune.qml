import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale

/**
 * Fine-tuning — ArcMenu-style behavior toggles.
 */
Item {
    id: root

    property bool cfg_ShowCategorySubmenus
    property bool cfg_ShowAppDescriptions
    property bool cfg_ShowGenericNames
    property bool cfg_ShowHiddenRecentFiles
    property bool cfg_MultiLineLabels
    property bool cfg_ShowTooltips
    property bool cfg_GroupAppsAlphabeticallyList
    property bool cfg_GroupAppsAlphabeticallyGrid
    property bool cfg_ActivateExistingWindow
    property bool cfg_KeepOpenOnCtrlClick
    property bool cfg_ScrollviewFadeEffects
    property bool cfg_ShowScrollbars
    property bool cfg_OverlayScrollbars
    property string cfg_CategoryIconType
    property string cfg_ShortcutIconType

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }
    function writeLive(key, value) { try { plasmoid.configuration[key] = value; } catch (e) {} }

    function resetDefaults() {
        cfg_ShowCategorySubmenus = false;
        cfg_ShowAppDescriptions = false;
        cfg_ShowGenericNames = false;
        cfg_ShowHiddenRecentFiles = false;
        cfg_MultiLineLabels = true;
        cfg_ShowTooltips = true;
        cfg_GroupAppsAlphabeticallyList = true;
        cfg_GroupAppsAlphabeticallyGrid = false;
        cfg_ActivateExistingWindow = false;
        cfg_KeepOpenOnCtrlClick = true;
        cfg_ScrollviewFadeEffects = true;
        cfg_ShowScrollbars = true;
        cfg_OverlayScrollbars = true;
        cfg_CategoryIconType = "symbolic";
        cfg_ShortcutIconType = "symbolic";
        writeLive("showCategorySubmenus", false);
        writeLive("showAppDescriptions", false);
        writeLive("showGenericNames", false);
        writeLive("showHiddenRecentFiles", false);
        writeLive("multiLineLabels", true);
        writeLive("showTooltips", true);
        writeLive("groupAppsAlphabeticallyList", true);
        writeLive("groupAppsAlphabeticallyGrid", false);
        writeLive("activateExistingWindow", false);
        writeLive("keepOpenOnCtrlClick", true);
        writeLive("scrollviewFadeEffects", true);
        writeLive("showScrollbars", true);
        writeLive("overlayScrollbars", true);
        writeLive("categoryIconType", "symbolic");
        writeLive("shortcutIconType", "symbolic");
        catIconCombo.currentIndex = 1;
        shortcutIconCombo.currentIndex = 1;
    }

    ConfigPage {
        title: root.tr("Fine-tuning")
        tip: root.tr("Adjust less commonly used settings")

        ConfigGroup {
            title: root.tr("General")
            ConfigSettingRow {
                title: root.tr("Show category submenus")
                iconName: "view-list-tree"
                accent: "blue"
                QQC2.Switch {
                    checked: cfg_ShowCategorySubmenus
                    onToggled: { cfg_ShowCategorySubmenus = checked; writeLive("showCategorySubmenus", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Show application descriptions")
                iconName: "text-x-generic"
                accent: "purple"
                QQC2.Switch {
                    checked: cfg_ShowAppDescriptions
                    onToggled: { cfg_ShowAppDescriptions = checked; writeLive("showAppDescriptions", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Show generic application names")
                iconName: "edit-rename"
                accent: "teal"
                QQC2.Switch {
                    checked: cfg_ShowGenericNames
                    onToggled: { cfg_ShowGenericNames = checked; writeLive("showGenericNames", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Show hidden recent files")
                iconName: "view-hidden"
                accent: "orange"
                QQC2.Switch {
                    checked: cfg_ShowHiddenRecentFiles
                    onToggled: { cfg_ShowHiddenRecentFiles = checked; writeLive("showHiddenRecentFiles", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Show multi-lined labels")
                subtitle: root.tr("Allows application labels to span multiple lines on grid-style layouts.")
                iconName: "format-justify-fill"
                accent: "green"
                QQC2.Switch {
                    checked: cfg_MultiLineLabels
                    onToggled: { cfg_MultiLineLabels = checked; writeLive("multiLineLabels", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Show tooltips")
                iconName: "help-hint"
                accent: "cyan"
                QQC2.Switch {
                    checked: cfg_ShowTooltips
                    onToggled: { cfg_ShowTooltips = checked; writeLive("showTooltips", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Group apps alphabetically on list views")
                subtitle: root.tr("For All Apps sections.")
                iconName: "view-sort-ascending"
                accent: "indigo"
                QQC2.Switch {
                    checked: cfg_GroupAppsAlphabeticallyList
                    onToggled: { cfg_GroupAppsAlphabeticallyList = checked; writeLive("groupAppsAlphabeticallyList", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Group apps alphabetically on grid views")
                subtitle: root.tr("For All Apps sections.")
                iconName: "view-app-grid-symbolic"
                accent: "pink"
                QQC2.Switch {
                    checked: cfg_GroupAppsAlphabeticallyGrid
                    onToggled: { cfg_GroupAppsAlphabeticallyGrid = checked; writeLive("groupAppsAlphabeticallyGrid", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Activate app window on launch")
                subtitle: root.tr("Launching an app activates its existing window if one is open; otherwise, it launches a new instance. Hold Ctrl while launching or middle-click to open a new window.")
                iconName: "window"
                accent: "yellow"
                QQC2.Switch {
                    checked: cfg_ActivateExistingWindow
                    onToggled: { cfg_ActivateExistingWindow = checked; writeLive("activateExistingWindow", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Keep ArcMenu open on Ctrl+Click")
                subtitle: root.tr("Prevents the menu from closing when activating items while holding Ctrl.")
                iconName: "input-keyboard"
                accent: "red"
                QQC2.Switch {
                    checked: cfg_KeepOpenOnCtrlClick
                    onToggled: { cfg_KeepOpenOnCtrlClick = checked; writeLive("keepOpenOnCtrlClick", checked); }
                }
            }
        }

        ConfigGroup {
            title: root.tr("Scrollview options")
            ConfigSettingRow {
                title: root.tr("Scrollview fade effects")
                iconName: "preferences-desktop-effects"
                accent: "blue"
                QQC2.Switch {
                    checked: cfg_ScrollviewFadeEffects
                    onToggled: { cfg_ScrollviewFadeEffects = checked; writeLive("scrollviewFadeEffects", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Show scrollbars")
                iconName: "view-fullscreen"
                accent: "purple"
                QQC2.Switch {
                    checked: cfg_ShowScrollbars
                    onToggled: { cfg_ShowScrollbars = checked; writeLive("showScrollbars", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Overlay scrollbars")
                iconName: "layer-visible-on"
                accent: "teal"
                opacity: cfg_ShowScrollbars ? 1 : 0.45
                QQC2.Switch {
                    checked: cfg_OverlayScrollbars
                    enabled: cfg_ShowScrollbars
                    onToggled: { cfg_OverlayScrollbars = checked; writeLive("overlayScrollbars", checked); }
                }
            }
        }

        ConfigGroup {
            title: root.tr("Icon style")
            ConfigSettingRow {
                title: root.tr("Category icon type")
                subtitle: root.tr("Some icon themes may not include the selected icon type.")
                iconName: "preferences-desktop-icons"
                accent: "orange"
                QQC2.ComboBox {
                    id: catIconCombo
                    model: [root.tr("Full Color"), root.tr("Symbolic")]
                    Component.onCompleted: currentIndex = cfg_CategoryIconType === "fullcolor" ? 0 : 1
                    onActivated: {
                        cfg_CategoryIconType = currentIndex === 0 ? "fullcolor" : "symbolic";
                        writeLive("categoryIconType", cfg_CategoryIconType);
                    }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Shortcut icon type")
                iconName: "favorite"
                accent: "green"
                QQC2.ComboBox {
                    id: shortcutIconCombo
                    model: [root.tr("Full Color"), root.tr("Symbolic")]
                    Component.onCompleted: currentIndex = cfg_ShortcutIconType === "fullcolor" ? 0 : 1
                    onActivated: {
                        cfg_ShortcutIconType = currentIndex === 0 ? "fullcolor" : "symbolic";
                        writeLive("shortcutIconType", cfg_ShortcutIconType);
                    }
                }
            }
        }

        QQC2.Button {
            text: root.tr("Reset to defaults")
            onClicked: root.resetDefaults()
        }
    }
}
