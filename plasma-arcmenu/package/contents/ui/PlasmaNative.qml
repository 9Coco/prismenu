import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker
import org.kde.plasma.private.sessions as Sessions

/**
 * Thin wrappers around Kickoff-shared Plasma APIs:
 *  - SessionManagement (lock / logout / reboot / power)
 *  - RootModel.favoritesModel (global favorites)
 *  - RunnerModel (Plasma Search / KRunner)
 *  - RecentUsageModel (recent applications)
 *
 * Places use KFilePlacesModel when the KIO QML module is available (loaded dynamically).
 */
Item {
    id: root

    property var menuData: null
    property var rootModel: null
    property var appletInterface: null

    property var runnerResults: []
    property var recentApps: []
    property var placesEntries: []
    property var plasmaFavoriteIds: []
    readonly property var favoritesSourceModel: {
        try { return root.rootModel ? root.rootModel.favoritesModel : null; }
        catch (e) { return null; }
    }

    signal runnerResultsUpdated(var results)
    signal recentAppsUpdated(var apps)
    signal placesUpdated(var places)
    signal plasmaFavoritesUpdated(var ids)

    // ---- Session (Kickoff Leave) ----
    Sessions.SessionManagement {
        id: session
    }

    readonly property var sessionManagement: session

    /**
     * confirmationMode: "default" | "force" | "skip"
     * Maps to SessionManagement.ConfirmationMode when available.
     */
    function runSessionAction(actionId, confirmationMode) {
        function callRequest(fnName) {
            try {
                var mode = null;
                if (session.ConfirmationMode !== undefined) {
                    if (confirmationMode === "force")
                        mode = session.ConfirmationMode.ForcePrompt;
                    else if (confirmationMode === "skip")
                        mode = session.ConfirmationMode.SkipPrompt;
                    else
                        mode = session.ConfirmationMode.Default;
                }
                if (mode !== null)
                    session[fnName](mode);
                else
                    session[fnName]();
                return true;
            } catch (e1) {
                try { session[fnName](); return true; } catch (e2) { return false; }
            }
        }

        try {
            switch (String(actionId || "")) {
            case "lock":
                session.lock();
                return true;
            case "logout":
                return callRequest("requestLogout");
            case "shutdown":
                if (session.canShutdown === false)
                    console.warn("ArcMenu: SessionManagement.canShutdown is false");
                return callRequest("requestShutdown");
            case "restart":
            case "reboot":
                return callRequest("requestReboot");
            case "suspend":
                session.suspend();
                return true;
            case "hibernate":
                session.hibernate();
                return true;
            case "hybridsleep":
                if (session.hybridSuspend)
                    session.hybridSuspend();
                else
                    session.suspend();
                return true;
            case "switchuser":
                session.switchUser();
                return true;
            default:
                return false;
            }
        } catch (err) {
            console.warn("ArcMenu SessionManagement failed:", actionId, err);
            return false;
        }
    }

    // ---- Plasma Search (KRunner via Kicker.RunnerModel) ----
    // Kickoff path: mergeResults=true creates one ResultsModel of every
    // enabled runner (apps, locations, windows, bookmarks, files, …).
    // mergeResults=false with an empty runners list creates *zero* models,
    // which is why Locations/Bookmarks never appeared.
    Kicker.RunnerModel {
        id: runnerModel
        appletInterface: root.appletInterface
        query: (menuData && menuData.searchQuery) ? String(menuData.searchQuery) : ""
        mergeResults: true
        onCountChanged: root.bindMatchesModel()
        onDataChanged: root.scheduleRunnerRebuild()
        onModelReset: root.bindMatchesModel()
        Component.onCompleted: {
            try {
                if (root.rootModel && root.rootModel.favoritesModel)
                    runnerModel.favoritesModel = root.rootModel.favoritesModel;
            } catch (e) {}
            Qt.callLater(root.bindMatchesModel);
        }
    }

    Connections {
        target: runnerModel
        ignoreUnknownSignals: true
        function onQueryFinished() { root.scheduleRunnerRebuild(); }
        function onAnyRunnerFinished() { root.scheduleRunnerRebuild(); }
        function onQueryingChanged() {
            if (runnerModel && !runnerModel.querying)
                root.scheduleRunnerRebuild();
        }
        function onQueryChanged() { root.bindMatchesModel(); }
    }

    Timer {
        id: runnerRebuildTimer
        interval: 40
        repeat: false
        onTriggered: root.rebuildRunnerResults()
    }

    function scheduleRunnerRebuild() {
        runnerRebuildTimer.restart();
    }

    function bindMatchesModel() {
        var m = null;
        try {
            if (runnerModel.count > 0)
                m = runnerModel.modelForRow(0);
        } catch (e) {}
        if (matchesInst.model !== m)
            matchesInst.model = m;
        root.scheduleRunnerRebuild();
    }

    Instantiator {
        id: matchesInst
        model: null
        asynchronous: false
        delegate: Item {
            width: 0; height: 0; visible: false
            readonly property int row: index
            readonly property int runnerRow: 0
            readonly property string display: String(model.display !== undefined ? model.display : "")
            readonly property string description: String(model.description !== undefined ? model.description : "")
            readonly property var decoration: model.decoration
            readonly property var iconName: model.iconName !== undefined ? model.iconName
                : (model.icon !== undefined ? model.icon : "")
            readonly property var url: model.url
            readonly property string favoriteId: String(model.favoriteId !== undefined ? model.favoriteId : "")
            readonly property string category: String(
                model.category !== undefined ? model.category
                    : (model.group !== undefined ? model.group
                        : (model.section !== undefined ? model.section : "")))
            readonly property string group: category
            readonly property bool isSeparator: !!(model.isSeparator || model.IsSeparator
                || model.isSection || model.IsSection)
        }
        onObjectAdded: root.scheduleRunnerRebuild()
        onObjectRemoved: root.scheduleRunnerRebuild()
        onCountChanged: root.scheduleRunnerRebuild()
    }

    Connections {
        target: matchesInst.model
        ignoreUnknownSignals: true
        function onCountChanged() { root.scheduleRunnerRebuild(); }
        function onDataChanged() { root.scheduleRunnerRebuild(); }
        function onModelReset() { root.scheduleRunnerRebuild(); }
        function onRowsInserted() { root.scheduleRunnerRebuild(); }
        function onRowsRemoved() { root.scheduleRunnerRebuild(); }
    }

    function _runnerIcon(obj) {
        try {
            var named = obj.iconName;
            if (typeof named === "string" && named.length)
                return named;
            if (typeof obj.decoration === "string" && obj.decoration.length)
                return obj.decoration;
            if (obj.decoration && obj.decoration.name)
                return String(obj.decoration.name);
        } catch (e) {}
        return "";
    }

    function _fallbackRunnerIcon(group, uri) {
        var g = String(group || "").toLowerCase();
        var u = String(uri || "").toLowerCase();
        if (g.indexOf("bookmark") >= 0 || g.indexOf("书签") >= 0 || /^https?:/.test(u))
            return "bookmarks";
        if (g.indexOf("location") >= 0 || g.indexOf("place") >= 0 || g.indexOf("位置") >= 0
            || /^(sftp|ftp|smb|nfs|fish|webdav|davs?|remote|mtp|kdeconnect):/.test(u))
            return "folder-remote";
        if (g.indexOf("window") >= 0 || g.indexOf("窗口") >= 0)
            return "window";
        if (u.indexOf("file:") === 0)
            return "unknown";
        return "application-x-executable";
    }

    function rebuildRunnerResults() {
        var out = [];
        var q = "";
        try { q = String(runnerModel.query || "").trim(); } catch (e0) {}
        if (!q) {
            root.runnerResults = [];
            runnerResultsUpdated([]);
            if (menuData)
                menuData.runnerResults = [];
            return;
        }
        var currentGroup = "";
        var n = matchesInst.count;
        for (var i = 0; i < n && out.length < 200; ++i) {
            var obj = matchesInst.objectAt(i);
            if (!obj)
                continue;
            if (obj.isSeparator) {
                var sepName = String(obj.display || "").trim();
                if (sepName)
                    currentGroup = sepName;
                continue;
            }
            var name = String(obj.display || "").trim();
            if (!name)
                continue;
            var itemGroup = String(obj.category || obj.group || "").trim();
            if (!itemGroup)
                itemGroup = currentGroup;
            if (itemGroup)
                currentGroup = itemGroup;
            var uri = obj.url !== undefined && obj.url !== null ? String(obj.url) : "";
            var icon = _runnerIcon(obj) || _fallbackRunnerIcon(itemGroup, uri);
            out.push({
                id: "runner:0:" + obj.row + ":" + (obj.favoriteId || name),
                name: name,
                icon: icon,
                decoration: obj.decoration,
                iconHolder: obj,
                genericName: obj.description || "",
                description: obj.description || "",
                favoriteId: obj.favoriteId || "",
                kickerUrl: uri,
                entryPath: uri,
                provider: "runner",
                group: itemGroup,
                runnerRow: 0,
                runnerIndex: obj.row,
                noDisplay: false
            });
        }
        root.runnerResults = out;
        runnerResultsUpdated(out);
        if (menuData)
            menuData.runnerResults = out;
    }

    function triggerRunnerAt(runnerRow, matchIndex) {
        if (matchIndex === undefined || matchIndex === null) {
            matchIndex = runnerRow;
            runnerRow = 0;
        }
        if (matchIndex === undefined || matchIndex === null || matchIndex < 0)
            return false;
        if (runnerRow === undefined || runnerRow === null || runnerRow < 0)
            runnerRow = 0;
        try {
            var m = runnerModel.modelForRow(runnerRow);
            if (m && m.trigger)
                return !!m.trigger(matchIndex, "", null);
        } catch (e) {
            console.warn("ArcMenu runner trigger failed", e);
        }
        return false;
    }

    // ---- Recent applications (KAStats / Kickoff) ----
    Kicker.RecentUsageModel {
        id: recentAppsModel
        Component.onCompleted: {
            function trySet(key, value) {
                try { recentAppsModel[key] = value; } catch (e) {}
            }
            // OnlyApps — see RecentUsageModel::IncludeUsage
            trySet("shownItems", 1);
            trySet("includeUsage", 1);
            trySet("include", 1);
            Qt.callLater(root.rebuildRecentApps);
        }
        onCountChanged: root.rebuildRecentApps()
        onDataChanged: root.rebuildRecentApps()
        onModelReset: root.rebuildRecentApps()
    }

    Instantiator {
        id: recentAppsInst
        model: recentAppsModel
        asynchronous: false
        delegate: Item {
            width: 0; height: 0; visible: false
            readonly property string display: String(model.display !== undefined ? model.display : "")
            readonly property string description: String(model.description !== undefined ? model.description : "")
            readonly property var url: model.url
            readonly property var decoration: model.decoration
            readonly property string favoriteId: String(model.favoriteId !== undefined ? model.favoriteId : "")
        }
        onObjectAdded: root.rebuildRecentApps()
        onObjectRemoved: root.rebuildRecentApps()
    }

    function rebuildRecentApps() {
        var out = [];
        var n = recentAppsInst.count;
        for (var i = 0; i < n && out.length < 30; ++i) {
            var obj = recentAppsInst.objectAt(i);
            if (!obj)
                continue;
            var name = String(obj.display || "").trim();
            var uri = obj.url !== undefined && obj.url !== null ? String(obj.url) : "";
            if (!name && !uri)
                continue;
            var id = obj.favoriteId || "";
            if (!id && uri.indexOf("applications:") === 0)
                id = uri.substring("applications:".length);
            if (!id && uri.endsWith(".desktop")) {
                var slash = uri.lastIndexOf("/");
                id = slash >= 0 ? uri.substring(slash + 1) : uri;
            }
            if (!id)
                id = "recent-app:" + name;
            var icon = "application-x-executable";
            try {
                if (typeof obj.decoration === "string" && obj.decoration.length)
                    icon = obj.decoration;
                else if (obj.decoration && obj.decoration.name)
                    icon = String(obj.decoration.name);
            } catch (e) {}
            out.push({
                id: id,
                name: name || id,
                icon: icon,
                genericName: obj.description || "",
                favoriteId: obj.favoriteId || id,
                kickerUrl: uri,
                entryPath: uri,
                provider: "recent-apps",
                noDisplay: false
            });
        }
        root.recentApps = out;
        recentAppsUpdated(out);
        if (menuData)
            menuData.plasmaRecentApps = out;
    }

    // ---- Global favorites (KAStatsFavoritesModel via RootModel) ----
    function favoritesModel() {
        return root.favoritesSourceModel;
    }

    function refreshPlasmaFavorites() {
        var fm = favoritesModel();
        var ids = [];
        if (!fm) {
            root.plasmaFavoriteIds = ids;
            plasmaFavoritesUpdated(ids);
            return;
        }
        try {
            var n = fm.count;
            for (var i = 0; i < n; ++i) {
                var fid = "";
                try {
                    // role favoriteId / Url commonly available
                    var idx = fm.index(i, 0);
                    fid = String(fm.data(idx, fm.favoriteIdRole !== undefined ? fm.favoriteIdRole : Qt.UserRole + 3) || "");
                } catch (e1) {}
                if (!fid) {
                    try { fid = String(fm.favoriteIdAt ? fm.favoriteIdAt(i) : ""); } catch (e2) {}
                }
                if (fid)
                    ids.push(fid);
            }
        } catch (e) {
            // Instantiator fallback below may still work
        }
        // Prefer Instantiator materialization when roles are awkward
        if (!ids.length && favInst.count > 0) {
            for (var j = 0; j < favInst.count; ++j) {
                var o = favInst.objectAt(j);
                if (o && o.favoriteId)
                    ids.push(o.favoriteId);
            }
        }
        root.plasmaFavoriteIds = ids;
        plasmaFavoritesUpdated(ids);
        if (menuData)
            menuData.plasmaFavoriteIds = ids;
    }

    Instantiator {
        id: favInst
        model: root.favoritesSourceModel
        asynchronous: false
        delegate: Item {
            width: 0; height: 0; visible: false
            readonly property string favoriteId: String(model.favoriteId !== undefined ? model.favoriteId : (model.url || ""))
            readonly property string display: String(model.display !== undefined ? model.display : "")
        }
        onObjectAdded: root.refreshPlasmaFavorites()
        onObjectRemoved: root.refreshPlasmaFavorites()
        onModelChanged: root.refreshPlasmaFavorites()
    }

    Connections {
        target: root.favoritesSourceModel
        ignoreUnknownSignals: true
        function onCountChanged() { root.refreshPlasmaFavorites(); }
        function onDataChanged() { root.refreshPlasmaFavorites(); }
        function onModelReset() { root.refreshPlasmaFavorites(); }
        function onRowsInserted() { root.refreshPlasmaFavorites(); }
        function onRowsRemoved() { root.refreshPlasmaFavorites(); }
        function onRowsMoved() { root.refreshPlasmaFavorites(); }
    }

    function isPlasmaFavorite(favoriteId) {
        var fm = favoritesModel();
        if (!fm || !favoriteId)
            return false;
        try { return !!fm.isFavorite(String(favoriteId)); } catch (e) { return false; }
    }

    function togglePlasmaFavorite(favoriteId) {
        var fm = favoritesModel();
        if (!fm || !favoriteId)
            return false;
        try {
            var id = String(favoriteId);
            if (fm.isFavorite(id))
                fm.removeFavorite(id);
            else
                fm.addFavorite(id);
            Qt.callLater(root.refreshPlasmaFavorites);
            return true;
        } catch (e) {
            console.warn("ArcMenu favorites toggle failed", e);
            return false;
        }
    }

    function setPlasmaFavorite(favoriteId, favorite) {
        var fm = favoritesModel();
        if (!fm || !favoriteId)
            return false;
        try {
            var id = String(favoriteId);
            var current = !!fm.isFavorite(id);
            if (favorite && !current)
                fm.addFavorite(id);
            else if (!favorite && current)
                fm.removeFavorite(id);
            Qt.callLater(root.refreshPlasmaFavorites);
            return true;
        } catch (e) {
            console.warn("ArcMenu setPlasmaFavorite failed:", favoriteId, e);
            return false;
        }
    }

    function movePlasmaFavorite(from, to) {
        var fm = favoritesModel();
        if (!fm || from < 0 || to < 0 || from === to)
            return false;
        try {
            fm.moveRow(from, to);
            Qt.callLater(root.refreshPlasmaFavorites);
            return true;
        } catch (e) {
            console.warn("ArcMenu movePlasmaFavorite failed:", from, to, e);
            return false;
        }
    }

    // ---- Places (KFilePlacesModel when KIO QML is present) ----
    property var filePlacesModel: null

    Timer {
        interval: 0
        running: true
        repeat: false
        onTriggered: root._initPlaces()
    }

    property bool _placesTried: false

    function _initPlaces() {
        if (root._placesTried)
            return;
        root._placesTried = true;
        // Many Plasma installs lack org.kde.kio QML; fall back to XDG places quietly.
        var candidates = [
            'import org.kde.kio as KIO; KIO.KFilePlacesModel {}',
            'import org.kde.plasma.private.fileplacesmodel as FP; FP.FilePlacesModel {}'
        ];
        for (var i = 0; i < candidates.length; ++i) {
            try {
                var obj = Qt.createQmlObject(candidates[i], root, "ArcMenuKFilePlaces");
                root.filePlacesModel = obj;
                placesInst.model = obj;
                Qt.callLater(root.rebuildPlaces);
                return;
            } catch (e) {}
        }
        root.filePlacesModel = null;
    }

    Instantiator {
        id: placesInst
        model: null
        asynchronous: false
        delegate: Item {
            width: 0; height: 0; visible: false
            readonly property string display: String(model.display !== undefined ? model.display : "")
            readonly property string description: String(model.description !== undefined ? model.description : "")
            readonly property var decoration: model.decoration
            readonly property var url: model.url !== undefined ? model.url : model.Url
            readonly property bool isHidden: !!(model.hidden || model.Hidden)
            readonly property bool isDevice: !!(model.isDevice || model.IsDevice)
        }
        onObjectAdded: root.rebuildPlaces()
        onObjectRemoved: root.rebuildPlaces()
    }

    function rebuildPlaces() {
        var out = [];
        if (!root.filePlacesModel) {
            root.placesEntries = out;
            placesUpdated(out);
            return;
        }
        var n = placesInst.count;
        for (var i = 0; i < n && out.length < 40; ++i) {
            var obj = placesInst.objectAt(i);
            if (!obj || obj.isHidden)
                continue;
            var name = String(obj.display || "").trim();
            var uri = obj.url !== undefined && obj.url !== null ? String(obj.url) : "";
            if (!name || !uri)
                continue;
            // Skip root / trash noise optionally — keep standard user places
            var icon = "folder";
            try {
                if (typeof obj.decoration === "string" && obj.decoration.length)
                    icon = obj.decoration;
                else if (obj.decoration && obj.decoration.name)
                    icon = String(obj.decoration.name);
            } catch (e) {}
            var localPath = uri.indexOf("file://") === 0 ? decodeURIComponent(uri.substring(7)) : "";
            var detail = String(obj.description || "").trim();
            if (!detail)
                detail = localPath || (menuData ? menuData.tr("Remote Location") : "Remote Location");
            out.push({
                id: "kplace:" + uri,
                name: name,
                icon: icon,
                decoration: obj.decoration,
                iconHolder: obj,
                kickerUrl: uri,
                entryPath: uri,
                exec: "",
                place: "",
                path: localPath,
                isDevice: !!obj.isDevice,
                categories: ["Places"],
                keywords: [],
                genericName: detail,
                description: detail,
                provider: "kfileplaces",
                noDisplay: false
            });
        }
        root.placesEntries = out;
        placesUpdated(out);
        if (menuData)
            menuData.plasmaPlaces = out;
    }

    function openPlaceUrl(url) {
        if (!url)
            return false;
        try {
            // KFilePlacesModel / KIO open via kioclient is still valid; prefer Qt.openUrlExternally for file:
            var u = String(url);
            Qt.openUrlExternally(u);
            return true;
        } catch (e) {
            return false;
        }
    }

    function triggerRootApp(catRow, appRow) {
        if (!root.rootModel || catRow === undefined || appRow === undefined)
            return false;
        try {
            var m = root.rootModel.modelForRow(catRow);
            if (!m)
                return false;
            return !!m.trigger(appRow, "", null);
        } catch (e) {
            console.warn("ArcMenu kicker trigger failed", e);
            return false;
        }
    }

    Connections {
        target: root
        function onRootModelChanged() {
            try {
                if (root.rootModel && root.rootModel.favoritesModel)
                    runnerModel.favoritesModel = root.rootModel.favoritesModel;
            } catch (e) {}
            favInst.model = root.favoritesModel();
            Qt.callLater(root.refreshPlasmaFavorites);
        }
    }
}
