import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.kicker as Kicker
import "../code/AppsModel.js" as AppsModel
import "../code/CategoryMeta.js" as CategoryMeta

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
    property string lastScanError: ""
    property string scanBackend: "kicker"
    property int lastAppCount: 0
    /** Shared native category metadata for runtime layouts and settings. */
    property var categories: []
    property bool _rebuilding: false
    property int _rebuildToken: 0
    /** Recent files via Kicker.RecentUsageModel (see SearchNativeProviders) */
    property var recentFiles: []
    /** GTK bookmarks (~/.config/gtk-3.0/bookmarks) — Places sidebar */
    property var bookmarks: []
    /** Removable devices mounted under /media & /run/media (fallback source
     *  for "External devices" when KFilePlacesModel QML is unavailable) */
    property var devices: []
    /** Open windows via TaskManager.TasksModel */
    property var openWindows: []

    signal appsUpdated(var apps)
    signal metaUpdated(string userName, string userIcon, string osId, string osPretty)
    signal scanFailed(string message)
    signal recentFilesUpdated(var files)
    signal bookmarksUpdated(var bookmarks)
    signal devicesUpdated(var devices)
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
                if (out.indexOf("ARCMENU_BOOKMARK|") >= 0)
                    root._parseBookmarks(out);
                if (out.indexOf("ARCMENU_DEVICE|") >= 0)
                    root._parseDevices(out);
            } catch (e) {
                console.warn("ArcMenu exec parse failed:", e);
            }
            root._osMetaPending = false;
            disconnectSource(sourceName);
        }
    }

    Kicker.RootModel {
        id: rootModel
        appletInterface: plasmoid
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
            setOpt(rootModel, "sorted", true);
            setOpt(rootModel, "showRecentContacts", false);
            setOpt(rootModel, "showFavoritesPlaceholder", false);
            // Plasma 6: autoPopulate lives on AppsModel; prefer explicit refresh
            setOpt(rootModel, "autoPopulate", false);
            Qt.callLater(function () {
                root.refresh();
            });
        }

        onCountChanged: root.scheduleRebuild()
        onRefreshed: root.scheduleRebuild()
    }

    PlasmaNative {
        id: plasmaNative
        menuData: root.menuData
        rootModel: rootModel
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

                    Instantiator {
                        id: nestedInst
                        model: appDel.nestedModel
                        asynchronous: false

                        delegate: Item {
                            width: 0
                            height: 0
                            visible: false
                            readonly property string display: String(model.display !== undefined ? model.display : "")
                            readonly property bool hasChildren: !!(model.hasChildren)
                            readonly property var decoration: model.decoration
                            readonly property var url: model.url
                            readonly property string favoriteId: String(model.favoriteId !== undefined ? model.favoriteId : "")
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

    function pushApp(display, url, favoriteId, decoration, catId, apps, seenApp, genericName, catRow, appRow) {
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
            if (seenApp[id].kickerCatRow === undefined && catRow !== undefined) {
                seenApp[id].kickerCatRow = catRow;
                seenApp[id].kickerAppRow = appRow;
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
            kickerCatRow: catRow,
            kickerAppRow: appRow
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
                    pushApp(nested.display, nested.url, nested.favoriteId, nested.decoration, catId, apps, seenApp, ng, catRow, i);
                }
            } else if (!row.hasChildren) {
                var g = "";
                try { g = row.genericName || row.description || ""; } catch (e2) {}
                pushApp(row.display, row.url, row.favoriteId, row.decoration, catId, apps, seenApp, g, catRow, i);
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

        // Special drill-down row clicked from a layout without an apps page
        // (no in-menu list available): open the mount root directly instead
        // of doing nothing. computer:/ no longer exists on Plasma 5/6.
        if (app.special === "devices") {
            exec.connectSource("/bin/bash -lc " + shellQuote(
                'p="/media/$USER"; [ -d "$p" ] || p="$HOME"; '
                + 'kioclient exec "file://$p" || dolphin "$p" || xdg-open "$p"'));
            return;
        }

        // KFilePlaces / file URL
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

        // Kickoff-style: AppsModel.trigger(row, "", null)
        if (typeof app.kickerCatRow === "number" && typeof app.kickerAppRow === "number") {
            if (plasmaNative.triggerRootApp(app.kickerCatRow, app.kickerAppRow))
                return;
        }

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
            console.warn("ArcMenu: SessionManagement unavailable, shell fallback for", actionId);
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
            "lock": "loginctl lock-session || qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock",
            "logout": "qdbus org.kde.Shutdown /Shutdown logout || loginctl terminate-user \"$USER\"",
            "suspend": "systemctl suspend",
            "hybridsleep": "systemctl hybrid-sleep || systemctl suspend",
            "hibernate": "systemctl hibernate",
            "restart": "systemctl reboot",
            "shutdown": "systemctl poweroff",
            "settings": "systemsettings",
            "discover": discover,
            "switchuser": "qdbus org.kde.ksmserver /KSMServer openSwitchUserDialog || dm-tool switch-to-greeter",
            "accountsettings": "systemsettings kcm_users || kcmshell6 kcm_users || plasma-open-settings kcm_users || systemsettings",
            "overview": "qdbus org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut Overview || qdbus org.kde.kglobalaccel /component/kwin invokeShortcut Overview",
            "show-desktop": "qdbus org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut 'Show Desktop' || qdbus org.kde.kglobalaccel /component/kwin invokeShortcut 'Show Desktop' || xdotool key Super+D"
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

    /** Open another window / instance of the app (ArcMenu "New Window"). */
    function openNewWindow(app) {
        if (!app)
            return;
        var id = desktopFileId(app);
        var path = desktopFilePath(app);
        var url = app.kickerUrl || (path ? ("file://" + path) : "");
        // Prefer desktop action NewWindow when present; else relaunch desktop entry
        var script = "id=" + shellQuote(id) + "; f=" + shellQuote(path) + "; "
            + "if [ -f \"$f\" ] && grep -qE '^\\[Desktop Action (NewWindow|new-window|WindowNew)\\]' \"$f\" 2>/dev/null; then "
            + "  act=$(grep -oE '\\[Desktop Action [^]]+\\]' \"$f\" | head -n1 | sed -E 's/\\[Desktop Action |\\]//g'); "
            + "  gtk-launch \"$id\" \"$act\" 2>/dev/null || kioclient exec " + shellQuote(url) + "; "
            + "elif [ -n \"$id\" ]; then "
            + "  gtk-launch \"$id\" 2>/dev/null || kioclient exec " + shellQuote(url) + " || true; "
            + "else "
            + "  kioclient exec " + shellQuote(url) + "; "
            + "fi";
        console.log("ArcMenu openNewWindow", id);
        runShell(script);
    }

    /**
     * Pin application to Plasma Task Manager / Icon Tasks (快捷栏).
     * Writes launchers=… on the first matching panel widget.
     */
    function pinToTaskManager(app) {
        if (!app)
            return;
        var id = desktopFileId(app);
        if (!id)
            return;
        var entry = "applications:" + id;
        // plasmashell JS: append to Icon Tasks / Task Manager launchers
        var js = ""
            + "var entry = " + JSON.stringify(entry) + ";"
            + "var panels = panels();"
            + "for (var i = 0; i < panels.length; ++i) {"
            + "  var ws = panels[i].widgets();"
            + "  for (var j = 0; j < ws.length; ++j) {"
            + "    var t = ws[j].type;"
            + "    if (t !== 'org.kde.plasma.icontasks' && t !== 'org.kde.plasma.taskmanager') continue;"
            + "    ws[j].currentConfigGroup = ['General'];"
            + "    var cur = String(ws[j].readConfig('launchers', ''));"
            + "    if (cur.indexOf(entry) >= 0) return;"
            + "    var next = cur.length ? (cur + ',' + entry) : entry;"
            + "    ws[j].writeConfig('launchers', next);"
            + "    ws[j].reloadConfig();"
            + "    return;"
            + "  }"
            + "}";
        console.log("ArcMenu pinToTaskManager", entry);
        runShell("qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
            + shellQuote(js)
            + " || qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
            + shellQuote(js));
    }

    function addDesktopShortcut(app) {
        if (!app)
            return;
        var src = desktopFilePath(app);
        if (!src)
            return;
        runShell(
            "dest=\"$HOME/Desktop\"; [ -d \"$dest\" ] || dest=\"$HOME/桌面\"; [ -d \"$dest\" ] || dest=\"$HOME\"; "
            + "f=" + shellQuote(src) + "; [ -f \"$f\" ] && cp \"$f\" \"$dest/\" && chmod +x \"$dest/$(basename \"$f\")\""
        );
    }

    function editDesktop(app) {
        if (!app)
            return;
        var src = app.entryPath || "";
        if (src.indexOf("file://") === 0)
            src = decodeURIComponent(src.substring(7));
        if (src)
            exec.connectSource("kate " + shellQuote(src) + " || kwrite " + shellQuote(src));
    }

    function runInTerminal(app) {
        if (!app)
            return;
        var url = app.kickerUrl || app.entryPath || "";
        var exe = String(app.exec || "").replace(/%[a-zA-Z]/g, "").trim();
        if (url)
            exec.connectSource("konsole -e bash -lc " + shellQuote("kioclient exec " + url));
        else if (exe)
            exec.connectSource("konsole -e bash -lc " + shellQuote(exe));
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

    function refreshBookmarks() {
        // GTK bookmarks file (same source GNOME ArcMenu PlaceDisplay uses)
        var script = [
            "python3 - <<'PY'",
            "import os, urllib.parse",
            "paths=[",
            "  os.path.expanduser('~/.config/gtk-3.0/bookmarks'),",
            "  os.path.expanduser('~/.config/gtk-4.0/bookmarks'),",
            "]",
            "seen=set()",
            "count=0",
            "for path in paths:",
            "  if not os.path.isfile(path):",
            "    continue",
            "  with open(path, 'r', encoding='utf-8', errors='replace') as f:",
            "    for line in f:",
            "      line=line.strip()",
            "      if not line or line.startswith('#'):",
            "        continue",
            "      parts=line.split(' ', 1)",
            "      uri=parts[0].strip()",
            "      if uri in seen:",
            "        continue",
            "      seen.add(uri)",
            "      name=parts[1].strip() if len(parts)>1 else ''",
            "      if not name:",
            "        if uri.startswith('file:'):",
            "          name=urllib.parse.unquote(uri.rsplit('/',1)[-1]) or uri",
            "        else:",
            "          name=uri",
            "      print('ARCMENU_BOOKMARK|%s|%s' % (uri.replace('|','%7C'), name.replace('|','-')))",
            "      count+=1",
            "      if count>=40: break",
            "  if count>=40: break",
            "PY"
        ].join("\n");
        exec.connectSource("/bin/bash -lc " + shellQuote(script));
    }

    function _parseBookmarks(out) {
        var lines = String(out).split("\n");
        var items = [];
        for (var i = 0; i < lines.length; ++i) {
            if (lines[i].indexOf("ARCMENU_BOOKMARK|") !== 0)
                continue;
            var p = lines[i].split("|");
            var uri = (p[1] || "").trim();
            var name = (p[2] || "").trim();
            if (!uri)
                continue;
            if (!name)
                name = uri;
            var path = uri.indexOf("file://") === 0 ? decodeURIComponent(uri.substring(7)) : uri;
            var openCmd = uri.indexOf("file:") === 0 || uri.indexOf("http") === 0
                ? ("kioclient exec " + shellQuote(uri) + " || xdg-open " + shellQuote(uri.indexOf("file:") === 0 ? path : uri))
                : ("xdg-open " + shellQuote(uri));
            items.push({
                id: "bookmark:" + uri,
                name: name,
                icon: uri.indexOf("http") === 0 ? "bookmarks" : "folder",
                exec: openCmd,
                kickerUrl: uri,
                entryPath: uri,
                genericName: path,
                description: path,
                provider: "bookmarks",
                noDisplay: false
            });
        }
        root.bookmarks = items;
        bookmarksUpdated(items);
        if (menuData)
            menuData.bookmarkResults = items;
    }

    function refreshDevices() {
        // computer:/ (KDE4 KIO slave) is gone on Plasma 5/6 — enumerate the
        // mounted removable media instead (/media/$USER, /run/media/$USER).
        var script = [
            "python3 - <<'PY'",
            "import os",
            "u=os.environ.get('USER','')",
            "roots=['/media/'+u if u else '', '/run/media/'+u if u else '']",
            "count=0",
            "for r in roots:",
            "  if not r or not os.path.isdir(r):",
            "    continue",
            "  try:",
            "    names=sorted(os.listdir(r))",
            "  except OSError:",
            "    continue",
            "  for n in names:",
            "    p=os.path.join(r,n)",
            "    if not os.path.isdir(p) or os.path.islink(p):",
            "      continue",
            "    print('ARCMENU_DEVICE|%s|%s' % (p.replace('|','%7C'), n.replace('|','-')))",
            "    count+=1",
            "    if count>=40: break",
            "  if count>=40: break",
            "PY"
        ].join("\n");
        exec.connectSource("/bin/bash -lc " + shellQuote(script));
    }

    function _parseDevices(out) {
        var lines = String(out).split("\n");
        var items = [];
        for (var i = 0; i < lines.length; ++i) {
            if (lines[i].indexOf("ARCMENU_DEVICE|") !== 0)
                continue;
            var p = lines[i].split("|");
            var path = (p[1] || "").trim();
            var name = (p[2] || "").trim();
            if (!path)
                continue;
            if (!name)
                name = path.substring(path.lastIndexOf("/") + 1) || path;
            items.push({
                id: "device:" + path,
                name: name,
                icon: "drive-removable-media",
                exec: "kioclient exec " + shellQuote("file://" + path)
                    + " || xdg-open " + shellQuote(path),
                path: path,
                genericName: path,
                description: path,
                provider: "devices",
                noDisplay: false
            });
        }
        root.devices = items;
        devicesUpdated(items);
        if (menuData)
            menuData.deviceResults = items;
    }

    function uninstall(app) {
        if (!app)
            return;
        var id = String(app.id || "").replace(/\.desktop$/, "");
        exec.connectSource("plasma-discover --mode uninstall --application " + shellQuote(id));
    }
}
