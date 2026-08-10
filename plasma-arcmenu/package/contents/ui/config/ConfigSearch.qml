import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale

/**
 * Search Options — ConfigPage chrome.
 */
Item {
    id: root

    property var cfg_Providers: ["applications"]
    property string cfg_Placeholder
    property bool cfg_ShowDescription
    property int cfg_MaxResults
    property bool cfg_HideSearchBar
    property bool cfg_HighlightSearchTerms
    property bool cfg_SearchBoxRadiusEnabled
    property int cfg_SearchBoxRadius
    property bool cfg_SearchWindows
    property bool cfg_SearchRecentFiles

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.UiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) { return Locale.tr(msgid, uiLang); }
    function writeLive(key, value) {
        try {
            plasmoid.configuration[key] = value;
            try { plasmoid.configuration.writeConfig(); } catch (e2) {}
        } catch (e) {}
    }

    ConfigPage {
        title: root.tr("Search Options")
        tip: root.tr("Providers, highlight, and result limits")

        ConfigGroup {
            title: root.tr("Search Options")
            ConfigSettingRow {
                title: root.tr("Hide Search Bar")
                subtitle: root.tr("The search bar hides when empty and appears when typing.")
                iconName: "edit-find"
                accent: "blue"
                QQC2.Switch {
                    checked: cfg_HideSearchBar
                    onToggled: { cfg_HideSearchBar = checked; writeLive("HideSearchBar", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Show search result descriptions")
                iconName: "text-x-generic"
                accent: "purple"
                QQC2.Switch {
                    checked: cfg_ShowDescription
                    onToggled: { cfg_ShowDescription = checked; writeLive("ShowDescription", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Highlight search result terms")
                iconName: "format-text-color"
                accent: "teal"
                QQC2.Switch {
                    checked: cfg_HighlightSearchTerms
                    onToggled: { cfg_HighlightSearchTerms = checked; writeLive("HighlightSearchTerms", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Maximum search results")
                iconName: "view-list-details"
                accent: "orange"
                QQC2.SpinBox {
                    from: 1; to: 100
                    value: cfg_MaxResults > 0 ? cfg_MaxResults : 5
                    onValueModified: { cfg_MaxResults = value; writeLive("MaxResults", value); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Search box border radius")
                iconName: "draw-square-rounded"
                accent: "green"
                QQC2.Switch {
                    checked: cfg_SearchBoxRadiusEnabled
                    onToggled: { cfg_SearchBoxRadiusEnabled = checked; writeLive("SearchBoxRadiusEnabled", checked); }
                }
                QQC2.SpinBox {
                    from: 0; to: 48
                    enabled: cfg_SearchBoxRadiusEnabled
                    value: cfg_SearchBoxRadius
                    onValueModified: { cfg_SearchBoxRadius = value; writeLive("SearchBoxRadius", value); }
                }
            }
        }

        ConfigGroup {
            title: root.tr("Additional Search Providers")
            ConfigSettingRow {
                title: root.tr("Search windows open in all workspaces")
                iconName: "window-duplicate"
                accent: "indigo"
                QQC2.Switch {
                    checked: cfg_SearchWindows
                    onToggled: { cfg_SearchWindows = checked; writeLive("SearchWindows", checked); }
                }
            }
            ConfigSep {}
            ConfigSettingRow {
                title: root.tr("Search recent files")
                iconName: "document-open-recent"
                accent: "cyan"
                QQC2.Switch {
                    checked: cfg_SearchRecentFiles
                    onToggled: { cfg_SearchRecentFiles = checked; writeLive("SearchRecentFiles", checked); }
                }
            }
        }
    }

    Component.onCompleted: {
        if (!cfg_MaxResults) cfg_MaxResults = 5;
        if (cfg_SearchBoxRadius === undefined || cfg_SearchBoxRadius === null)
            cfg_SearchBoxRadius = 25;
    }
}
