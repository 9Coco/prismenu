.pragma library

/**
 * Detect distribution logo for the panel button.
 * Reads /etc/os-release style info when available via Plasma,
 * otherwise falls back to KDE branding.
 *
 * Bundled ArcMenu presets live in contents/icons/menu-button/ (see PresetIcons.js).
 */

var DISTRO_ICONS = {
    "kubuntu": "start-here-kubuntu",
    "ubuntu": "start-here-ubuntu",
    "neon": "start-here-kde",
    "fedora": "start-here-fedora",
    "opensuse": "start-here-opensuse",
    "suse": "start-here-opensuse",
    "arch": "start-here-archlinux",
    "manjaro": "start-here-manjaro",
    "debian": "start-here-debian",
    "gentoo": "start-here-gentoo",
    "zorin": "start-here-zorin",
    "linuxmint": "start-here-linuxmint",
    "elementary": "start-here-elementary",
    "solus": "start-here-solus",
    "default": "start-here-kde"
};

/** Curated theme icons shown under “System” in the icon chooser. */
var SYSTEM_ICONS = [
    "start-here",
    "start-here-kde",
    "start-here-kubuntu",
    "start-here-ubuntu",
    "start-here-fedora",
    "start-here-opensuse",
    "start-here-archlinux",
    "start-here-debian",
    "start-here-manjaro",
    "start-here-linuxmint",
    "plasma",
    "applications-all",
    "applications-other",
    "application-menu",
    "dash-launcher",
    "kde",
    "distributor-logo",
    "user-desktop",
    "folder-home",
    "preferences-system",
    "system-run"
];

var BUILTIN_ICONS = [
    { id: "auto-distro", name: "Auto-detect distribution", icon: "start-here" },
    { id: "kde", name: "KDE Logo", icon: "start-here-kde" },
    { id: "plasma", name: "Plasma", icon: "plasma" },
    { id: "applications", name: "Application Grid", icon: "applications-all" },
    { id: "kubuntu", name: "Kubuntu", icon: "start-here-kubuntu" },
    { id: "ubuntu", name: "Ubuntu", icon: "start-here-ubuntu" },
    { id: "fedora", name: "Fedora", icon: "start-here-fedora" },
    { id: "opensuse", name: "openSUSE", icon: "start-here-opensuse" },
    { id: "arch", name: "Arch Linux", icon: "start-here-archlinux" },
    { id: "debian", name: "Debian", icon: "start-here-debian" },
    { id: "custom", name: "Custom icon…", icon: "document-open" }
];

function builtinIcons() {
    return BUILTIN_ICONS.slice();
}

function systemIconNames() {
    return SYSTEM_ICONS.slice();
}

/** Bundled ArcMenu action icons use icon-* / distro-* ids. */
function isPresetIcon(id) {
    var s = String(id || "");
    return s.indexOf("icon-") === 0 || s.indexOf("distro-") === 0;
}

function isSymbolicIcon(id) {
    return String(id || "").indexOf("-symbolic") >= 0;
}

function detectDistroId(osReleaseId, prettyName) {
    var id = String(osReleaseId || "").toLowerCase();
    var pretty = String(prettyName || "").toLowerCase();
    if (id.indexOf("kubuntu") >= 0 || pretty.indexOf("kubuntu") >= 0) {
        return "kubuntu";
    }
    if (DISTRO_ICONS[id]) {
        return id;
    }
    for (var key in DISTRO_ICONS) {
        if (id.indexOf(key) >= 0 || pretty.indexOf(key) >= 0) {
            return key;
        }
    }
    return "default";
}

/**
 * Resolve stored buttonIcon config to a Kirigami.Icon source string.
 * Preset icons return "preset:<id>" — QML must map that to a file URL.
 */
function resolveButtonIcon(buttonIcon, customPath, osReleaseId, prettyName) {
    if (buttonIcon === "custom") {
        if (customPath && customPath.length > 0) {
            return customPath;
        }
        return DISTRO_ICONS[detectDistroId(osReleaseId, prettyName)];
    }
    if (buttonIcon === "auto-distro") {
        return DISTRO_ICONS[detectDistroId(osReleaseId, prettyName)];
    }
    if (isPresetIcon(buttonIcon)) {
        return "preset:" + buttonIcon;
    }
    for (var i = 0; i < BUILTIN_ICONS.length; ++i) {
        if (BUILTIN_ICONS[i].id === buttonIcon) {
            return BUILTIN_ICONS[i].icon;
        }
    }
    if (buttonIcon && String(buttonIcon).length > 0) {
        return buttonIcon;
    }
    return DISTRO_ICONS["default"];
}

/** Whether the panel button should tint the icon (symbolic / mask). */
function buttonIconIsMask(buttonIcon, customPath) {
    if (buttonIcon === "custom") {
        if (customPath && String(customPath).indexOf("-symbolic") >= 0)
            return true;
        return false;
    }
    if (isPresetIcon(buttonIcon)) {
        return isSymbolicIcon(buttonIcon);
    }
    return true;
}

function isLikelyImagePath(path) {
    if (!path) {
        return false;
    }
    var lower = path.toLowerCase();
    return lower.indexOf(".png") >= 0
        || lower.indexOf(".svg") >= 0
        || lower.indexOf(".jpg") >= 0
        || lower.indexOf(".jpeg") >= 0
        || lower.indexOf(".webp") >= 0
        || lower.indexOf("file://") === 0
        || lower.indexOf("/") === 0;
}
