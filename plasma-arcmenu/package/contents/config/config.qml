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
                return plasmoid.configuration.UiLanguage || "zh_CN";
            } catch (e) {
                return "zh_CN";
            }
        })(),
        Qt.locale().name,
        Qt.locale().uiLanguages)

    function tr(msgid) {
        return Locale.tr(msgid, uiLang);
    }

    // Top-level matches GNOME ArcMenu: General / Menu / Menu Button (+ Plasma About).
    ConfigCategory {
        name: configModel.tr("General")
        icon: "preferences-desktop"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: configModel.tr("Menu")
        icon: "settings-configure"
        source: "config/ConfigMenu.qml"
    }
    ConfigCategory {
        name: configModel.tr("Menu Button")
        icon: "view-app-grid-symbolic"
        source: "config/ConfigMenuButton.qml"
    }
    // No custom About page — Plasma already adds one from metadata.json
}
