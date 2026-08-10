import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

/**
 * Edge / corner drag handles to resize the menu popup.
 *
 * While dragging, only liveWidth / liveHeight change (one cheap property
 * write per mouse move — no config writes). The host (main.qml) binds the
 * popup's Layout min/max/preferred to these values; this file then applies
 * the size to whichever host is in use:
 *
 * 1. Desktop (inline expansion, formFactor Planar): the menu lives inside
 *    the containment's AppletContainer. The containment's GridLayoutManager
 *    applies Layout hints one-way only — it grows containers but never
 *    shrinks them (its maximum branch is disabled upstream) — which is why
 *    dragging smaller used to do nothing. We resize the container directly,
 *    the same flow Plasma's own edit-mode resize handles use: releaseSpace()
 *    while dragging, positionItem() on release (snaps to grid + persists).
 *
 * 2. Panel (AppletPopup window): libplasma converts Layout min/max changes
 *    into window resizes; growing via updateMinSize() is reliable, but
 *    shrinking via updateMaxSize() can be reverted by a Wayland race, so
 *    syncWindowSize() ALSO resizes the popup window directly on every move.
 *
 * The final size is persisted once, through the catalog (MenuData), when
 * the drag ends.
 */
Item {
    id: root

    property var menuData: null
    /** Extra popup width outside menuWidth (layout side panel). */
    property int sideWidth: 0
    property int minWidth: 400
    /** Soft cap only — effectiveMaxWidth below raises it to screen fit (the
     *  fixed 900 used to stop the horizontal drag mid-screen). */
    property int maxWidth: 1200
    property int minHeight: 400
    /** Hard ceiling only for popup hosts; desktop inline gets a screen-fit
     *  ceiling via effectiveMaxHeight below (the old fixed 800 made the
     *  vertical drag "lock" on tall screens). */
    property int maxHeight: 800
    readonly property int effectiveMaxHeight: {
        if (root.dragContainer)
            return Math.max(root.maxHeight, Screen.height - 80);
        return root.maxHeight;
    }
    /** Screen-fit ceiling for the content width: never wider than the screen
     *  minus the layout's side panel and a safety margin. */
    readonly property int effectiveMaxWidth: {
        var cap = Screen.width - root.sideWidth - 80;
        return Math.max(root.maxWidth, cap);
    }
    property int handleThickness: 6
    property bool resizeHeight: true

    /** Live drag size (content, excluding sideWidth); -1 while idle. */
    property int liveWidth: -1
    property int liveHeight: -1
    readonly property bool dragging: liveWidth > 0 || liveHeight > 0

    /** Desktop AppletContainer found on press (null in panel/popup hosts). */
    property var dragContainer: null
    /** Scene-space bottom edge captured on press — the fixed anchor. */
    property real pressBottom: 0
    /** Container-y target of the current drag frame (bottom-left anchor). */
    property real targetY: 0
    /** Reused Translate that cancels the containment's y-glide lag. */
    property var compTranslate: null
    /** Container transforms saved before compensation (restored on release). */
    property var origTransforms: null
    /** True while this file writes container geometry (suppresses ext logs). */
    property bool writingGeom: false
    /** Wallpaper-blur layer behind the applet (see killBackdropBlur). */
    property var backdropBg: null

    Component {
        id: translateComp
        Translate {}
    }

    /**
     * The containment glides every container-y write (~100 ms, retargeted on
     * each move — the ease-in restarts every frame, so the edge crawls far
     * behind the mouse instead of merely trailing 100 ms). The animator
     * lives in the containment internals where we cannot see or disable it
     * (runtime scans find no Behavior on the container). Size writes apply
     * instantly; only y glides.
     *
     * So the drag never writes container.y — the glide is never started.
     * The painted position is nailed to the target purely by a transform:
     * ty = targetY - actual y. Only on release do we write y once, and the
     * transform keeps the visuals exact through that single glide until the
     * grid snap settles.
     */
    /**
     * The desktop container paints a blurred-wallpaper backdrop behind the
     * applet (BasicAppletContainer's maskItem, an Effects.MultiEffect
     * re-parented to the containment root, positioned from ScenePosition —
     * which ignores transforms, so it also leaked a smeared band above the
     * top edge during vertical drags). The menu paints its own opaque
     * background and never uses this layer, so hide it outright — also
     * re-hides it if the containment recreates it (blurEnabledChanged).
     */
    function killBackdropBlur() {
        if (!root.backdropBg) {
            var c = root.appletContainer();
            if (!c || !c.background)
                return;
            root.backdropBg = c.background;
        }
        if (root.backdropBg.maskItem)
            root.backdropBg.maskItem.visible = false;
    }

    Timer {
        id: killBlurTimer
        interval: 400
        onTriggered: root.killBackdropBlur()
    }

    Connections {
        target: root.backdropBg
        ignoreUnknownSignals: true
        function onBlurEnabledChanged() {
            if (root.backdropBg && root.backdropBg.maskItem)
                root.backdropBg.maskItem.visible = false;
        }
    }

    Component.onCompleted: killBlurTimer.start()

    function compensate() {
        var c = root.dragContainer;
        if (!c)
            return;
        var off = root.targetY - c.y;
        if (Math.abs(off) < 0.5) {
            if (root.compTranslate)
                root.compTranslate.y = 0;
            return;
        }
        if (!root.compTranslate) {
            root.origTransforms = c.transform;
            root.compTranslate = translateComp.createObject(root);
            c.transform = root.compTranslate;
        }
        root.compTranslate.y = off;
    }

    function clearCompensation() {
        var c = root.dragContainer;
        if (root.compTranslate) {
            root.compTranslate.y = 0;
            root.compTranslate.destroy();
            root.compTranslate = null;
        }
        if (c)
            c.transform = root.origTransforms;
        root.origTransforms = null;
    }

    /**
     * Walk up to find the desktop AppletContainer (an ItemContainer managed
     * by AppletsLayout). Present only when the applet is expanded inline on
     * the desktop; panel applets expand into an AppletPopup window instead.
     */
    function appletContainer() {
        var p = root.parent;
        while (p) {
            if (p.layout !== undefined && p.layout !== null
                    && typeof p.layout.positionItem === "function")
                return p;
            p = p.parent;
        }
        return null;
    }

    /**
     * Resize the desktop AppletContainer directly.
     * GridLayoutManager::adjustToItemSizeHints() only grows containers from
     * Layout hints, never shrinks them — so shrinking must set the geometry
     * explicitly, like Plasma's own ResizeHandle: releaseSpace() per move,
     * positionItem() on release (re-registers the grid cells, snaps to the
     * cell grid and persists ItemGeometries via layoutNeedsSaving).
     */
    function syncContainerSize(role) {
        var container = root.dragContainer;
        if (!container)
            return;
        var lay = container.layout;
        // Container = content + background margins; keep the delta.
        var chromeW = container.width - root.width;
        var chromeH = container.height - root.height;
        var w = Math.round((root.liveWidth > 0 ? root.liveWidth + root.sideWidth : root.width) + chromeW);
        var h = Math.round((root.liveHeight > 0 ? root.liveHeight : root.height) + chromeH);
        if (lay && typeof lay.releaseSpace === "function")
            lay.releaseSpace(container);
        // Launcher semantics: the bottom-left corner is the fixed origin.
        // Left edge never moves; bottom edge never moves — height changes
        // always grow/shrink upward (like a menu anchored to a taskbar
        // button), regardless of which edge handle is being dragged.
        //
        // Never write container.y during the drag: every y write retargets
        // the containment's ~100ms glide, and reading c.y right after a
        // write returns the new target, not the gliding painted value — the
        // compensation then zeroed against a paint still mid-glide, which
        // ghosted fast vertical drags. Keep c.y untouched for the whole
        // drag and nail the painted position purely with the translate.
        root.writingGeom = true;
        container.width = w;
        container.height = h;
        root.writingGeom = false;
        root.targetY = root.pressBottom - h;
        // Safe here: no glide is running (we didn't touch y), so c.y reads
        // the real painted position and the offset is exact.
        root.compensate();
    }

    /**
     * Geometry watchdogs: the transform compensation keeps visuals nailed
     * to the target; if anything external rewrites the geometry anyway,
     * re-assert the target (guarded by writingGeom to ignore our writes).
     */
    Connections {
        target: root.dragContainer
        ignoreUnknownSignals: true
        function onYChanged() {
            if (!root.dragContainer)
                return;
            // Skip our own geometry writes: right after a write c.y reads the
            // new target, not the gliding painted value — recomputing then
            // would zero the compensation and ghost the paint for a frame.
            if (root.writingGeom)
                return;
            // Glide moved the container: create/refresh the lag compensation
            // so the painted position stays nailed to targetY.
            root.compensate();
        }
        function onHeightChanged() {
            if (root.dragContainer && !root.writingGeom)
                console.log("ArcMenu ext h:", Date.now() % 100000,
                            "h", Math.round(root.dragContainer.height),
                            "y", Math.round(root.dragContainer.y));
        }
        function onWidthChanged() {
            if (root.dragContainer && !root.writingGeom)
                console.log("ArcMenu ext w:", Date.now() % 100000,
                            "w", Math.round(root.dragContainer.width));
        }
        function onXChanged() {
            if (root.dragContainer && !root.writingGeom)
                console.log("ArcMenu ext x:", Date.now() % 100000,
                            "x", Math.round(root.dragContainer.x));
        }
    }

    /**
     * Deferred grid re-registration, two passes:
     * 1st pass — the y glide may not have settled at release; wait for it,
     *            then positionItem() (snaps to the cell grid + persists).
     * 2nd pass — the snap itself glides y a bit; the compensation kept the
     *            visuals exact through it — drop it now and detach.
     */
    property bool commitSnapped: false
    Timer {
        id: commitTimer
        interval: 120
        repeat: false
        onTriggered: {
            var c = root.dragContainer;
            if (!c) {
                root.commitSnapped = false;
                return;
            }
            if (!root.commitSnapped) {
                root.commitSnapped = true;
                if (c.layout && typeof c.layout.positionItem === "function")
                    c.layout.positionItem(c);
                commitTimer.restart();
                return;
            }
            root.commitSnapped = false;
            root.clearCompensation();
            root.dragContainer = null;
        }
    }

    /** One-shot environment dump on first press (host window identity). */
    property bool envLogged: false
    function logEnvOnce() {
        if (root.envLogged)
            return;
        root.envLogged = true;
        var w = root.Window.window;
        var ff = -1, loc = -1, exp = false;
        try { ff = plasmoid.formFactor; loc = plasmoid.location; exp = plasmoid.expanded; } catch (e) {}
        console.log("ArcMenu env:",
                    "formFactor", ff, "(0=Planar/desktop 1=Horizontal 2=Vertical)",
                    "location", loc, "expanded", exp,
                    "screen", Screen.width, "x", Screen.height,
                    "rep", Math.round(root.width), "x", Math.round(root.height),
                    "win", w ? (Math.round(w.width) + "x" + Math.round(w.height)
                                + " flags=" + w.flags + " name='" + w.objectName + "'") : "null");
    }

    readonly property int loc: {
        try { return plasmoid.location; } catch (e) { return PlasmaCore.Types.BottomEdge; }
    }
    readonly property bool showTop: resizeHeight && (
        loc === PlasmaCore.Types.BottomEdge
        || loc === PlasmaCore.Types.Floating
        || loc === PlasmaCore.Types.Desktop)
    readonly property bool showBottom: resizeHeight && (
        loc === PlasmaCore.Types.TopEdge
        || loc === PlasmaCore.Types.Floating
        || loc === PlasmaCore.Types.Desktop)
    readonly property bool showLeft: loc === PlasmaCore.Types.RightEdge
        || loc === PlasmaCore.Types.Floating
        || loc === PlasmaCore.Types.Desktop
    readonly property bool showRight: loc === PlasmaCore.Types.LeftEdge
        || loc === PlasmaCore.Types.Floating
        || loc === PlasmaCore.Types.Desktop
        || loc === PlasmaCore.Types.BottomEdge
        || loc === PlasmaCore.Types.TopEdge

    function clampW(w) {
        return Math.max(root.minWidth, Math.min(root.effectiveMaxWidth, Math.round(w)));
    }
    function clampH(h) {
        return Math.max(root.minHeight, Math.min(root.effectiveMaxHeight, Math.round(h)));
    }

    /** Persist the dragged size once, then leave live-drag mode. */
    function commitDrag() {
        if (root.menuData) {
            if (root.liveWidth > 0 && root.menuData.setMenuWidth)
                root.menuData.setMenuWidth(root.liveWidth);
            if (root.liveHeight > 0 && root.menuData.setMenuHeight)
                root.menuData.setMenuHeight(root.liveHeight);
        }
        // Desktop inline host: freeze the bottom edge at its current spot,
        // then re-register with the grid layout once the y glide settles
        // (snaps to the cell grid and schedules an ItemGeometries save).
        if (root.dragContainer) {
            // The write below is intercepted by the glide (reads back the
            // mid-animation value), so pin targetY to the INTENDED spot.
            root.targetY = root.pressBottom - root.dragContainer.height;
            root.writingGeom = true;
            root.dragContainer.y = root.targetY;
            root.writingGeom = false;
            // No compensate() after this write (same post-write-readback trap
            // as syncContainerSize); the glide + snap ticks keep the visual
            // nailed to targetY until commitTimer drops the compensation.
            commitTimer.restart();
        }
        console.log("ArcMenu resize commit:", root.liveWidth, "x", root.liveHeight,
                    "rep", Math.round(root.width), "x", Math.round(root.height));
        root.liveWidth = -1;
        root.liveHeight = -1;
        // dragContainer is cleared by commitTimer's 2nd pass (desktop host,
        // after glide + grid snap settle) — keep it alive until then so the
        // bottom-edge pin and compensation stay effective.
    }

    /**
     * Resize the popup window directly to the live drag size.
     * Runs after the liveWidth/liveHeight writes, so AppletPopup has already
     * applied the Layout min/max pin (window constraints match the target);
     * this final resize() overrides any stale grow request issued by
     * AppletPopup::updateMinSize() on Wayland — the case where shrinking
     * used to bounce straight back.
     */
    function syncWindowSize(role) {
        // Desktop inline host: resize the AppletContainer, not the window
        // (the "window" here is the whole desktop and must not be touched).
        if (root.dragContainer) {
            root.syncContainerSize(role);
            return;
        }
        var win = root.Window.window;
        if (!win)
            return;
        // Never touch desktop-filling shells (Raven on small screens etc.)
        if (win.width >= Screen.width - 8 && win.height >= Screen.height - 8)
            return;
        // Window = content + theme chrome (padding/arrows); keep the delta.
        var chromeW = win.width - root.width;
        var chromeH = win.height - root.height;
        var w = (root.liveWidth > 0 ? root.liveWidth + root.sideWidth : root.width) + chromeW;
        var h = (root.liveHeight > 0 ? root.liveHeight : root.height) + chromeH;
        win.resize(Math.round(w), Math.round(h));
    }

    component EdgeHandle: MouseArea {
        id: edge
        property string edgeRole: "e"
        property real pressGlobalX: 0
        property real pressGlobalY: 0
        property int pressW: 0
        property int pressH: 0
        property real lastLogTime: 0

        z: 50
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.LeftButton
        cursorShape: {
            switch (edgeRole) {
            case "e":
            case "w": return Qt.SizeHorCursor;
            case "n":
            case "s": return Qt.SizeVerCursor;
            case "ne":
            case "sw": return Qt.SizeBDiagCursor;
            default: return Qt.SizeFDiagCursor;
            }
        }

        onPressed: (mouse) => {
            root.logEnvOnce();
            root.dragContainer = root.appletContainer();
            if (root.dragContainer) {
                // A pending settle from the previous drag must not clear
                // the container we are about to drive.
                commitTimer.stop();
                root.commitSnapped = false;
                root.pressBottom = root.dragContainer.y + root.dragContainer.height;
            }
            var g = mapToGlobal(mouse.x, mouse.y);
            pressGlobalX = g.x;
            pressGlobalY = g.y;
            // Seed from what is actually on screen, not from the config —
            // the two can disagree (e.g. stale remembered popup size), which
            // used to make the first drag appear to do nothing.
            pressW = root.clampW(root.width - root.sideWidth);
            pressH = root.clampH(root.height);
            var win = root.Window.window;
            console.log("ArcMenu resize press:", edgeRole, "seed", pressW, "x", pressH,
                        "rep", Math.round(root.width), "x", Math.round(root.height),
                        "maxH", root.effectiveMaxHeight,
                        "win", win ? Math.round(win.width) + "x" + Math.round(win.height) : "null");
        }
        onPositionChanged: (mouse) => {
            if (!pressed)
                return;
            var g = mapToGlobal(mouse.x, mouse.y);
            var dx = g.x - pressGlobalX;
            var dy = g.y - pressGlobalY;
            var role = edge.edgeRole;
            if (role === "e" || role === "ne" || role === "se")
                root.liveWidth = root.clampW(pressW + dx);
            else if (role === "w" || role === "nw" || role === "sw")
                root.liveWidth = root.clampW(pressW - dx);
            if (role === "s" || role === "se" || role === "sw")
                root.liveHeight = root.clampH(pressH + dy);
            else if (role === "n" || role === "ne" || role === "nw")
                root.liveHeight = root.clampH(pressH - dy);
            root.syncWindowSize(role);
            var now = Date.now();
            if (now - edge.lastLogTime > 400) {
                edge.lastLogTime = now;
                var lw = root.Window.window;
                console.log("ArcMenu resize drag:", role,
                            "live", root.liveWidth, "x", root.liveHeight,
                            "rep", Math.round(root.width), "x", Math.round(root.height),
                            "win", lw ? Math.round(lw.width) + "x" + Math.round(lw.height) : "null");
            }
        }
        onReleased: root.commitDrag()
        onCanceled: root.commitDrag()
    }

    EdgeHandle {
        visible: root.showTop
        edgeRole: "n"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.handleThickness
        anchors.leftMargin: root.handleThickness
        anchors.rightMargin: root.handleThickness
    }
    EdgeHandle {
        visible: root.showBottom
        edgeRole: "s"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.handleThickness
        anchors.leftMargin: root.handleThickness
        anchors.rightMargin: root.handleThickness
    }
    EdgeHandle {
        visible: root.showLeft
        edgeRole: "w"
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: root.handleThickness
        anchors.topMargin: root.handleThickness
        anchors.bottomMargin: root.handleThickness
    }
    EdgeHandle {
        visible: root.showRight
        edgeRole: "e"
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.handleThickness
        anchors.topMargin: root.handleThickness
        anchors.bottomMargin: root.handleThickness
    }
    EdgeHandle {
        visible: root.showTop && root.showRight
        edgeRole: "ne"
        anchors.top: parent.top
        anchors.right: parent.right
        width: root.handleThickness * 2
        height: root.handleThickness * 2
    }
    EdgeHandle {
        visible: root.showTop && root.showLeft
        edgeRole: "nw"
        anchors.top: parent.top
        anchors.left: parent.left
        width: root.handleThickness * 2
        height: root.handleThickness * 2
    }
    EdgeHandle {
        visible: root.showBottom && root.showRight
        edgeRole: "se"
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.handleThickness * 2
        height: root.handleThickness * 2
    }
    EdgeHandle {
        visible: root.showBottom && root.showLeft
        edgeRole: "sw"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: root.handleThickness * 2
        height: root.handleThickness * 2
    }
}
