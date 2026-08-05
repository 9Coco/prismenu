import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "../code/AppsModel.js" as AppsModel

Item {
    id: root

    property var menuData: null
    property bool useDemoFallback: true

    signal appsUpdated(var apps)
    signal metaUpdated(string userName, string userIcon, string osId, string osPretty)

    readonly property string scanScript: "bash -lc " + shellQuote([
        "set +e",
        "ID=$(. /etc/os-release 2>/dev/null; echo ${ID:-linux})",
        "PRETTY=$(. /etc/os-release 2>/dev/null; echo ${PRETTY_NAME:-Linux})",
        "USER=$(id -un 2>/dev/null || echo user)",
        "echo \"__META__|$USER|user-identity|$ID|$PRETTY\"",
        "python3 - <<'PY'",
        "import os, sys",
        "dirs=[]",
        "for d in ['/usr/share/applications','/usr/local/share/applications', os.path.expanduser('~/.local/share/applications')]:",
        "    if os.path.isdir(d): dirs.append(d)",
        "cats_map={'Audio':'AudioVideo','Video':'AudioVideo','AudioVideo':'AudioVideo','Development':'Development','Education':'Education','Science':'Education','Game':'Game','Graphics':'Graphics','Network':'Network','Office':'Office','Settings':'Settings','System':'System','Utility':'Utility','Accessories':'Accessories'}",
        "seen=set()",
        "apps=[]",
        "for d in dirs:",
        "  for name in os.listdir(d):",
        "    if not name.endswith('.desktop'): continue",
        "    path=os.path.join(d,name)",
        "    if name in seen: continue",
        "    seen.add(name)",
        "    data={}",
        "    try:",
        "      with open(path,'r',encoding='utf-8',errors='ignore') as f:",
        "        in_desktop=False",
        "        for line in f:",
        "          line=line.rstrip('\\n')",
        "          if line.startswith('[') and line.endswith(']'):",
        "            in_desktop=(line=='[Desktop Entry]')",
        "            continue",
        "          if not in_desktop or '=' not in line: continue",
        "          k,v=line.split('=',1)",
        "          if k in ('Name','GenericName','Icon','Exec','Categories','Keywords','NoDisplay','Hidden','Type') and k not in data:",
        "            data[k]=v",
        "    except Exception:",
        "      continue",
        "    if data.get('Type','Application') not in ('Application',''): continue",
        "    if str(data.get('Hidden','')).lower()=='true': continue",
        "    if not data.get('Name'): continue",
        "    raw=(data.get('Categories') or '').split(';')",
        "    cats=[]",
        "    for c in raw:",
        "      m=cats_map.get(c)",
        "      if m and m not in cats: cats.append(m)",
        "    if not cats: cats=['Utility']",
        "    keys=[k for k in (data.get('Keywords') or '').split(';') if k]",
        "    execv=(data.get('Exec') or '')",
        "    for tok in ('%f','%F','%u','%U','%i','%c','%k'): execv=execv.replace(tok,'')",
        "    nod=str(data.get('NoDisplay','')).lower()=='true'",
        "    print('|'.join([",
        "      name,",
        "      data.get('Name','').replace('|','/'),",
        "      data.get('GenericName','').replace('|','/'),",
        "      data.get('Icon','application-x-executable').replace('|','/'),",
        "      execv.strip().replace('|','/'),",
        "      ','.join(cats),",
        "      ','.join(keys).replace('|','/'),",
        "      '1' if nod else '0',",
        "      path.replace('|','/')",
        "    ]))",
        "PY"
    ].join("; "))

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            var out = data["stdout"] || "";
            disconnectSource(sourceName);
            if (sourceName.indexOf("__LAUNCH__") === 0 || sourceName.indexOf("__ACTION__") === 0) {
                return;
            }
            handleScan(out);
        }
    }

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function refresh() {
        exec.connectSource(scanScript);
    }

    function handleScan(out) {
        var lines = String(out).split("\n");
        var apps = [];
        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i].trim();
            if (!line) continue;
            if (line.indexOf("__META__|") === 0) {
                var m = line.split("|");
                metaUpdated(m[1] || "user", m[2] || "user-identity", m[3] || "linux", m[4] || "Linux");
                continue;
            }
            var p = line.split("|");
            if (p.length < 9) continue;
            apps.push({
                id: p[0],
                name: p[1],
                genericName: p[2],
                icon: p[3] || "application-x-executable",
                exec: p[4],
                categories: p[5] ? p[5].split(",") : ["Utility"],
                keywords: p[6] ? p[6].split(",") : [],
                noDisplay: p[7] === "1",
                isFavorite: false,
                entryPath: p[8]
            });
        }
        apps = AppsModel.sortAppsByName(AppsModel.filterVisibleApps(apps));
        if (apps.length === 0 && useDemoFallback && menuData) {
            menuData.seedDemoApps();
            appsUpdated(menuData.allApps);
            return;
        }
        appsUpdated(apps);
    }

    function launch(app) {
        if (!app || !app.exec) return;
        exec.connectSource("__LAUNCH__; " + app.exec);
    }

    function runPower(actionId, softwareCenterCmd) {
        var discover = (softwareCenterCmd && softwareCenterCmd !== "auto-detect")
            ? softwareCenterCmd
            : "plasma-discover";
        var map = {
            "lock": "loginctl lock-session || qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock",
            "logout": "qdbus org.kde.Shutdown /Shutdown logout || loginctl terminate-user \"$USER\"",
            "suspend": "systemctl suspend",
            "hibernate": "systemctl hibernate",
            "restart": "systemctl reboot",
            "shutdown": "systemctl poweroff",
            "settings": "systemsettings",
            "discover": discover,
            "switchuser": "qdbus org.kde.ksmserver /KSMServer openSwitchUserDialog || dm-tool switch-to-greeter",
            "accountsettings": "systemsettings kcm_users"
        };
        var cmd = map[actionId];
        if (cmd) {
            exec.connectSource("__ACTION__; " + cmd);
        }
    }

    function addDesktopShortcut(app) {
        if (!app || !app.entryPath) return;
        var cmd = "bash -lc " + shellQuote(
            "dest=\"$HOME/Desktop\"; " +
            "[ -d \"$dest\" ] || dest=\"$HOME/桌面\"; " +
            "[ -d \"$dest\" ] || dest=\"$HOME\"; " +
            "cp " + shellQuote(app.entryPath) + " \"$dest/\" && chmod +x \"$dest/$(basename " + shellQuote(app.entryPath) + ")\""
        );
        exec.connectSource("__ACTION__; " + cmd);
    }

    function editDesktop(app) {
        if (!app || !app.entryPath) return;
        exec.connectSource("__ACTION__; kwriteconfig6 >/dev/null 2>&1; kate " + shellQuote(app.entryPath) + " || kwrite " + shellQuote(app.entryPath));
    }

    function runInTerminal(app) {
        if (!app || !app.exec) return;
        exec.connectSource("__ACTION__; konsole -e bash -lc " + shellQuote(app.exec));
    }

    function uninstall(app) {
        if (!app) return;
        var id = String(app.id || "").replace(/\.desktop$/, "");
        exec.connectSource("__ACTION__; plasma-discover --mode uninstall --application " + shellQuote(id));
    }

    Component.onCompleted: Qt.callLater(refresh)
}
