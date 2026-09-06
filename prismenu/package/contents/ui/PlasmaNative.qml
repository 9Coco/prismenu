import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker
import org.kde.plasma.private.sessions as Sessions
import org.kde.plasma.plasma5support as P5Support

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
    property var systemPlaceUrls: ({})
    property bool systemPlaceMetadataReady: false
    property bool systemPlaceMetadataPending: false
    property var plasmaFavoriteIds: []
    property var favoritesModelOverride: null
    readonly property var favoritesSourceModel: {
        if (root.favoritesModelOverride)
            return root.favoritesModelOverride;
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
                    console.warn("Prismenu: SessionManagement.canShutdown is false");
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
            console.warn("Prismenu SessionManagement failed:", actionId, err);
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

            // Kickoff reads this role from the live RunnerModel row.
            function systemActions() {
                try { return Array.from(model.actionList || []); }
                catch (e) { return []; }
            }
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
                kickerSource: obj,
                noDisplay: false
            });
        }
        root.runnerResults = out;
        runnerResultsUpdated(out);
        if (menuData)
            menuData.runnerResults = out;
    }

    function triggerRunnerAt(runnerRow, matchIndex, actionId, actionArgument) {
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
                return !!m.trigger(matchIndex, String(actionId || ""),
                    actionArgument === undefined ? null : actionArgument);
        } catch (e) {
            console.warn("Prismenu runner trigger failed", e);
        }
        return false;
    }

    function runnerSourceAt(runnerRow, matchIndex) {
        if (matchIndex === undefined || matchIndex === null || matchIndex < 0)
            return null;
        if (runnerRow === undefined || runnerRow === null || runnerRow < 0)
            runnerRow = 0;
        if (runnerRow !== 0)
            return null;
        try { return matchesInst.objectAt(matchIndex); } catch (e) { return null; }
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
        var ids = [];
        var j;
        for (j = 0; j < favInst.count; ++j) {
            var o = favInst.objectAt(j);
            if (o && o.favoriteId)
                ids.push(String(o.favoriteId));
        }
        if (!ids.length) {
            var fm = favoritesModel();
            try {
                var n = fm ? fm.count : 0;
                for (var i = 0; i < n; ++i) {
                    var fid = "";
                    try {
                        var idx = fm.index(i, 0);
                        fid = String(fm.data(idx, fm.favoriteIdRole !== undefined ? fm.favoriteIdRole : Qt.UserRole + 3) || "");
                    } catch (e1) {}
                    if (fid)
                        ids.push(fid);
                }
            } catch (e) {}
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
            readonly property int row: index
            readonly property string favoriteId: {
                var fid = model.favoriteId;
                if (fid)
                    return String(fid);
                return String(model.url || "");
            }
            readonly property string display: String(model.display !== undefined ? model.display : "")
            readonly property var url: model.url
            function systemActions() {
                try { return Array.from(model.actionList || []); }
                catch (e) { return []; }
            }
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

    function _favoriteIdVariants(value) {
        var out = [];
        function push(v) {
            v = String(v || "").trim();
            if (!v || out.indexOf(v) >= 0)
                return;
            out.push(v);
        }
        push(value);
        var s = String(value || "").trim();
        if (!s)
            return out;
        if (s.indexOf("applications:") === 0)
            push(s.substring("applications:".length));
        else if (s.indexOf(":") < 0)
            push("applications:" + s);
        var base = s.indexOf("applications:") === 0 ? s.substring("applications:".length) : s;
        if (base.indexOf(".desktop") < 0 && base.indexOf("/") < 0 && base.indexOf(":") < 0)
            push(base + ".desktop");
        if (base.slice(-8) === ".desktop")
            push(base.substring(0, base.length - 8));
        if (out.indexOf("applications:" + base) < 0 && base.indexOf(":") < 0)
            push("applications:" + base);
        if (base.slice(-8) !== ".desktop" && base.indexOf(":") < 0) {
            push("applications:" + base + ".desktop");
            push(base + ".desktop");
        }
        return out;
    }

    function isPlasmaFavorite(favoriteId) {
        var fm = favoritesModel();
        if (!fm || !favoriteId)
            return false;
        var ids = root._favoriteIdVariants(favoriteId);
        for (var i = 0; i < ids.length; ++i) {
            try {
                if (fm.isFavorite(ids[i]))
                    return true;
            } catch (e) {}
        }
        return !!root.favoriteSourceForId(favoriteId);
    }

    function togglePlasmaFavorite(favoriteId) {
        return root.setPlasmaFavorite(favoriteId, !root.isPlasmaFavorite(favoriteId));
    }

    function setPlasmaFavorite(favoriteId, favorite) {
        var fm = favoritesModel();
        if (!fm)
            return false;
        var ids = root._favoriteIdVariants(favoriteId);
        var matched = "";
        var i;
        for (i = 0; i < ids.length; ++i) {
            try {
                if (fm.isFavorite(ids[i])) {
                    matched = ids[i];
                    break;
                }
            } catch (e1) {}
        }
        if (!matched) {
            var src = root.favoriteSourceForId(favoriteId);
            if (src && src.favoriteId)
                matched = String(src.favoriteId);
        }
        try {
            if (favorite) {
                if (matched)
                    return true;
                var addId = ids.length ? ids[0] : String(favoriteId || "");
                if (!addId)
                    return false;
                fm.addFavorite(addId);
            } else {
                if (!matched)
                    return false;
                fm.removeFavorite(matched);
            }
            if (menuData && menuData.dropPinnedPreviewForce)
                menuData.dropPinnedPreviewForce();
            root.refreshPlasmaFavorites();
            Qt.callLater(root.refreshPlasmaFavorites);
            return true;
        } catch (e) {
            console.warn("Prismenu setPlasmaFavorite failed:", favoriteId, e);
            return false;
        }
    }

    function insertPlasmaFavorite(favoriteId, index) {
        var fm = favoritesModel();
        if (!fm || !favoriteId)
            return false;
        try {
            var id = String(favoriteId);
            if (fm.isFavorite(id))
                return false;
            fm.addFavorite(id, Math.max(0, index | 0));
            Qt.callLater(root.refreshPlasmaFavorites);
            return true;
        } catch (e) {
            console.warn("Prismenu insertPlasmaFavorite failed:", favoriteId, e);
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
            console.warn("Prismenu movePlasmaFavorite failed:", from, to, e);
            return false;
        }
    }

    function _favoriteIdNorm(value) {
        var s = String(value || "");
        if (s.indexOf("applications:") === 0)
            s = s.substring("applications:".length);
        return s;
    }

    /** Live KAStats favorites row Kickoff would right-click. */
    function favoriteSourceForId(favoriteId) {
        var variants = root._favoriteIdVariants(favoriteId);
        if (!variants.length)
            return null;
        var n = favInst.count;
        for (var i = 0; i < n; ++i) {
            var obj = favInst.objectAt(i);
            if (!obj)
                continue;
            var haveVars = root._favoriteIdVariants(obj.favoriteId);
            for (var a = 0; a < variants.length; ++a) {
                for (var b = 0; b < haveVars.length; ++b) {
                    if (variants[a] === haveVars[b])
                        return obj;
                }
            }
        }
        return null;
    }

    function favoriteSourceForApp(app) {
        if (!app)
            return null;
        var keys = [app.favoriteId, app.id, app.kickerUrl, app.entryPath];
        var i;
        for (i = 0; i < keys.length; ++i) {
            var src = root.favoriteSourceForId(keys[i]);
            if (src)
                return src;
        }
        var name = String(app.name || "").toLowerCase();
        if (!name)
            return null;
        var n = favInst.count;
        for (i = 0; i < n; ++i) {
            var obj = favInst.objectAt(i);
            if (obj && String(obj.display || "").toLowerCase() === name)
                return obj;
        }
        return null;
    }

    function removeFavoriteForApp(app, actionArgument) {
        var fm = favoritesModel();
        if (!fm)
            return false;
        var keys = [];
        function push(v) {
            if (v && typeof v === "object" && v.favoriteId)
                v = v.favoriteId;
            v = String(v || "");
            if (v && v !== "[object Object]" && keys.indexOf(v) < 0)
                keys.push(v);
        }
        push(actionArgument);
        var src = root.favoriteSourceForApp(app);
        if (src)
            push(src.favoriteId);
        if (app) {
            push(app.favoriteId);
            push(app.id);
            push(app.kickerUrl);
            push(app.entryPath);
            if (menuData && menuData.plasmaFavoriteIdForApp)
                push(menuData.plasmaFavoriteIdForApp(app));
        }
        var i;
        for (i = 0; i < keys.length; ++i) {
            var id = keys[i];
            var variants = root._favoriteIdVariants(id);
            var v;
            for (v = 0; v < variants.length; ++v) {
                try { fm.removeFavorite(variants[v]); } catch (e0) {}
            }
            try {
                if (fm.linkedActivitiesFor && fm.removeFavoriteFrom) {
                    var linked = fm.linkedActivitiesFor(id) || [];
                    for (var a = 0; a < linked.length; ++a)
                        fm.removeFavoriteFrom(id, linked[a]);
                }
            } catch (e1) {}
        }
        if (src && fm.trigger) {
            try {
                fm.trigger(src.row, "_kicker_favorite_remove",
                    { favoriteId: String(src.favoriteId) });
            } catch (e2) {}
        }
        console.log("Prismenu removeFavoriteForApp app=", app ? app.id : "",
            "rowId=", src ? src.favoriteId : "", "tried=", keys.join(","),
            "countNow=", fm.count);
        if (menuData && menuData.dropPinnedPreviewForce)
            menuData.dropPinnedPreviewForce();
        root.refreshPlasmaFavorites();
        Qt.callLater(root.refreshPlasmaFavorites);
        return true;
    }

    function triggerFavoriteAt(index, actionId, actionArgument) {
        var fm = favoritesModel();
        if (!fm || index < 0 || !fm.trigger)
            return false;
        try {
            return !!fm.trigger(index, String(actionId || ""),
                actionArgument === undefined ? null : actionArgument);
        } catch (e) {
            console.warn("Prismenu favorite trigger failed", e);
            return false;
        }
    }

    // ---- Places (the same Kicker.ComputerModel used by official Kickoff) ----
    // ComputerModel intentionally combines KDE's built-in places with bookmarks
    // added by the user in Dolphin. Its public roles do not expose the XBEL
    // isSystemItem bit, so read that bit from KDE's own user-places.xbel file.
    P5Support.DataSource {
        id: placesMetadataExec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            placesMetadataExec.disconnectSource(sourceName);
            root.systemPlaceMetadataPending = false;
            var urls = {};
            try {
                var out = String((data && data.stdout) || "");
                var rx = /href="([^"]*)"/g;
                var match;
                while ((match = rx.exec(out)) !== null) {
                    var uri = root.decodeXmlAttribute(match[1]);
                    if (uri.length)
                        urls[root.normalizedPlaceUrl(uri)] = true;
                }
            } catch (e) {
                console.warn("Prismenu system-place metadata parse failed:", e);
            }
            root.systemPlaceUrls = urls;
            root.systemPlaceMetadataReady = true;
            root.rebuildPlaces();
        }
    }

    Timer {
        id: placesMetadataTimer
        interval: 80
        repeat: false
        onTriggered: root.refreshSystemPlaceMetadata()
    }

    function shellQuotePlaceMetadata(value) {
        return "'" + String(value || "").replace(/'/g, "'\\''") + "'";
    }

    function decodeXmlAttribute(value) {
        return String(value || "")
            .replace(/&quot;/g, "\"")
            .replace(/&apos;/g, "'")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&amp;/g, "&");
    }

    function normalizedPlaceUrl(value) {
        var uri = String(value || "").trim();
        try { uri = decodeURI(uri); } catch (e) {}
        while (uri.length > 1 && uri.endsWith("/") && !/^[a-z][a-z0-9+.-]*:\/$/i.test(uri))
            uri = uri.substring(0, uri.length - 1);
        return uri;
    }

    function refreshSystemPlaceMetadata() {
        if (root.systemPlaceMetadataPending)
            return;
        root.systemPlaceMetadataPending = true;
        var xpath = "//*[local-name()='bookmark'][*[local-name()='info']//*[local-name()='isSystemItem' and normalize-space(text())='true']]/@href";
        var script = "f=\"$HOME/.local/share/user-places.xbel\"; "
            + "[ -r \"$f\" ] && xmllint --xpath " + root.shellQuotePlaceMetadata(xpath)
            + " \"$f\" 2>/dev/null || true";
        placesMetadataExec.connectSource("/bin/bash -lc " + root.shellQuotePlaceMetadata(script));
    }

    function scheduleSystemPlaceMetadataRefresh() {
        placesMetadataTimer.restart();
    }

    function isSystemPlaceUrl(uri) {
        return root.systemPlaceUrls[root.normalizedPlaceUrl(uri)] === true;
    }

    Kicker.ComputerModel {
        id: computerModel
        appletInterface: root.appletInterface
        favoritesModel: root.favoritesSourceModel
        // The right rail is a places list, so omit ComputerModel's optional
        // System Settings application. Rows without a URL (KRunner/apps) are
        // filtered below as well.
        systemApplications: []
        Component.onCompleted: {
            root.scheduleSystemPlaceMetadataRefresh();
            Qt.callLater(root.rebuildPlaces);
        }
        onCountChanged: {
            root.rebuildPlaces();
            root.scheduleSystemPlaceMetadataRefresh();
        }
        onDataChanged: {
            root.rebuildPlaces();
            root.scheduleSystemPlaceMetadataRefresh();
        }
        onModelReset: {
            root.rebuildPlaces();
            root.scheduleSystemPlaceMetadataRefresh();
        }
    }

    Instantiator {
        id: placesInst
        model: computerModel
        asynchronous: false
        delegate: Item {
            width: 0; height: 0; visible: false
            readonly property string display: String(model.display !== undefined ? model.display : "")
            readonly property string description: String(model.description !== undefined ? model.description : "")
            readonly property var decoration: model.decoration
            readonly property var url: model.url
            readonly property string group: String(model.group !== undefined ? model.group : "")
            readonly property int computerRow: index
        }
        onObjectAdded: root.rebuildPlaces()
        onObjectRemoved: root.rebuildPlaces()
    }

    function rebuildPlaces() {
        var out = [];
        var n = placesInst.count;
        for (var i = 0; i < n && out.length < 40; ++i) {
            var obj = placesInst.objectAt(i);
            if (!obj)
                continue;
            var name = String(obj.display || "").trim();
            var uri = obj.url !== undefined && obj.url !== null ? String(obj.url) : "";
            if (!name || !uri)
                continue;
            var icon = "folder";
            try {
                if (typeof obj.decoration === "string" && obj.decoration.length)
                    icon = obj.decoration;
                else if (obj.decoration && obj.decoration.name)
                    icon = String(obj.decoration.name);
            } catch (e) {}
            var localPath = uri.indexOf("file://") === 0 ? decodeURIComponent(uri.substring(7)) : "";
            var modelDescription = String(obj.description || "").trim();
            var isDevice = modelDescription.length > 0;
            var detail = modelDescription;
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
                isDevice: isDevice,
                isSystemPlace: isDevice || root.isSystemPlaceUrl(uri),
                placeGroup: obj.group,
                computerRow: obj.computerRow,
                categories: ["Places"],
                keywords: [],
                genericName: detail,
                description: detail,
                provider: "kicker-computer",
                noDisplay: false
            });
        }
        root.placesEntries = out;
        placesUpdated(out);
        if (menuData)
            menuData.plasmaPlaces = out;
    }

    function triggerComputerAt(row) {
        try {
            computerModel.trigger(row, "", undefined);
            return true;
        } catch (e) {
            console.warn("Prismenu ComputerModel trigger failed:", row, e);
            return false;
        }
    }

    function openPlaceUrl(url) {
        if (!url)
            return false;
        try {
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
            console.warn("Prismenu kicker trigger failed", e);
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
