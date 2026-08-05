import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Menu Layout")
        icon: "view-grid"
        source: "config/ConfigLayout.qml"
    }
    ConfigCategory {
        name: i18n("Theme & Appearance")
        icon: "preferences-desktop-theme"
        source: "config/ConfigTheme.qml"
    }
    ConfigCategory {
        name: i18n("Menu Content")
        icon: "view-list-details"
        source: "config/ConfigContent.qml"
    }
    ConfigCategory {
        name: i18n("Search")
        icon: "edit-find"
        source: "config/ConfigSearch.qml"
    }
    ConfigCategory {
        name: i18n("System Actions")
        icon: "system-shutdown"
        source: "config/ConfigPower.qml"
    }
    ConfigCategory {
        name: i18n("About")
        icon: "help-about"
        source: "config/ConfigAbout.qml"
    }
}
