import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../components" as Components

/** Shared app-drawer shell for GNOME, Android, ChromeOS, iPadOS and DeX. */
LayoutBase {
    id: root

    readonly property string variant: menuData ? menuData.currentLayoutId : "android-pixel"
    readonly property bool pixel: variant === "android-pixel"
    readonly property bool gnome: variant === "gnome-grid"
    readonly property bool dex: variant === "android-dex"
    readonly property bool desktopFooter: dex || variant === "win11-compact-grid"
    readonly property bool paged: variant === "android-oneui" || variant === "ipados-home"
        || variant === "macos-launchpad" || variant === "chromeos-tablet"
    readonly property bool hasDash: gnome
    readonly property int columns: width >= 900 ? 8 : (width >= 680 ? 6 : 5)
    readonly property var allItems: root.searching && menuData
        ? menuData.searchResultsFlat : root.allApplications
    readonly property var predicted: {
        var recent = menuData && menuData.recentApps ? menuData.recentApps : [];
        var pinned = menuData && menuData.pinnedApps ? menuData.pinnedApps : [];
        return (recent.length ? recent : pinned.length ? pinned : root.defaultPinned).slice(0, 5);
    }
    readonly property var dashItems: {
        var pinned = menuData && menuData.pinnedApps ? menuData.pinnedApps : [];
        return (pinned.length ? pinned : root.defaultPinned).slice(0, 9);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        Components.LayoutSearchField {
            layoutRoot: root
            Layout.fillWidth: true
            Layout.maximumWidth: 760
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.pixel && !root.searching
            spacing: Kirigami.Units.smallSpacing / 2

            PlasmaComponents.Label {
                text: root.tr("Suggested")
                font.weight: Font.DemiBold
                color: root.fg
            }
            Components.LayoutAppGrid {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 5.2
                layoutRoot: root
                items: root.predicted
                columns: 5
                iconSize: Math.max(44, root.gridIconSize)
            }
        }

        Components.LayoutAppGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            layoutRoot: root
            items: root.allItems
            columns: root.columns
            iconSize: Math.max(44, root.gridIconSize)
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            visible: root.paged && !root.searching
            spacing: Kirigami.Units.smallSpacing
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    width: index === 0 ? 18 : 7
                    height: 7
                    radius: 4
                    color: root.fg
                    opacity: index === 0 ? 0.8 : 0.3
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(parent.width, root.dashItems.length * 62 + 36)
            Layout.preferredHeight: Kirigami.Units.gridUnit * 4.2
            visible: root.hasDash && !root.searching
            radius: height / 2
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
            Components.LayoutAppGrid {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                layoutRoot: root
                items: root.dashItems
                columns: Math.max(1, root.dashItems.length)
                iconSize: Math.max(36, root.gridIconSize)
            }
        }

        RowLayout {
            visible: root.desktopFooter
            Layout.fillWidth: true

            Components.UserFace {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                userIcon: menuData ? menuData.userIcon : "user-identity"
                userName: menuData ? menuData.userName : ""
                fallbackColor: root.fg
            }
            Item { Layout.fillWidth: true }
            Components.SessionButtons {
                menuData: root.menuData
                enabledOptions: ["lock", "shutdown"]
                onActionRequested: (id) => root.powerAction(id)
            }
        }
    }
}
