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

    readonly property bool bundled: CategoryIcons.isBundled(iconName)

    source: {
        if (!iconName)
            return "application-x-executable";
        if (bundled)
            return Qt.resolvedUrl("../../icons/categories/" + iconName + ".svg");
        // Face / custom paths (Kickoff-style user icons)
        if (iconName.indexOf("/") === 0)
            return "file://" + iconName;
        return iconName;
    }

    isMask: bundled
    color: tintColor
}
