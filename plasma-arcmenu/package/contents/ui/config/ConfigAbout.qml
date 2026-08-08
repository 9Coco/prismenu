import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../../code/Locale.js" as Locale

Item {
    id: root

    readonly property string uiLanguagePref: {
        try { return plasmoid.configuration.uiLanguage || "zh_CN"; } catch (e) { return "zh_CN"; }
    }
    readonly property string uiLang: Locale.resolveLanguage(uiLanguagePref, Qt.locale().name, Qt.locale().uiLanguages)

    function tr(msgid) {
        return Locale.tr(msgid, uiLang);
    }

    function trf(msgid, arg1) {
        return Locale.trf(msgid, uiLang, arg1);
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.Icon {
                source: "start-here-kde"
                Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                Layout.preferredHeight: Kirigami.Units.iconSizes.huge
            }
            ColumnLayout {
                Kirigami.Heading {
                    text: root.tr("Arc Menu for KDE Plasma")
                    level: 1
                }
                QQC2.Label { text: root.trf("Version %1", "1.0.0") }
                QQC2.Label { text: root.tr("License: GPL-2.0-or-later") }
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: root.tr("A feature-rich Plasma application menu with 14 switchable layouts, deep appearance customization, favorites, recent apps, Plasma Search integration, and system actions. Designed for Kubuntu and other Plasma desktops.")
        }

        Kirigami.Heading { text: root.tr("Credits"); level: 2 }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: root.tr("Inspired by the Arc Menu project for GNOME Shell and the layout diversity of traditional Linux/Windows start menus. Built on KDE Frameworks, Plasma, Kirigami, and KService.")
        }

        Kirigami.Heading { text: root.tr("Links"); level: 2 }
        QQC2.Label { text: "https://github.com/arcmenu/plasma-arcmenu" }
    }
}
