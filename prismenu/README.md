# Prismenu for KDE Plasma

A customizable application menu plasmoid for **KDE Plasma 6**, with **49 switchable layouts**, appearance customization, favorites and recent apps, Plasma Search–style app matching, system actions, and graphical settings. Kubuntu with Plasma 6 is the primary target; long-term daily use is a project goal.

The project is intended to be a dependable replacement for Plasma's default application launchers, not only a collection of visual layout recreations. It uses Plasma's native application stack and keeps layouts, shared behavior, and configuration separated so the menu can continue to evolve with Plasma 6.

## Features

- **49 layouts** with source-oriented display names, including Solus Brisk, Linux Mint, Xfce Whisker, KDE Plasma, Ubuntu Unity, Budgie, ChromeOS, Windows 7/10/11 variants, and ArcMenu-original layouts
- **Panel button** with distro auto-detect (Kubuntu-friendly), custom icons, optional label, Meta hotkey, popup animations
- **Browse / search / launch** applications via **Plasma Kicker** (`org.kde.plasma.private.kicker` → `RootModel` / KService) — same stack as Kickoff
- **Favorites & recent apps** with optional Plasma global favorites sync flag
- **KDE Places** retain their native icons (Music, Pictures, Videos, Trash, network locations, and bookmarks) in sidebars, icon rails, and settings, including live icon updates; custom shortcut icons remain supported
- **System actions**: shut down, restart, log out, lock, suspend, hibernate, System Settings, Discover, switch user (with confirmations)
- **Theme engine**: follow Plasma theme or fully custom colors/fonts/radii/icon sizes
- **Category management**: hide, rename, reorder, custom icons
- **Keyboard navigation** and application context menus
- **UI languages**: built-in English and Simplified Chinese; gettext templates and stubs for 20+ locales are also included for translation work

## Requirements

- Linux running **KDE Plasma 6**. The package declares Plasma 6.0 as its minimum API version; this is not a claim that every Plasma 6 release or distribution has been tested.
- Runtime QML modules: Plasma Kicker and session management, `org.kde.plasma.plasma5support`, Kirigami, `org.kde.kirigamiaddons.components` (including `Avatar`), KCMUtils, KSvg, KDE Task Manager, and Qt Quick Controls/Dialogs. Install their Plasma 6 / Qt 6 packages using your distribution's package manager; package names vary.
- For CMake installation: CMake 3.16+, ECM 6.0+, Qt 6.6+ development packages (`Core`, `Qml`, `Quick`), KF6 6.0+ development packages (`I18n`, `Package`, `Config`), Plasma 6 development files, gettext tools, and a working build toolchain.

