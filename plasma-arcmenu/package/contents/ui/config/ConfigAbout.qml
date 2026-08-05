import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
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
                    text: i18n("Arc Menu for KDE Plasma")
                    level: 1
                }
                QQC2.Label { text: i18n("Version %1", "1.0.0") }
                QQC2.Label { text: i18n("License: GPL-2.0-or-later") }
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("A feature-rich Plasma application menu with 14 switchable layouts, deep appearance customization, favorites, recent apps, Plasma Search integration, and system actions. Designed for Kubuntu and other Plasma desktops.")
        }

        Kirigami.Heading { text: i18n("Credits"); level: 2 }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("Inspired by the Arc Menu project for GNOME Shell and the layout diversity of traditional Linux/Windows start menus. Built on KDE Frameworks, Plasma, Kirigami, and KService.")
        }

        Kirigami.Heading { text: i18n("Links"); level: 2 }
        QQC2.Label { text: "https://github.com/arcmenu/plasma-arcmenu" }
    }
}
