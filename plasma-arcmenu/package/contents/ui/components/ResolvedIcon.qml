import QtQuick
import org.kde.kirigami as Kirigami
import "../../code/CategoryIcons.js" as CategoryIcons

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

    source: {
        if (!iconName)
            return "application-x-executable";
        if (bundled)
            return Qt.resolvedUrl("../../icons/categories/" + iconName + ".svg");
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

    isMask: bundled || root.preferSymbolic
    color: tintColor
}
