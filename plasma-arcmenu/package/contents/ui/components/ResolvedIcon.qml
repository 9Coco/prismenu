import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
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
    property int _svgRevision: 0

    // Local SVGs are not theme icon names. Give Kirigami a rendered image so
    // its Plasma theme adapter does not search every icon theme for their
    // file basenames during the first popup polish. KSvg keeps native SVG
    // caching; Kirigami still handles mask tinting and selection colors.
    KSvg.Svg {
        id: localSvg
        imagePath: root.bundled
            ? Qt.resolvedUrl("../../icons/categories/" + root.iconName + ".svg")
            : (root.preset ? Qt.resolvedUrl("../../icons/menu-button/" + root.iconName + ".svg") : "")
        onRepaintNeeded: root._svgRevision++
    }

    source: {
        if (!iconName)
            return "application-x-executable";
        if (bundled || preset) {
            const revision = root._svgRevision;
            return localSvg.image(Qt.size(
                Math.max(1, Math.ceil(root.width * root.Screen.devicePixelRatio)),
                Math.max(1, Math.ceil(root.height * root.Screen.devicePixelRatio))));
        }
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
