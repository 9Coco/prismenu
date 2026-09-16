import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import "../../code/CategoryIcons.js" as CategoryIcons
import "../../code/PresetIcons.js" as PresetIcons
import "../../code/SearchExtras.js" as SearchExtras

/**
 * Kirigami.Icon that preserves native decorations and resolves bundled SVGs.
 */
Kirigami.Icon {
    id: root

    property string iconName: ""
    property var iconItem: null
    /** When set, used for bundled (mask) icons so they follow list selection/hover. */
    property color tintColor: Kirigami.Theme.textColor
    /** Prefer symbolic / mask rendering (Fine-tuning → Icon style) */
    property bool preferSymbolic: true

    readonly property var itemSource: iconItem ? SearchExtras.resultIconSource(iconItem) : iconName
    readonly property string sourceName: typeof itemSource === "string" ? itemSource : ""
    readonly property bool bundled: CategoryIcons.isBundled(sourceName)
    readonly property bool preset: PresetIcons.isPreset(sourceName)
    property int _svgRevision: 0

    // Local SVGs are not theme icon names. Give Kirigami a rendered image so
    // its Plasma theme adapter does not search every icon theme for their
    // file basenames during the first popup polish. KSvg keeps native SVG
    // caching; Kirigami still handles mask tinting and selection colors.
    KSvg.Svg {
        id: localSvg
        imagePath: root.bundled
            ? Qt.resolvedUrl("../../icons/categories/" + root.sourceName + ".svg")
            : (root.preset ? Qt.resolvedUrl("../../icons/menu-button/" + root.sourceName + ".svg") : "")
        onRepaintNeeded: root._svgRevision++
    }

    fallback: iconName || "application-x-executable"
    source: {
        // QIcon decorations have no QML-accessible name; keep the native value.
        if (root.itemSource && typeof root.itemSource !== "string")
            return root.itemSource;
        if (!sourceName)
            return fallback;
        if (bundled || preset) {
            const revision = root._svgRevision;
            return localSvg.image(Qt.size(
                Math.max(1, Math.ceil(root.width * root.Screen.devicePixelRatio)),
                Math.max(1, Math.ceil(root.height * root.Screen.devicePixelRatio))));
        }
        // Face / custom paths (Kickoff-style user icons)
        if (sourceName.indexOf("/") === 0)
            return "file://" + sourceName;
        if (root.preferSymbolic) {
            var n = sourceName;
            if (n.indexOf("-symbolic") < 0 && n.indexOf("/") < 0 && n.indexOf(".") < 0)
                return n + "-symbolic";
        }
        return sourceName;
    }

    isMask: bundled || (preset && PresetIcons.isSymbolic(sourceName)) || root.preferSymbolic
    color: tintColor
}
