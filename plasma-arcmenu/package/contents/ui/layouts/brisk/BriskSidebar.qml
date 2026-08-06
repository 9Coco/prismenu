import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

/**
 * Brisk left sidebar:
 *   Pinned / All Applications
 *   ── categories ──
 *   Software / Settings
 */
Item {
    id: root

    property var menuData: null
    property string selectedId: "pinned" // pinned | all | <categoryId>
    property int iconSize: 22
    property color selectedBg: Kirigami.Theme.highlightColor
    property color selectedFg: Kirigami.Theme.highlightedTextColor
    property color fg: Kirigami.Theme.textColor

    signal selectionChanged(string id)
    signal shortcutActivated(var item)

    readonly property var categories: {
        var out = [];
        if (!menuData || !menuData.categories) {
            return out;
        }
        var cats = menuData.categories;
        for (var i = 0; i < cats.length; ++i) {
            if (cats[i].id === "all") {
                continue;
            }
            out.push(cats[i]);
        }
        return out;
    }

    readonly property var extras: [
        { id: "shortcut-software", name: i18n("Software"), icon: "plasmadiscover", action: "discover" },
        { id: "shortcut-settings", name: i18n("Settings"), icon: "preferences-system", action: "settings" }
    ]

    function categoryLabel(cat) {
        if (!cat) return "";
        switch (cat.id) {
        case "Office": return i18n("Office");
        case "Development": return i18n("Development");
        case "Accessories": return i18n("Accessories");
        case "Utility": return i18n("Utilities");
        case "Network": return i18n("Internet");
        case "Graphics": return i18n("Graphics");
        case "System": return i18n("System Tools");
        case "Game": return i18n("Games");
        case "Education": return i18n("Education");
        case "AudioVideo": return i18n("Multimedia");
        case "Settings": return i18n("Settings");
        default: return cat.name || "";
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: flick.width
            spacing: Kirigami.Units.smallSpacing / 2

            // ---- Pinned / All ----
            BriskNavRow {
                width: col.width
                iconName: "pin"
                label: i18n("Pinned Applications")
                iconSize: root.iconSize
                selected: root.selectedId === "pinned"
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                fg: root.fg
                onActivated: root.selectionChanged("pinned")
            }

            BriskNavRow {
                width: col.width
                iconName: "view-app-grid-symbolic"
                label: i18n("All Applications")
                iconSize: root.iconSize
                selected: root.selectedId === "all"
                selectedBg: root.selectedBg
                selectedFg: root.selectedFg
                fg: root.fg
                onActivated: root.selectionChanged("all")
            }

            Kirigami.Separator {
                width: col.width
                opacity: 0.4
            }

            // ---- Categories ----
            Repeater {
                model: root.categories.length
                BriskNavRow {
                    required property int index
                    width: col.width
                    iconName: root.categories[index].icon || "applications-other"
                    label: root.categoryLabel(root.categories[index])
                    iconSize: root.iconSize
                    selected: root.selectedId === root.categories[index].id
                    selectedBg: root.selectedBg
                    selectedFg: root.selectedFg
                    fg: root.fg
                    onActivated: root.selectionChanged(root.categories[index].id)
                }
            }

            Kirigami.Separator {
                width: col.width
                opacity: 0.4
            }

            // ---- Software / Settings ----
            Repeater {
                model: root.extras.length
                BriskNavRow {
                    required property int index
                    width: col.width
                    iconName: root.extras[index].icon
                    label: root.extras[index].name
                    iconSize: root.iconSize
                    selected: false
                    selectedBg: root.selectedBg
                    selectedFg: root.selectedFg
                    fg: root.fg
                    onActivated: root.shortcutActivated(root.extras[index])
                }
            }

            Kirigami.Separator {
                width: col.width
                opacity: 0.4
            }
        }
    }
}
