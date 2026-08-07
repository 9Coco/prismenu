.pragma library

/**
 * Built-in UI language packs for Arc Menu.
 * Plasma gettext (.mo) is not required; language is selected in General settings.
 */

var ZH_CN = {
    "Accessories": "附件",
    "Account Settings": "账户设置",
    "Activities Overview": "活动概况",
    "Add to Desktop": "添加到桌面",
    "Add to Favorites": "添加到收藏",
    "Add to Panel": "添加到面板",
    "Add world clock…": "添加世界时钟…",
    "All Applications": "所有应用程序",
    "All apps": "全部应用",
    "All apps A-Z": "全部应用 A-Z",
    "Alternative Menu Layouts": "选择菜单布局",
    "Appearance": "外观",
    "Application Details": "应用详细信息",
    "Application menu with switchable layouts": "支持多种可切换布局的应用菜单",
    "Applications": "应用",
    "Arc Menu": "Arc Menu",
    "Arc Menu for KDE Plasma": "KDE Plasma 版 Arc Menu",
    "ArcMenu Settings": "ArcMenu 设置",
    "Are you sure you want to log out?": "确定要注销吗？",
    "Are you sure you want to restart the computer?": "确定要重新启动计算机吗？",
    "Are you sure you want to shut down the computer?": "确定要关闭计算机吗？",
    "Back": "返回",
    "Browse…": "浏览…",
    "Button icon:": "按钮图标：",
    "Categories": "分类",
    "Chinese (Simplified)": "简体中文",
    "Clear Recent Applications": "清空最近使用的应用",
    "Computer": "电脑",
    "Configure Arc Menu": "配置 Arc Menu",
    "Configure Arc Menu…": "配置 Arc Menu…",
    "Confirm": "确认",
    "Credits": "致谢",
    "Current Menu Layout": "当前菜单布局",
    "Custom icon path:": "自定义图标路径：",
    "Development": "编程",
    "Devices": "设备",
    "Discover": "Discover",
    "Do you want to continue?": "是否继续？",
    "Documents": "文档",
    "Downloads": "下载",
    "Edit Application…": "编辑应用…",
    "Education": "教育",
    "English": "English",
    "Failed to load layout: %1": "无法加载布局：%1",
    "Favorites": "收藏",
    "File Manager": "文件管理器",
    "Files": "文件",
    "Follow system": "跟随系统",
    "Frequent": "常用",
    "Frequent apps": "常用应用程序",
    "Games": "游戏",
    "General": "通用",
    "Graphics": "图形",
    "Hibernate": "休眠",
    "Hide categories": "隐藏分类",
    "Home": "主目录",
    "Home folder": "主文件夹",
    "Internet": "互联网",
    "Launch": "启动",
    "Launcher Menu Layouts": "启动器菜单布局",
    "Leave": "离开",
    "Library Home": "程序库主页",
    "License: GPL-2.0-or-later": "许可证：GPL-2.0-or-later",
    "Lock": "锁定",
    "Lock Screen": "锁定屏幕",
    "Log Out": "注销",
    "Menu Content": "菜单内容",
    "Menu Layout": "菜单布局",
    "Menu height:": "菜单高度：",
    "Menu hotkey:": "菜单快捷键：",
    "Menu language:": "菜单语言：",
    "Menu width:": "菜单宽度：",
    "Modern Menu Layouts": "现代菜单布局",
    "Multimedia": "多媒体",
    "Music": "音乐",
    "No applications": "暂无应用",
    "No matching applications found": "未找到匹配的应用",
    "Office": "办公",
    "Overview": "概览",
    "Pictures": "图片",
    "Pin applications from the context menu": "从右键菜单固定应用",
    "Pinned": "已固定",
    "Pinned Applications": "固定应用程序",
    "Pinned applications": "固定应用",
    "Places": "位置",
    "Power": "电源",
    "Power Off": "关机",
    "Programming": "编程",
    "Recent": "最近",
    "Recommended": "推荐",
    "Remove from Favorites": "从收藏移除",
    "Restart": "重启",
    "Results": "结果",
    "Root": "根目录",
    "Run in Terminal": "以终端运行",
    "Search": "搜索",
    "Search applications…": "搜索应用…",
    "Search results": "搜索结果",
    "Search…": "搜索…",
    "Select a new menu layout?": "选择新的菜单布局？",
    "Session": "会话",
    "Settings": "设置",
    "Shortcuts": "快捷方式",
    "Show Details": "显示详细信息",
    "Show categories": "显示分类",
    "Show text label:": "显示文字标签：",
    "Shut Down": "关机",
    "Software": "软件",
    "Software Center": "软件中心",
    "Suspend": "挂起",
    "Switch User": "切换用户",
    "System": "系统",
    "System Actions": "系统操作",
    "System Settings": "系统设置",
    "System Tools": "系统工具",
    "Terminal": "终端",
    "Theme & Appearance": "主题与外观",
    "Tools": "工具",
    "Touch Menu Layouts": "触摸菜单布局",
    "Traditional Menu Layouts": "传统菜单布局",
    "Tweaks": "优化",
    "Type to search applications": "输入以搜索应用",
    "UI language applies to menu labels (categories, places, actions).": "界面语言作用于菜单文案（分类、位置、操作等）。",
    "Uninstall…": "卸载…",
    "User": "用户",
    "User account": "用户帐户",
    "Utilities": "工具",
    "Utility Tools": "实用工具",
    "Version %1": "版本 %1",
    "Videos": "视频",
    "About": "关于"
};

var STRINGS = {
    en: {},
    zh_CN: ZH_CN
};

function availableLanguages() {
    return [
        { id: "system", name: "Follow system" },
        { id: "en", name: "English" },
        { id: "zh_CN", name: "Chinese (Simplified)" }
    ];
}

/**
 * Resolve configured preference to an active pack id ("en" | "zh_CN").
 * systemLocaleName: e.g. Qt.locale().name → "zh_CN"
 * uiLanguages: optional Qt.locale().uiLanguages array
 */
function resolveLanguage(pref, systemLocaleName, uiLanguages) {
    if (pref === "en" || pref === "zh_CN") {
        return pref;
    }
    var loc = (systemLocaleName || "").toString().replace(/\.UTF-8$/i, "").replace(/-/g, "_");
    if (loc.toLowerCase().indexOf("zh") === 0) {
        return "zh_CN";
    }
    // Plasma sometimes reports en_US for name while uiLanguages still lists zh
    if (uiLanguages && uiLanguages.length !== undefined) {
        for (var i = 0; i < uiLanguages.length; ++i) {
            var u = ("" + uiLanguages[i]).toLowerCase().replace(/-/g, "_");
            if (u.indexOf("zh") === 0) {
                return "zh_CN";
            }
        }
    }
    return "en";
}

function tr(msgid, lang) {
    if (!msgid) {
        return "";
    }
    if (!lang || lang === "en") {
        return msgid;
    }
    var pack = STRINGS[lang];
    if (pack && pack[msgid] !== undefined) {
        return pack[msgid];
    }
    return msgid;
}

function trf(msgid, lang, arg1) {
    var s = tr(msgid, lang);
    if (arg1 === undefined || arg1 === null) {
        return s;
    }
    return s.replace("%1", arg1);
}
