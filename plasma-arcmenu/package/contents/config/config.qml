import QtQuick
import org.kde.plasma.configuration
import org.kde.plasma.plasmoid
import "../code/Locale.js" as Locale

ConfigModel {
    id: configModel

    // Use the same built-in Locale.js pack as the menu (no .mo install required).
    readonly property string uiLang: Locale.resolveLanguage(
        (function () {
            try {
                return plasmoid.configuration.uiLanguage || "zh_CN";
            } catch (e) {
                return "zh_CN";
            }
        })(),
        Qt.locale().name,
        Qt.locale().uiLanguages)

    function tr(msgid) {
        return Locale.tr(msgid, uiLang);
    }

    ConfigCategory {
        name: configModel.tr("General")
        icon: "preferences-desktop"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: configModel.tr("Menu Button")
        icon: "view-app-grid-symbolic"
        source: "config/ConfigMenuButton.qml"
    }
    ConfigCategory {
        name: configModel.tr("Menu Layout")
        icon: "view-grid"
        source: "config/ConfigLayout.qml"
    }
    ConfigCategory {
        name: configModel.tr("ArcMenu layout adjustment")
        icon: "view-list-tree"
        source: "config/ConfigArcLayout.qml"
    }
    ConfigCategory {
        name: configModel.tr("Pinned Applications")
        icon: "pin"
        source: "config/ConfigPinned.qml"
    }
    ConfigCategory {
        name: configModel.tr("Directory Shortcuts")
        icon: "folder"
        source: "config/ConfigDirectoryShortcuts.qml"
    }
    ConfigCategory {
        name: configModel.tr("Application Shortcuts")
        icon: "applications-other"
        source: "config/ConfigAppShortcuts.qml"
    }
    ConfigCategory {
        name: configModel.tr("Extra Categories")
        icon: "view-list-details"
        source: "config/ConfigExtraCategories.qml"
    }
    ConfigCategory {
        name: configModel.tr("Menu Visual Appearance")
        icon: "preferences-desktop-display"
        source: "config/ConfigVisual.qml"
    }
    ConfigCategory {
        name: configModel.tr("Menu Theme")
        icon: "preferences-desktop-theme"
        source: "config/ConfigTheme.qml"
    }
    ConfigCategory {
        name: configModel.tr("Fine-tuning")
        icon: "preferences-other"
        source: "config/ConfigFineTune.qml"
    }
    ConfigCategory {
        name: configModel.tr("Menu Content")
        icon: "view-catalog"
        source: "config/ConfigContent.qml"
    }
    ConfigCategory {
        name: configModel.tr("Search Options")
        icon: "edit-find"
        source: "config/ConfigSearch.qml"
    }
    ConfigCategory {
        name: configModel.tr("Power Options")
        icon: "system-shutdown"
        source: "config/ConfigPower.qml"
    }
    ConfigCategory {
        name: configModel.tr("Modify ArcMenu Context Menu")
        icon: "open-menu-symbolic"
        source: "config/ConfigContextMenu.qml"
    }
    // No custom About page — Plasma already adds one from metadata.json
}
