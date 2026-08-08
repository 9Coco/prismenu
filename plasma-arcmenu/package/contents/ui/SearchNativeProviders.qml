import QtQuick
import org.kde.plasma.private.kicker as Kicker
import org.kde.taskmanager as TaskManager

/**
 * Native Plasma providers for ArcMenu search extras:
 *  - Recent files → Kicker.RecentUsageModel (KAStats / same as Kickoff)
 *  - Open windows → TaskManager.TasksModel (all virtual desktops)
 *
 * No Python / wmctrl.
 */
Item {
    id: root

    property var recentFiles: []
    property var openWindows: []

    signal recentFilesUpdated(var files)
    signal openWindowsUpdated(var windows)

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
            Qt.callLater(root.rebuildRecentFiles);
        }
        onCountChanged: root.rebuildRecentFiles()
        onDataChanged: root.rebuildRecentFiles()
        onModelReset: root.rebuildRecentFiles()
    }

    Instantiator {
        id: recentDocsInst
        model: recentDocsModel
        asynchronous: false
        delegate: Item {
            width: 0; height: 0; visible: false
            readonly property string display: String(model.display !== undefined ? model.display : "")
            readonly property string description: String(model.description !== undefined ? model.description : "")
            readonly property var url: model.url
            readonly property var decoration: model.decoration
        }
        onObjectAdded: root.rebuildRecentFiles()
        onObjectRemoved: root.rebuildRecentFiles()
    }

    function rebuildRecentFiles() {
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
        onCountChanged: root.rebuildOpenWindows()
        onDataChanged: root.rebuildOpenWindows()
        onModelReset: root.rebuildOpenWindows()
        Component.onCompleted: Qt.callLater(root.rebuildOpenWindows)
    }

    Instantiator {
        id: tasksInst
        model: tasksModel
        asynchronous: false
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
        onObjectAdded: root.rebuildOpenWindows()
        onObjectRemoved: root.rebuildOpenWindows()
    }

    function rebuildOpenWindows() {
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
            console.warn("ArcMenu activateWindow failed", e);
            return false;
        }
    }

    function refresh() {
        rebuildRecentFiles();
        rebuildOpenWindows();
    }
}
