import QtQuick
import org.kde.kirigami as Kirigami
import "../../code/CategoryIcons.js" as CategoryIcons
import "../../code/PresetIcons.js" as PresetIcons

/**
 * Kirigami.Icon that resolves bundled arcmenu-cat-* SVGs from contents/icons/categories/.
 */
Kirigami.Icon {
    id: root

    property string iconName: ""
    /** When set, used for bundled (mask) icons so they follow list selection/hover. */
    property color tintColor: Kirigami.Theme.textColor
    /** Prefer symbolic / mask rendering (Fine-tuning → Icon style) */
    property bool preferSymbolic: true

    readonly property bool bundled: CategoryIcons.isBundled(iconName)
    readonly property bool preset: PresetIcons.isPreset(iconName)
    
    source: {
        if (!iconName)
            return "application-x-executable";
        if (bundled)
            return Qt.resolvedUrl("../../icons/categories/" + iconName + ".svg");
        // Bundled menu-button presets (distro logos, arcmenu icons)
        if (preset)
            return Qt.resolvedUrl("../../icons/menu-button/" + iconName + ".svg");
        // Face / custom paths (Kickoff-style user icons)
        if (iconName.indexOf("/") === 0)
            return "file://" + iconName;
        if (root.preferSymbolic) {
            var n = String(iconName);
            if (n.indexOf("-symbolic") < 0 && n.indexOf("/") < 0 && n.indexOf(".") < 0)
                return n + "-symbolic";
        }
        return iconName;
    }

    isMask: bundled || (preset && PresetIcons.isSymbolic(iconName)) || root.preferSymbolic
    color: tintColor
}
