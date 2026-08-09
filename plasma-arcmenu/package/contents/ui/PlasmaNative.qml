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

    property var runnerResults: []
    property var recentApps: []
    property var placesEntries: []
    property var plasmaFavoriteIds: []

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
    Kicker.RunnerModel {
        id: runnerModel
        appletInterface: plasmoid
        query: (menuData && menuData.searchQuery) ? String(menuData.searchQuery) : ""
        onCountChanged: root.rebuildRunnerResults()
        onDataChanged: root.rebuildRunnerResults()
        onModelReset: root.rebuildRunnerResults()
        Component.onCompleted: {
            try {
                if (root.rootModel && root.rootModel.favoritesModel)
                    runnerModel.favoritesModel = root.rootModel.favoritesModel;
            } catch (e) {}
            Qt.callLater(root.rebuildRunnerResults);
        }
    }

    Instantiator {
        id: runnerInst
        model: runnerModel
        asynchronous: false
        delegate: Item {
            width: 0; height: 0; visible: false
            readonly property int row: index
            readonly property string display: String(model.display !== undefined ? model.display : "")
            readonly property string description: String(model.description !== undefined ? model.description : "")
            readonly property var decoration: model.decoration
            readonly property var url: model.url
            readonly property string favoriteId: String(model.favoriteId !== undefined ? model.favoriteId : "")
            readonly property string group: String(model.group !== undefined ? model.group
                : (model.category !== undefined ? model.category : ""))
            readonly property bool isSeparator: !!(model.isSeparator || model.IsSeparator
                || model.isSection || model.IsSection)
        }
        onObjectAdded: root.rebuildRunnerResults()
        onObjectRemoved: root.rebuildRunnerResults()
    }

    function rebuildRunnerResults() {
        var out = [];
        var n = runnerInst.count;
        // RunnerModel inserts separator rows whose display is the category (Apps / Settings / …)
        var currentGroup = "";
        for (var i = 0; i < n && out.length < 40; ++i) {
            var obj = runnerInst.objectAt(i);
            if (!obj)
                continue;
            if (obj.isSeparator) {
                currentGroup = String(obj.display || "").trim();
                continue;
            }
            var name = String(obj.display || "").trim();
            if (!name)
                continue;
            var icon = "application-x-executable";
            try {
                if (typeof obj.decoration === "string" && obj.decoration.length)
                    icon = obj.decoration;
                else if (obj.decoration && obj.decoration.name)
                    icon = String(obj.decoration.name);
            } catch (e) {}
            var uri = obj.url !== undefined && obj.url !== null ? String(obj.url) : "";
            var group = "";
            try {
                if (obj.group)
                    group = String(obj.group);
            } catch (e2) {}
            if (!group)
                group = currentGroup;
            out.push({
                id: "runner:" + i + ":" + (obj.favoriteId || name),
                name: name,
                icon: icon,
                genericName: obj.description || "",
                description: obj.description || "",
                favoriteId: obj.favoriteId || "",
                kickerUrl: uri,
                entryPath: uri,
                provider: "runner",
                group: group,
                runnerIndex: obj.row,
                noDisplay: false
            });
        }
        root.runnerResults = out;
        runnerResultsUpdated(out);
        if (menuData)
            menuData.runnerResults = out;
    }

    function triggerRunnerAt(index) {
        if (index === undefined || index === null || index < 0)
            return false;
        try {
            return !!runnerModel.trigger(index, "", null);
        } catch (e) {
            console.warn("ArcMenu runner trigger failed", e);
            return false;
        }
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
        try {
            if (root.rootModel && root.rootModel.favoritesModel)
                return root.rootModel.favoritesModel;
        } catch (e) {}
        return null;
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
        model: root.favoritesModel()
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
            out.push({
                id: "kplace:" + uri,
                name: name,
                icon: icon,
                kickerUrl: uri,
                entryPath: uri,
                exec: "",
                place: "",
                path: uri.indexOf("file://") === 0 ? decodeURIComponent(uri.substring(7)) : "",
                isDevice: !!obj.isDevice,
                categories: ["Places"],
                keywords: [],
                genericName: name,
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
