import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.kicker as Kicker
import "../code/AppsModel.js" as AppsModel
import "../code/CategoryMeta.js" as CategoryMeta
import "../code/KickoffTools.js" as KickoffTools

/**
 * Application catalog via Plasma Kicker — same stack as Kickoff / XDG menus on KDE:
 *   org.kde.plasma.private.kicker → RootModel → KService / KSycoca / applications.menu
 *
 * Categories (办公 / 影音 / 系统…) and apps are read from RootModel with the same
 * QML model roles Kickoff uses (display, hasChildren, url, favoriteId, …).
 * Session / favorites / runners / places: see PlasmaNative.qml
 */
Item {
    id: root

    property var menuData: null
    /** PlasmoidItem required by Kicker context actions (same object Kickoff uses). */
    property var appletInterface: null
    /** Official launcher client format; main.qml supplies the real Plasmoid id. */
    property string favoritesClientId: "org.kde.plasma.arcmenu.favorites.instance-0"
    property string lastScanError: ""
    property string scanBackend: "kicker"
    property int lastAppCount: 0
    /** Shared native category metadata for runtime layouts and settings. */
    property var categories: []
    property bool _rebuilding: false
    property int _rebuildToken: 0
    /** Recent files via Kicker.RecentUsageModel (see SearchNativeProviders) */
    property var recentFiles: []
    /** Open windows via TaskManager.TasksModel */
    property var openWindows: []

    signal appsUpdated(var apps)
    signal metaUpdated(string userName, string userIcon, string osId, string osPretty)
    signal scanFailed(string message)
    signal recentFilesUpdated(var files)
    signal openWindowsUpdated(var windows)

    SearchNativeProviders {
        id: nativeSearch
        onRecentFilesUpdated: (files) => {
            root.recentFiles = files;
            root.recentFilesUpdated(files);
            if (menuData)
                menuData.recentFileResults = files;
        }
        onOpenWindowsUpdated: (windows) => {
            root.openWindows = windows;
            root.openWindowsUpdated(windows);
            if (menuData)
                menuData.openWindowResults = windows;
        }
    }

    readonly property var nameToId: ({
        "Office": "Office", "办公": "Office",
        "Development": "Development", "开发": "Development", "Programming": "Development", "编程": "Development",
        "Utility": "Utility", "Utilities": "Utility", "Tools": "Utility", "工具": "Utility", "实用工具": "Utility",
        "Accessories": "Accessories", "附件": "Accessories",
        "Network": "Network", "Internet": "Network", "互联网": "Network", "网络": "Network",
        "Graphics": "Graphics", "图像处理": "Graphics", "图形": "Graphics",
        "System": "System", "系统": "System", "系统工具": "System",
        "Settings": "Settings", "设置": "Settings",
        "Education": "Education", "科学和数学": "Education", "Science": "Education", "Science & Math": "Education",
        "Game": "Game", "Games": "Game", "游戏": "Game",
        "AudioVideo": "AudioVideo", "Multimedia": "AudioVideo", "Sound & Video": "AudioVideo", "影音": "AudioVideo", "音视频": "AudioVideo",
        "Help": "Help", "帮助": "Help"
    })

    readonly property var skipNames: ({
        "Favorites": true, "Favorite Applications": true, "常用应用程序": true,
        "All Applications": true, "全部应用程序": true, "所有应用程序": true,
        "Recent Applications": true, "Recent Documents": true, "Recent Contacts": true,
        "Often Used Applications": true, "Often Used Documents": true,
        "Power / Session": true, "Leave": true, "会话": true
    })

    // Launch / power / user-meta probes
    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            try {
                var out = String((data && data.stdout) ? data.stdout : "");
                var idx = out.indexOf("ARCMENU_META|");
                if (idx >= 0) {
                    var line = out.substring(idx).split("\n")[0];
                    var p = line.split("|");
                    var u = (p[1] || "").trim();
                    var iconPath = (p[2] || "").trim();
                    var osId = (p[3] || "").trim();
                    var osPretty = (p[4] || "").trim();
                    var iconSrc = "user-identity";
                    if (iconPath.length) {
                        iconSrc = iconPath.indexOf("file:") === 0
                            ? iconPath
                            : ("file://" + iconPath);
                    }
                    root._osMetaLoaded = true;
                    metaUpdated(u, iconSrc, osId, osPretty);
                }
            } catch (e) {
                console.warn("ArcMenu exec parse failed:", e);
            }
            root._osMetaPending = false;
            disconnectSource(sourceName);
        }
    }

    Kicker.RootModel {
        id: rootModel
        appletInterface: root.appletInterface
        appNameFormat: 0
        flat: false
        showSeparators: false
        showAllApps: true
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
        Component.onCompleted: {
            function setOpt(obj, key, value) {
                try { obj[key] = value; } catch (e) {}
            }
            try {
                // Same initialization path and client-id format as Kickoff.
                rootModel.favoritesModel.initForClient(root.favoritesClientId);
            } catch (favoritesError) {
                console.warn("ArcMenu favorites init failed:", favoritesError);
            }
            setOpt(rootModel, "sorted", true);
            setOpt(rootModel, "showRecentContacts", false);
            setOpt(rootModel, "showFavoritesPlaceholder", false);
            // Plasma 6: autoPopulate lives on AppsModel; prefer explicit refresh
            setOpt(rootModel, "autoPopulate", false);
            Qt.callLater(function () {
                root.refresh();
                if (plasmaNative && plasmaNative.refreshPlasmaFavorites)
                    plasmaNative.refreshPlasmaFavorites();
            });
        }

        onCountChanged: root.scheduleRebuild()
        onRefreshed: root.scheduleRebuild()
    }

    PlasmaNative {
        id: plasmaNative
        menuData: root.menuData
        rootModel: rootModel
        appletInterface: root.appletInterface
    }

    // Nested Instantiators materialize the same roles Kickoff ListViews see.
    Instantiator {
        id: catInst
        model: rootModel
        asynchronous: false

        delegate: Item {
            id: catDel
            width: 0
            height: 0
            visible: false

            readonly property int row: index
            readonly property string display: String(model.display !== undefined ? model.display : "")
            readonly property bool hasChildren: !!(model.hasChildren)
            readonly property string description: String(model.description !== undefined ? model.description : "")
            readonly property var decoration: model.decoration
            readonly property var childModel: catDel.hasChildren ? rootModel.modelForRow(index) : null
            property alias appInst: appInst

            Instantiator {
                id: appInst
                model: catDel.childModel
                asynchronous: false

                delegate: Item {
                    id: appDel
                    width: 0
                    height: 0
                    visible: false

                    readonly property int row: index
                    readonly property string display: String(model.display !== undefined ? model.display : "")
                    readonly property bool hasChildren: !!(model.hasChildren)
                    readonly property string description: String(model.description !== undefined ? model.description : "")
                    readonly property var decoration: model.decoration
                    readonly property var url: model.url
                    readonly property string favoriteId: String(model.favoriteId !== undefined ? model.favoriteId : "")
                    readonly property var nestedModel: (appDel.hasChildren && catDel.childModel)
                        ? catDel.childModel.modelForRow(index) : null
                    property alias nestedInst: nestedInst

                    // actionList is deliberately read only when the context
                    // menu opens. Binding it for every row while RootModel is
                    // rebuilding can ask Kicker for actions on stale indexes.
                    function systemActions() {
                        try { return Array.from(model.actionList || []); }
                        catch (e) { return []; }
                    }

                    Instantiator {
                        id: nestedInst
                        model: appDel.nestedModel
                        asynchronous: false

                        delegate: Item {
                            id: nestedDel
                            width: 0
                            height: 0
                            visible: false
                            readonly property int row: index
                            readonly property string display: String(model.display !== undefined ? model.display : "")
                            readonly property bool hasChildren: !!(model.hasChildren)
                            readonly property string description: String(model.description !== undefined ? model.description : "")
                            readonly property var decoration: model.decoration
                            readonly property var url: model.url
                            readonly property string favoriteId: String(model.favoriteId !== undefined ? model.favoriteId : "")

                            function systemActions() {
                                try { return Array.from(model.actionList || []); }
                                catch (e) { return []; }
                            }
                        }

                        onObjectAdded: root.scheduleRebuild()
                        onObjectRemoved: root.scheduleRebuild()
                    }
                }

                onObjectAdded: root.scheduleRebuild()
                onObjectRemoved: root.scheduleRebuild()
            }
        }

        onObjectAdded: root.scheduleRebuild()
        onObjectRemoved: root.scheduleRebuild()
    }

    Timer {
        id: rebuildTimer
        interval: 120
        repeat: false
        onTriggered: root.rebuild()
    }

    Timer {
        id: retryTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (root.lastAppCount === 0 && rootModel.count > 0)
                root.rebuild();
        }
    }

    function scheduleRebuild() {
        rebuildTimer.restart();
    }

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function categoryIdFromName(name) {
        if (!name)
            return "";
        if (root.nameToId[name] !== undefined)
            return root.nameToId[name];
        return String(name).replace(/\s+/g, "") || "";
    }

    function iconNameFromDecoration(dec) {
        if (dec === undefined || dec === null)
            return "applications-other";
        if (typeof dec === "string")
            return dec.length ? dec : "applications-other";
        try {
            if (dec.name)
                return String(dec.name);
        } catch (e) {}
        return "applications-other";
    }

    function desktopIdFromUrl(url, favoriteId, display) {
        if (favoriteId && String(favoriteId).indexOf(".desktop") >= 0)
            return String(favoriteId);
        var u = String(url || "");
        if (u.indexOf("applications:") === 0)
            return u.substring("applications:".length);
        if (u.indexOf("file://") === 0) {
            var path = decodeURIComponent(u.substring(7));
            var slash = path.lastIndexOf("/");
            return slash >= 0 ? path.substring(slash + 1) : path;
        }
        if (u.endsWith(".desktop")) {
            var s = u.lastIndexOf("/");
            return s >= 0 ? u.substring(s + 1) : u;
        }
        if (favoriteId && String(favoriteId).length)
            return String(favoriteId);
        return display ? String(display).replace(/\s+/g, "_") + ".desktop" : "";
    }

    function pushApp(display, url, favoriteId, decoration, catId, apps, seenApp,
                     genericName, kickerPath, kickerSource) {
        display = String(display || "").trim();
        if (!display)
            return;
        var id = desktopIdFromUrl(url, favoriteId, display);
        if (!id)
            return;
        if (seenApp[id]) {
            if (catId && catId !== "all" && seenApp[id].categories.indexOf(catId) < 0)
                seenApp[id].categories.push(catId);
            if (genericName && !seenApp[id].genericName)
                seenApp[id].genericName = String(genericName);
            if ((!seenApp[id].kickerModelPath || seenApp[id].kickerModelPath.length < 2)
                    && kickerPath && kickerPath.length >= 2) {
                seenApp[id].kickerModelPath = kickerPath;
                seenApp[id].kickerSource = kickerSource;
            }
            return;
        }
        var app = {
            id: id,
            name: display,
            genericName: genericName ? String(genericName) : "",
            icon: iconNameFromDecoration(decoration) || "application-x-executable",
            exec: "",
            categories: (catId && catId !== "all") ? [catId] : [],
            keywords: [],
            noDisplay: false,
            isFavorite: false,
            entryPath: String(url || ""),
            favoriteId: favoriteId ? String(favoriteId) : id,
            kickerUrl: url ? String(url) : "",
            // The official Kickoff menu invokes context actions on the Kicker
            // model that produced the row. Keep the complete model path so
            // nested application-menu groups resolve to the correct row too.
            kickerModelPath: kickerPath || [],
            kickerSource: kickerSource || null
        };
        seenApp[id] = app;
        apps.push(app);
    }

    function collectFromAppInst(appInst, catId, apps, seenApp, catRow) {
        if (!appInst)
            return;
        for (var i = 0; i < appInst.count; ++i) {
            var row = appInst.objectAt(i);
            if (!row)
                continue;
            if (row.hasChildren && row.nestedInst && row.nestedInst.count > 0) {
                for (var j = 0; j < row.nestedInst.count; ++j) {
                    var nested = row.nestedInst.objectAt(j);
                    if (!nested || nested.hasChildren)
                        continue;
                    var ng = "";
                    try { ng = nested.genericName || nested.description || ""; } catch (e1) {}
                    pushApp(nested.display, nested.url, nested.favoriteId, nested.decoration,
                            catId, apps, seenApp, ng, [catRow, i, j], nested);
                }
            } else if (!row.hasChildren) {
                var g = "";
                try { g = row.genericName || row.description || ""; } catch (e2) {}
                pushApp(row.display, row.url, row.favoriteId, row.decoration,
                        catId, apps, seenApp, g, [catRow, i], row);
            }
        }
    }

    function rebuild() {
        if (root._rebuilding)
            return;
        root._rebuilding = true;
        var token = ++root._rebuildToken;

        var apps = [];
        var cats = [];
        var seenApp = {};

        try {
            console.log("ArcMenu Kicker rebuild: rootModel.count=", rootModel.count,
                        "catInst.count=", catInst.count);

            for (var i = 0; i < catInst.count; ++i) {
                var cat = catInst.objectAt(i);
                if (!cat)
                    continue;

                var name = String(cat.display || "").trim();
                var desc = String(cat.description || "");

                // Separator / empty
                if (!name || name.indexOf("---") === 0)
                    continue;

                // Kickoff "All Applications" synthetic model
                if (desc.indexOf("KICKER_ALL_MODEL") >= 0 || root.skipNames[name]) {
                    if (desc.indexOf("KICKER_ALL_MODEL") >= 0)
                        collectFromAppInst(cat.appInst, "all", apps, seenApp, cat.row);
                    continue;
                }

                if (!cat.hasChildren || !cat.childModel)
                    continue;

                var catId = categoryIdFromName(name);
                if (!catId)
                    continue;

                cats.push({
                    id: catId,
                    name: name,
                    icon: CategoryMeta.iconForCategory(
                        name, catId, iconNameFromDecoration(cat.decoration))
                });
                collectFromAppInst(cat.appInst, catId, apps, seenApp, cat.row);
            }
        } catch (err) {
            lastScanError = String(err);
            console.warn("ArcMenu Kicker rebuild failed:", err);
            scanFailed(lastScanError);
            root._rebuilding = false;
            return;
        }

        if (token !== root._rebuildToken) {
            root._rebuilding = false;
            return;
        }

        apps.sort(function (a, b) {
            return String(a.name || "").localeCompare(String(b.name || ""), undefined, { sensitivity: "base" });
        });

        lastAppCount = apps.length;
        root.categories = cats;
        scanBackend = "kicker";
        lastScanError = apps.length === 0 ? "kicker returned 0 apps" : "";
        console.log("ArcMenu Kicker:", apps.length, "apps,", cats.length, "cats");

        if (menuData) {
            if (cats.length > 0)
                menuData.rawCategories = cats;
            menuData.allApps = apps;
            Qt.callLater(menuData.migrateLegacyFavoritesToPlasma);
        }
        appsUpdated(apps);

        if (apps.length === 0)
            scanFailed(lastScanError);

        root._rebuilding = false;

        // Model often finishes populating shortly after first refresh
        if (apps.length === 0 && rootModel.count > 0)
            retryTimer.start();
    }

    function refresh() {
        lastScanError = "";
        try {
            if (rootModel.refresh)
                rootModel.refresh();
            else
                scheduleRebuild();
        } catch (e) {
            lastScanError = String(e);
            console.warn("ArcMenu Kicker refresh failed:", e);
            scanFailed(lastScanError);
            scheduleRebuild();
        }
        // os-release is static — only probe once (see refreshUserMeta)
        if (!_osMetaLoaded)
            refreshUserMeta();
    }

    property bool _osMetaLoaded: false
    property bool _osMetaPending: false

    /**
     * OS id for distro icon — user face/name come from KUser (Kickoff).
     * Debounced / one-shot to avoid spam during plasmashell restart.
     */
    function refreshUserMeta(force) {
        if (!force && root._osMetaLoaded)
            return;
        if (root._osMetaPending)
            return;
        root._osMetaPending = true;
        var script = [
            "u=\"${USER:-}\"; [ -n \"$u\" ] || u=\"$(id -un 2>/dev/null)\";",
            "osid=\"\"; osp=\"\";",
            "if [ -r /etc/os-release ]; then . /etc/os-release; osid=\"${ID:-}\"; osp=\"${PRETTY_NAME:-}\"; fi",
            "printf 'ARCMENU_META|%s||%s|%s\\n' \"$u\" \"$osid\" \"$osp\""
        ].join(" ");
        exec.connectSource("/bin/bash -lc " + shellQuote(script));
    }

    /**
     * Open an XDG user directory via real filesystem path.
     * `xdg:Download` is NOT a valid KIO URL — use `xdg-user-dir DOWNLOAD`.
     * name: HOME | DOCUMENTS | DOWNLOAD | MUSIC | PICTURES | VIDEOS | …
     */
    function openXdgUserDir(name) {
        var key = String(name || "HOME").toUpperCase();
        var aliases = {
            "DOWNLOADS": "DOWNLOAD",
            "DOCS": "DOCUMENTS",
            "DOCUMENT": "DOCUMENTS",
            "PIC": "PICTURES",
            "PICTURE": "PICTURES",
            "VIDEO": "VIDEOS"
        };
        if (aliases[key])
            key = aliases[key];

        var script;
        if (key === "HOME" || key === "") {
            script = 'p="$HOME"; kioclient exec "$p" || dolphin "$p" || xdg-open "$p"';
        } else {
            // Resolve with xdg-user-dir (honors zh_CN 下载/文档/…); then open with Dolphin/KIO
            script = 'p=$(xdg-user-dir ' + key + ' 2>/dev/null); '
                + 'if [ -z "$p" ] || [ ! -e "$p" ]; then '
                + '  case ' + key + ' in '
                + '    DOCUMENTS) p="$HOME/Documents"; [ -d "$HOME/文档" ] && p="$HOME/文档" ;; '
                + '    DOWNLOAD)  p="$HOME/Downloads"; [ -d "$HOME/下载" ] && p="$HOME/下载" ;; '
                + '    MUSIC)     p="$HOME/Music";     [ -d "$HOME/音乐" ] && p="$HOME/音乐" ;; '
                + '    PICTURES)  p="$HOME/Pictures";  [ -d "$HOME/图片" ] && p="$HOME/图片" ;; '
                + '    VIDEOS)    p="$HOME/Videos";    [ -d "$HOME/视频" ] && p="$HOME/视频" ;; '
                + '    DESKTOP)   p="$HOME/Desktop";   [ -d "$HOME/桌面" ] && p="$HOME/桌面" ;; '
                + '    *) p="$HOME" ;; '
                + '  esac; '
                + 'fi; '
                + 'mkdir -p "$p" 2>/dev/null; '
                + 'echo "ArcMenu openPlace ' + key + ' -> $p"; '
                + 'kioclient exec "$p" || dolphin "$p" || xdg-open "$p"';
        }
        console.log("ArcMenu openXdgUserDir", key);
        exec.connectSource("/bin/bash -lc " + shellQuote(script));
    }

    function launch(app, opts) {
        if (!app)
            return;
        opts = opts || {};

        // Preferred: explicit place key from PlacesSidebar / MenuData
        if (app.place) {
            openXdgUserDir(app.place);
            return;
        }

        // Official Kickoff ComputerModel place — preserve its KIO/device setup behavior.
        if (app.provider === "kicker-computer" && typeof app.computerRow === "number") {
            if (plasmaNative.triggerComputerAt(app.computerRow))
                return;
        }

        // Other file/bookmark URLs
        if ((app.provider === "kfileplaces" || app.provider === "bookmarks") && app.kickerUrl) {
            if (plasmaNative.openPlaceUrl(app.kickerUrl))
                return;
        }

        // Open window via TaskManager (native)
        if (app.provider === "windows" && typeof app.taskIndex === "number") {
            if (nativeSearch.activateWindowAt(app.taskIndex))
                return;
        }

        // Plasma Search / KRunner hit — trigger the per-runner matches model
        if (app.provider === "runner" && typeof app.runnerIndex === "number") {
            var runnerRow = (typeof app.runnerRow === "number") ? app.runnerRow : 0;
            if (plasmaNative.triggerRunnerAt(runnerRow, app.runnerIndex))
                return;
        }

        // Kickoff-style: invoke the originating AppsModel row. Synthetic
        // shortcuts and non-Kicker providers continue through the fallbacks.
        if (root.triggerSystemAction(app, "", undefined))
            return;

        if (root.launchDesktopEntry(app, opts))
            return;

        var url = app.kickerUrl || app.entryPath || "";
        var u = String(url);
        var lower = u.toLowerCase();
        var iconAsset = /\.(svg|svgz|png|xpm|ico|jpg|jpeg|webp)(\?|#|$)/.test(lower)
            || lower.indexOf("/icons/") >= 0
            || lower.indexOf("/pixmaps/") >= 0;
        if (u && !iconAsset && lower.indexOf(".desktop") < 0) {
            try {
                if (u.indexOf("preferred:") === 0) {
                    Qt.openUrlExternally(u);
                    return;
                }
                if (u.indexOf("file:") === 0 || u.indexOf("/") === 0
                    || u.indexOf("http:") === 0 || u.indexOf("https:") === 0
                    || u.indexOf("sftp:") === 0 || u.indexOf("smb:") === 0) {
                    Qt.openUrlExternally(u.indexOf("/") === 0 ? ("file://" + u) : u);
                    return;
                }
            } catch (e) {}
        }

        if (app.exec) {
            var e = String(app.exec);
            var m = e.match(/xdg:\s*([A-Za-z]+)/);
            if (m) {
                openXdgUserDir(m[1]);
                return;
            }
            if (/xdg-open\s+\$HOME/.test(e) || e === "xdg-open $HOME") {
                openXdgUserDir("HOME");
                return;
            }
            if (e.indexOf("$") >= 0 || e.indexOf(" ") >= 0)
                exec.connectSource("/bin/bash -lc " + shellQuote(e));
            else
                exec.connectSource(e);
        }
    }

    /**
     * Run a .desktop application. Never xdg-open / openUrlExternally the
     * desktop file itself — that opens Kate because .desktop is text.
     */
    function launchDesktopEntry(app, opts) {
        opts = opts || {};
        var raw = String(app.kickerUrl || app.entryPath || app.favoriteId || app.id || "");
        var lower = raw.toLowerCase();
        var isDesktop = lower.indexOf(".desktop") >= 0
            || lower.indexOf("applications:") === 0
            || /\.desktop$/i.test(String(app.id || ""));
        if (!isDesktop)
            return false;

        var desktopFile = "";
        var desktopId = "";
        if (lower.indexOf("applications:") === 0) {
            desktopId = raw.substring("applications:".length).replace(/\.desktop$/i, "");
            desktopFile = desktopId + ".desktop";
        } else if (lower.indexOf(".desktop") >= 0) {
            var path = raw;
            if (path.indexOf("file://") === 0) {
                try { path = decodeURIComponent(path.substring(7)); } catch (e1) {
                    path = path.substring(7);
                }
            }
            var slash = path.lastIndexOf("/");
            desktopFile = slash >= 0 ? path.substring(slash + 1) : path;
            desktopId = desktopFile.replace(/\.desktop$/i, "");
        } else {
            desktopId = String(app.id || app.favoriteId || "").replace(/\.desktop$/i, "");
            if (!desktopId || desktopId.indexOf("recent-app:") === 0 || desktopId.indexOf("runner:") === 0)
                return false;
            desktopFile = desktopId + ".desktop";
        }
        if (!desktopId)
            return false;

        var activate = opts.activateExisting
            ? ("kstart --activate " + shellQuote(desktopId)
                + " 2>/dev/null || kstart5 --activate " + shellQuote(desktopId) + " 2>/dev/null || ")
            : "";
        exec.connectSource("/bin/bash -lc " + shellQuote(
            activate
            + "gtk-launch " + shellQuote(desktopId)
            + " || kioclient exec " + shellQuote("applications:" + desktopFile)
            + " || kde-open5 " + shellQuote("applications:" + desktopFile)
        ));
        return true;
    }

    function runShell(cmd) {
        console.log("ArcMenu: shell", cmd);
        exec.connectSource("/bin/bash -lc " + shellQuote(cmd));
    }

    /**
     * Power / session — SessionManagement like Kickoff Leave.
     * confirmationMode: "default" | "force" | "skip"
     * Non-session actions (settings / discover / …) keep desktop helpers.
     */
    function runPower(actionId, softwareCenterCmd, confirmationMode) {
        var sessionIds = {
            "lock": 1, "logout": 1, "suspend": 1, "hibernate": 1,
            "hybridsleep": 1, "restart": 1, "reboot": 1, "shutdown": 1, "switchuser": 1
        };
        if (sessionIds[actionId]) {
            if (plasmaNative.runSessionAction(actionId, confirmationMode || "default"))
                return;
            console.warn("ArcMenu: native SessionManagement rejected", actionId);
            return;
        }

        // Settings / software center: prefer launching the resolved catalog
        // entry (KService path) instead of a bare shell exec.
        if (actionId === "settings"
            || (actionId === "discover" && (!softwareCenterCmd || softwareCenterCmd === "auto-detect"))) {
            var candidates = actionId === "settings"
                ? ["systemsettings.desktop", "org.kde.systemsettings.desktop"]
                : ["org.kde.discover.desktop", "plasma-discover.desktop"];
            for (var i = 0; i < candidates.length; ++i) {
                var found = AppsModel.findAppById(menuData ? menuData.allApps : [], candidates[i]);
                if (found) {
                    root.launch(found, {});
                    return;
                }
            }
        }

        var discover = (softwareCenterCmd && softwareCenterCmd !== "auto-detect")
            ? softwareCenterCmd
            : "plasma-discover";
        var map = {
            "settings": "systemsettings",
            "discover": discover,
            "accountsettings": "systemsettings kcm_users || kcmshell6 kcm_users || plasma-open-settings kcm_users || systemsettings",
            "overview": "qdbus org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut Overview || qdbus org.kde.kglobalaccel /component/kwin invokeShortcut Overview",
            "show-desktop": "qdbus org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut 'Show Desktop' || qdbus org.kde.kglobalaccel /component/kwin invokeShortcut 'Show Desktop'"
        };
        var cmd = map[actionId];
        if (!cmd) {
            console.warn("ArcMenu: unknown power action", actionId);
            return;
        }
        runShell(cmd);
    }

    function togglePlasmaFavorite(favoriteId) {
        return plasmaNative.togglePlasmaFavorite(favoriteId);
    }

    function isPlasmaFavorite(favoriteId) {
        return plasmaNative.isPlasmaFavorite(favoriteId);
    }

    function setPlasmaFavorite(favoriteId, favorite) {
        return plasmaNative.setPlasmaFavorite(favoriteId, favorite);
    }

    function removeFavoriteForApp(app, actionArgument) {
        return plasmaNative.removeFavoriteForApp(app, actionArgument);
    }

    function insertPlasmaFavorite(favoriteId, index) {
        return plasmaNative.insertPlasmaFavorite(favoriteId, index);
    }

    function movePlasmaFavorite(from, to) {
        return plasmaNative.movePlasmaFavorite(from, to);
    }

    function kickerSourceApp(app) {
        if (!app)
            return null;
        if (app.kickerModelPath && app.kickerModelPath.length >= 2)
            return app;
        var wantedId = desktopFileId(app);
        var catalog = menuData && menuData.allApps ? menuData.allApps : [];
        for (var i = 0; i < catalog.length; ++i) {
            if (desktopFileId(catalog[i]) === wantedId
                    && catalog[i].kickerModelPath
                    && catalog[i].kickerModelPath.length >= 2)
                return catalog[i];
        }
        return null;
    }

    function _copyActionList(source) {
        if (!source || !source.systemActions)
            return [];
        try {
            var raw = source.systemActions();
            if (!raw || !raw.length)
                return [];
            var out = [];
            for (var i = 0; i < raw.length; ++i) {
                if (raw[i] !== undefined && raw[i] !== null)
                    out.push(raw[i]);
            }
            return out;
        } catch (e) {
            return [];
        }
    }

    function _actionIdOf(entry) {
        if (!entry)
            return "";
        try { return String(entry.actionId || ""); } catch (e) { return ""; }
    }

    function _favoriteI18n(msgid) {
        try {
            var plasma = i18nd("plasma_applet_org.kde.plasma.kicker", msgid);
            if (plasma && plasma !== msgid)
                return plasma;
        } catch (e) {}
        if (menuData && menuData.tr)
            return menuData.tr(msgid);
        return msgid;
    }

    function _favoriteIdForApp(app) {
        if (!app)
            return "";
        var src = plasmaNative.favoriteSourceForApp
            ? plasmaNative.favoriteSourceForApp(app) : null;
        if (src && src.favoriteId)
            return String(src.favoriteId);
        if (menuData && menuData.plasmaFavoriteIdForApp) {
            var fromMenu = menuData.plasmaFavoriteIdForApp(app);
            if (fromMenu)
                return String(fromMenu);
        }
        return String(app.favoriteId || app.id || "");
    }

    function _canFavoriteApp(app) {
        if (!app || app.place || app.isSection)
            return false;
        var id = String(app.id || "");
        if (id === "arcmenu-settings" || id.indexOf("shortcut-") === 0
                || id.indexOf("custom:") === 0)
            return false;
        return !!_favoriteIdForApp(app);
    }

    /**
     * Kickoff ActionMenu: model.actionList plus Tools.createFavoriteActions
     * inserted before addToDesktop / addToTaskManager / addToPanel.
     */
    function systemActions(app) {
        var list = [];
        if (app && app.provider === "runner" && typeof app.runnerIndex === "number") {
            var runnerSrc = app.kickerSource
                || plasmaNative.runnerSourceAt(app.runnerRow, app.runnerIndex);
            list = root._copyActionList(runnerSrc);
        }
        if (!list.length) {
            var sourceApp = kickerSourceApp(app);
            list = root._copyActionList(sourceApp ? sourceApp.kickerSource : null);
        }
        if (!list.length) {
            var favSrc = plasmaNative.favoriteSourceForApp
                ? plasmaNative.favoriteSourceForApp(app) : null;
            list = root._copyActionList(favSrc);
        }
        if (!_canFavoriteApp(app))
            return list;
        var favId = root._favoriteIdForApp(app);
        var favActions = KickoffTools.createFavoriteActions(
            root._favoriteI18n, rootModel.favoritesModel, favId);
        return KickoffTools.insertFavoriteActions(list, favActions);
    }

    function _triggerCatalog(app, actionId, actionArgument) {
        var sourceApp = kickerSourceApp(app);
        var path = sourceApp ? (sourceApp.kickerModelPath || []) : [];
        if (path.length < 2)
            return { handled: false, closeLauncher: false };
        var sourceModel = rootModel;
        for (var p = 0; p < path.length - 1; ++p) {
            sourceModel = sourceModel.modelForRow(path[p]);
            if (!sourceModel)
                throw new Error("missing Kicker model at path index " + p);
        }
        var closeLauncher = !!KickoffTools.triggerAction(
            sourceModel, path[path.length - 1], String(actionId || ""), actionArgument);
        return { handled: true, closeLauncher: closeLauncher };
    }

    function _isFavoriteAction(actionId) {
        return KickoffTools.startsWith(actionId, "_kicker_favorite_");
    }

    /** Invoke AppsModel.trigger exactly as Kickoff's ActionMenu does. */
    function invokeSystemAction(app, actionId, actionArgument) {
        var id = String(actionId || "");
        if (root._isFavoriteAction(id)) {
            // Official Tools.triggerAction reads favoriteModel and favoriteId
            // directly from actionArgument; do not reconstruct either value.
            try {
                KickoffTools.triggerAction(null, -1, id, actionArgument);
                // A reorder preview deliberately shadows plasmaFavoriteIds.
                // Clear it before refreshing so an immediate Add/Remove action
                // cannot leave every layout rendering the stale drag snapshot.
                if (menuData && menuData.dropPinnedPreviewForce)
                    menuData.dropPinnedPreviewForce();
                Qt.callLater(plasmaNative.refreshPlasmaFavorites);
                return { handled: true, closeLauncher: false };
            } catch (favoriteError) {
                console.warn("ArcMenu favorite action failed", id, favoriteError);
                return { handled: false, closeLauncher: false };
            }
        }
        try {
            if (app && app.provider === "runner" && typeof app.runnerIndex === "number") {
                var runnerRow = (typeof app.runnerRow === "number") ? app.runnerRow : 0;
                if (plasmaNative.triggerRunnerAt(runnerRow, app.runnerIndex, id, actionArgument))
                    return { handled: true, closeLauncher: id === "" };
            }
        } catch (e0) {}
        try {
            var favSrc = plasmaNative.favoriteSourceForId
                ? plasmaNative.favoriteSourceForId(_favoriteIdForApp(app))
                : null;
            if (id && favSrc && plasmaNative.triggerFavoriteAt
                    && plasmaNative.triggerFavoriteAt(favSrc.row, id, actionArgument))
                return { handled: true, closeLauncher: false };
        } catch (e1) {}
        try {
            var catalog = root._triggerCatalog(app, id, actionArgument);
            if (catalog.handled)
                return catalog;
        } catch (e) {
            console.warn("ArcMenu Kicker trigger failed for", app ? app.id : "", actionId, e);
        }
        return { handled: false, closeLauncher: false };
    }

    /** Whether Kicker accepted the action (used by normal launch/fallbacks). */
    function triggerSystemAction(app, actionId, actionArgument) {
        return root.invokeSystemAction(app, actionId, actionArgument).handled;
    }

    /** Kicker's return value tells Kickoff whether to close after an action. */
    function triggerSystemActionAndShouldClose(app, actionId, actionArgument) {
        var result = root.invokeSystemAction(app, actionId, actionArgument);
        return result.handled && result.closeLauncher;
    }

    function desktopFileId(app) {
        if (!app)
            return "";
        // Sidebar shortcuts → real desktop entries
        if (app.action === "discover" || app.id === "shortcut-software")
            return "org.kde.discover.desktop";
        if (app.action === "settings" || app.id === "shortcut-settings")
            return "systemsettings.desktop";
        var id = String(app.id || "");
        if (id.indexOf("applications:") === 0)
            id = id.substring("applications:".length);
        if (id.indexOf("shortcut-") === 0)
            return "";
        if (id.indexOf(".desktop") < 0 && id.length)
            id = id + ".desktop";
        return id;
    }

    function desktopFilePath(app) {
        if (!app)
            return "";
        var src = app.entryPath || "";
        if (src.indexOf("file://") === 0)
            src = decodeURIComponent(src.substring(7));
        if (src && src.indexOf(".desktop") >= 0)
            return src;
        var id = desktopFileId(app);
        if (!id)
            return "";
        return "/usr/share/applications/" + id;
    }

    function refreshRecentFiles() {
        // Kicker RecentUsageModel — same stack as Kickoff “Recent Files”
        nativeSearch.refresh();
        nativeSearch.rebuildRecentFiles();
    }

    function refreshOpenWindows() {
        // TaskManager.TasksModel — all virtual desktops
        nativeSearch.refresh();
        nativeSearch.rebuildOpenWindows();
    }

}