**Kubuntu 24.04 is not a default compatible environment:** its official release ships [Plasma 5.27](https://kubuntu.org/news/kubuntu-24-04-lts-noble-numbat-released/). Use an installation that actually provides Plasma 6 and the runtime modules above. Other Plasma 6 distributions are intended targets, not a verified compatibility matrix.

The repository's Python/JavaScript checks validate source structure and helper behavior. They do not establish native QML loading, successful CMake installation, or behavior on a particular Plasma desktop. Validate those on the target system before relying on a release for daily use.

## Quick install (per-user)

```bash
cd prismenu
./install.sh
```

Then:

1. Right-click the panel → **Add Widgets** → **Prismenu**, or
2. Right-click Kickoff → **Show Alternatives** → **Prismenu**

For a new installation, add the widget through Plasma's widget picker. An already-running instance can retain loaded QML after an update; reopen or reload it when needed.

The installed package includes `COPYING`, `LICENSES/`, and `THIRD_PARTY_NOTICES.md`; see [License and third-party assets](#license-and-third-party-assets).

## CMake install (system-wide)

```bash
cd prismenu
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build
sudo cmake --install build
```

## Configuration

Right-click the Prismenu button → **Configure Prismenu…**

The settings dialog has three project-defined categories, in this order:

1. **Menu** — opens the menu settings hub described below.
2. **General** — language, hotkey, popup animation, shared configuration, activity filtering, backup/import, and reset.
3. **Menu Button** — panel icon and label, icon size, display style, left/middle click actions, and button appearance.

Within **Menu**, the content section links to **Menu Layout**, **Frequent Locations**, **Application Shortcuts**, **Search Options**, **Menu Groups**, **ArcMenu layout adjustment**, and **Power Options**. The appearance section links to **Menu Theme**, **Menu Visual Appearance**, and **Fine-tuning**. Plasma also supplies an **About** page from `metadata.json`.

Configure the installed widget through its context menu. This project does not install a standalone System Settings KCM.

## Layout notes

The layout picker groups menus by source platform, then by desktop
(KDE, GNOME, Windows 7 / 10 / 11, …). Android is registered as a future
source family and appears automatically when its first layout is added.

A catalog of start-menu structures from Windows, Plasma, GNOME, macOS, ChromeOS,
Android, iPadOS, and other desktops — including names, structure diagrams, preview
mockups, and functional design notes — is in
[`docs/start-menu-catalog/`](../docs/start-menu-catalog/README.md). Use it when
adding layouts so new shells follow a real platform pattern instead of another
skin of the same two-column menu.

| Layout | Style |
|--------|-------|
| `arcmenu` | Official ArcMenu (pinned left, places/shortcuts right, search+session bottom) |
| `brisk` | Solus Brisk (search top, category sidebar left, apps right, session bottom) |
| `budgie` | Budgie style (search top, pinned/all/categories left, apps right) |
| `mint` | Linux Mint (left icon rail + categories + pinned) |
| `whisker` | XFCE Whisker (user bar + categories + pinned) |
| `redmond` | Windows 7-inspired two-column menu (grid adaptation + places) |
| `insider` | Early Windows 10 style (account header + app grid + utility rail) |
| `windows` | Windows 10 classic (rail + frequent/A–Z list + pinned tiles) |
| `eleven` | Windows 11 standard (pinned grid + recommended + footer) |
| `az` | Windows 11 compact (pinned grid + alphabetical all apps) |
| `enterprise` | Generic enterprise category sidebar + application grid |
| `zest` | Zest 三栏（左地点 / 中分类控制右栏 / 底搜索） |
| `chromebook` | Chromebook（竖长：顶部搜索 + 四列网格） |
| `raven` | Raven（全高左侧栏 + 固定/快捷方式侧板） |
| `elementary` | Elementary（顶部搜索 + 六列应用网格） |
| `plasma` | Plasma (user+search header, list, bottom tabs) |
| `pop` | Pop!_OS (search + 6-col grid + category tabs) |
| `sleek` | Sleek (pinned grid + avatar sidebar + single power) |
| `tognee` | Tognee (icon rail + categories + bottom search) |
| `kickoff` / `kicker` | Plasma native styles |
| `whisker` / `mint` / `brisk` / `budgie` | Traditional Linux menus |
| `chromebook` / `elementary` / `plasma-dash` / `unity-dash` / `simple` | Grid / minimal |
| `unity` | Unity compact (pinned + shortcuts + bottom places/session) |

All layout sources live in single files contents/ui/layouts/Layout<Name>.qml; the per-layout folders only keep design notes.

Unsupported options for a layout are disabled in settings with an explanatory note.

## Project layout

```
prismenu/
├── package/                 # Plasmoid package
│   ├── metadata.json
│   ├── COPYING              # Full GPL v2 text
│   ├── LICENSES/            # Separate graphics license texts
│   ├── THIRD_PARTY_NOTICES.md
│   └── contents/
│       ├── config/          # KConfig schema + ConfigModel
│       ├── code/            # JS helpers (layouts, pages, favorites, theme, distro)
│       └── ui/
│           ├── layouts/     # Layout shells (compose chrome + pages)
│           ├── pages/       # Page display modules (home / apps / search / …)
│           ├── components/  # Shared widgets + functional chrome modules
│           └── config/      # Settings pages
├── po/                      # Translations
├── icons/                   # SVG assets
├── tests/                   # Requirement structure checks
├── CMakeLists.txt
├── install.sh
└── COPYING                  # Full GPL v2 text
```

**Architecture note:** `code/LayoutRegistry.js` is the single source of layout metadata, including the QML source, preview kind, capabilities, defaults, and sizing policy. All selectable layouts inherit `ui/layouts/LayoutBase.qml`, which owns shared catalog projections, activation behavior, standard categories, and idle-time preloading. Layouts use `LayoutSearchField`, `LayoutAppList`, and `LayoutAppGrid` to inherit data/theme/event wiring while remaining responsible for navigation state, chrome, sizing, and visual composition. Full-catalog sorting and A–Z grouping are computed once in `MenuData.qml`.

To add a normal layout, create `ui/layouts/LayoutName.qml` inheriting `LayoutBase`, then add one metadata object to `LayoutRegistry.js` with a source-platform `category` and a desktop `desktop` (for example `plasma` or `win7`). The settings preview, two-level picker, and structural checks discover the new layout from that object; they do not maintain separate layout-ID lists.

## Development checks

```bash
python3 tests/validate_requirements.py
node tests/test_search_extras.js
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests/qml/tst_place_icons.qml
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests/qml/tst_bundled_icon.qml
```

Adjust the Qt tool path for your distribution. The Places regression uses the
installed KDE Places model and checks native icon identity/rendering, live
updates, theme-name fallbacks, and custom icons without modifying bookmarks.
Bundled icon tint checks require an RHI renderer and are skipped on the Qt
software renderer. Add `QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl` to the
QML test commands to exercise tinting where offscreen OpenGL is available.

## License and third-party assets

Project code is licensed under **GPL-2.0-or-later**. The repository's [root `LICENSE`](../LICENSE), [`COPYING`](COPYING), and [`package/COPYING`](package/COPYING) contain the full GNU GPL version 2 text; the project's licensing declaration permits version 2 or any later version. Preserve upstream copyright and license notices when redistributing modified code.

Bundled graphics have separate license terms. The canonical inventory, source links, attribution, modifications, and exceptions are in [`package/THIRD_PARTY_NOTICES.md`](package/THIRD_PARTY_NOTICES.md). It identifies Material Symbols graphics under Apache-2.0, ArcMenu icons under CC-BY-SA-4.0, and NixOS logos under CC-BY-4.0; the corresponding full texts are in [`package/LICENSES/`](package/LICENSES/). Other distribution logos retain their upstream copyright and trademark notices as recorded in the inventory. Asset license and trademark terms still apply when distributing the GPL-licensed application; a project-wide GPL statement does not replace them.

Both `install.sh` and the CMake `plasma_install_package` route install the `package/` contents, including its `COPYING`, `LICENSES/`, and `THIRD_PARTY_NOTICES.md`. Keep these files in any downloadable plasmoid package or repackaged distribution.
