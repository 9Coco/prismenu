import QtQuick
import org.kde.plasma.private.kicker as Kicker
import org.kde.taskmanager as TaskManager

/**
 * Native Plasma providers for Prismenu search extras:
 *  - Recent files → Kicker.RecentUsageModel (KAStats / same as Kickoff)
 *  - Open windows → TaskManager.TasksModel (all virtual desktops)
 *
 * No Python / wmctrl.
 *
 * Two properties of this implementation worth knowing:
 *
 * 1. Delegates are incubated asynchronously, so their model role bindings
 *    are never evaluated inside the model's itemsInserted handler. A
 *    synchronous evaluation there re-enters TasksModel::data() through the
 *    grouping/concat proxy chain while the model is mid-update, which
 *    segfaulted plasmashell when windows were created/destroyed rapidly.
 *
 * 2. Each provider is enabled only after an explicit search/navigation
 *    request during this opening. Model notifications never enable one.
 *    The native C++ models keep mirroring state while delegates are inactive.
 */
Item {
    id: root

    property var recentFiles: []
    property var openWindows: []

    /** Bind to the menu's expanded state; opening alone starts no provider. */
    property bool liveUpdates: true
    property bool recentFilesRequested: false
    property bool openWindowsRequested: false
    readonly property bool recentFilesActive: liveUpdates && recentFilesRequested
    readonly property bool openWindowsActive: liveUpdates && openWindowsRequested

    signal recentFilesUpdated(var files)
    signal openWindowsUpdated(var windows)

    onLiveUpdatesChanged: {
        if (!liveUpdates) {
            recentFilesRequested = false;
            openWindowsRequested = false;
        }
    }

    // ---- Recent documents (Kicker / KAStats) ----
    Kicker.RecentUsageModel {
        id: recentDocsModel
        Component.onCompleted: {
            // Plasma versions differ on the enum property name
            function trySet(key, value) {
                try { recentDocsModel[key] = value; } catch (e) {}
            }
            // OnlyDocs — see RecentUsageModel::IncludeUsage
            trySet("shownItems", 2);
            trySet("includeUsage", 2);
            trySet("include", 2);
            root.queueRecentFilesRebuild();
        }
        onCountChanged: root.queueRecentFilesRebuild()
        onDataChanged: root.queueRecentFilesRebuild()
        onModelReset: root.queueRecentFilesRebuild()
    }

    Instantiator {
        id: recentDocsInst
        model: recentDocsModel
        active: root.recentFilesActive
        asynchronous: true
        delegate: Item {
            width: 0; height: 0; visible: false
            readonly property string display: String(model.display !== undefined ? model.display : "")
            readonly property string description: String(model.description !== undefined ? model.description : "")
            readonly property var url: model.url
            readonly property var decoration: model.decoration
        }
        onObjectAdded: root.queueRecentFilesRebuild()
        onObjectRemoved: root.queueRecentFilesRebuild()
    }

    /** Gated + coalesced rebuild request (see liveUpdates). */
    function requestRecentFiles() {
        if (!liveUpdates)
            return;
        recentFilesRequested = true;
        queueRecentFilesRebuild();
    }

    function queueRecentFilesRebuild() {
        if (!recentFilesActive)
            return;
        // count/object/data signals arrive in bursts — dedupe via callLater
        Qt.callLater(rebuildRecentFiles);
    }

    function rebuildRecentFiles() {
        // A queued request may run after the popup was closed.
        if (!recentFilesActive)
            return;
        var files = [];
        var n = recentDocsInst.count;
        for (var i = 0; i < n && files.length < 40; ++i) {
            var obj = recentDocsInst.objectAt(i);
            if (!obj)
                continue;
            var name = String(obj.display || "").trim();
            var url = obj.url;
            var uri = "";
            if (url !== undefined && url !== null)
                uri = String(url);
            if (!name && !uri)
                continue;
            if (!name)
                name = uri.split("/").pop() || uri;
            var path = uri.indexOf("file://") === 0 ? decodeURIComponent(uri.substring(7)) : uri;
            var icon = "document-open-recent";
            try {
                if (obj.decoration !== undefined && obj.decoration !== null) {
                    if (typeof obj.decoration === "string" && obj.decoration.length)
                        icon = obj.decoration;
                    else if (obj.decoration.name)
                        icon = String(obj.decoration.name);
                }
            } catch (e) {}
            files.push({
                id: "recent-file:" + (uri || name),
                name: name,
                icon: icon,
                decoration: obj.decoration,
                iconHolder: obj,
                kickerUrl: uri,
                entryPath: uri,
                genericName: obj.description || path,
                description: obj.description || path,
                provider: "recent-files",
                noDisplay: false
            });
        }
        root.recentFiles = files;
        recentFilesUpdated(files);
    }

    // ---- Open windows (Task Manager — all workspaces) ----
    TaskManager.TasksModel {
        id: tasksModel
        groupMode: TaskManager.TasksModel.GroupDisabled
        filterByScreen: false
        filterByActivity: false
        filterByVirtualDesktop: false
        sortMode: TaskManager.TasksModel.SortAlpha
        onCountChanged: root.queueOpenWindowsRebuild()
        onDataChanged: root.queueOpenWindowsRebuild()
        onModelReset: root.queueOpenWindowsRebuild()
        Component.onCompleted: root.queueOpenWindowsRebuild()
    }

    Instantiator {
        id: tasksInst
        model: tasksModel
        active: root.openWindowsActive
        asynchronous: true
        delegate: Item {
            width: 0; height: 0; visible: false
            readonly property int row: index
            readonly property string display: String(model.display !== undefined ? model.display : "")
            readonly property string appId: String(model.AppId !== undefined ? model.AppId : "")
            readonly property bool isWindow: !!(model.IsWindow)
            readonly property bool isLauncher: !!(model.IsLauncher)
            readonly property bool isStartup: !!(model.IsStartup)
            readonly property var decoration: model.decoration
        }
        onObjectAdded: root.queueOpenWindowsRebuild()
        onObjectRemoved: root.queueOpenWindowsRebuild()
    }

    /** Gated + coalesced rebuild request (see liveUpdates). */
    function requestOpenWindows() {
        if (!liveUpdates)
            return;
        openWindowsRequested = true;
        queueOpenWindowsRebuild();
    }

    function queueOpenWindowsRebuild() {
        if (!openWindowsActive)
            return;
        Qt.callLater(rebuildOpenWindows);
    }

    function rebuildOpenWindows() {
        if (!openWindowsActive)
            return;
        var wins = [];
        var n = tasksInst.count;
        for (var i = 0; i < n && wins.length < 40; ++i) {
            var obj = tasksInst.objectAt(i);
            if (!obj || obj.isLauncher || obj.isStartup)
                continue;
            // Prefer real windows; if role missing, still include titled tasks
            if (obj.isWindow === false)
                continue;
            var title = String(obj.display || "").trim();
            if (!title)
                continue;
            var icon = "window";
            try {
                if (obj.decoration !== undefined && obj.decoration !== null) {
                    if (typeof obj.decoration === "string" && obj.decoration.length)
                        icon = obj.decoration;
                    else if (obj.decoration.name)
                        icon = String(obj.decoration.name);
                }
            } catch (e) {}
            wins.push({
                id: "window:" + obj.row + ":" + (obj.appId || title),
                name: title,
                icon: icon,
                decoration: obj.decoration,
                iconHolder: obj,
                genericName: obj.appId || "",
                description: obj.appId || title,
                provider: "windows",
                taskIndex: obj.row,
                noDisplay: false
            });
        }
        root.openWindows = wins;
        openWindowsUpdated(wins);
    }

    function activateWindowAt(taskIndex) {
        if (taskIndex === undefined || taskIndex === null || taskIndex < 0)
            return false;
        try {
            var mi = tasksModel.makeModelIndex(taskIndex);
            tasksModel.requestActivate(mi);
            return true;
        } catch (e) {
            console.warn("Prismenu activateWindow failed", e);
            return false;
        }
    }

    function refresh() {
        requestRecentFiles();
        requestOpenWindows();
    }
}
