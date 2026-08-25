# Arc Menu for KDE Plasma

A customizable, daily-use application menu plasmoid for **KDE Plasma 6**, maintained for long-term use on **Kubuntu** and other Plasma desktops. It provides **25 switchable layouts**, deep appearance customization, favorites and recent apps, Plasma Search–style app matching, system actions, and a complete graphical settings interface.

The project is intended to be a dependable replacement for Plasma's default application launchers, not only a collection of visual layout recreations. It uses Plasma's native application stack and keeps layouts, shared behavior, and configuration separated so the menu can continue to evolve with Plasma 6.

## Features

- **25 layouts**: Arc Menu, Brisk, Mint, Whisker, Elementary, Plasma, Plasma Dash, Pop, Unity Dash, Unity, Redmond (Win7), Sleek, Tognee, Eleven (Win11), A-Z, Enterprise, Insider, Windows, Zest, Chromebook, Raven, Budgie, Kickoff, Kicker, Simple
- **Panel button** with distro auto-detect (Kubuntu-friendly), custom icons, optional label, Meta hotkey, popup animations
- **Browse / search / launch** applications via **Plasma Kicker** (`org.kde.plasma.private.kicker` → `RootModel` / KService) — same stack as Kickoff
- **Favorites & recent apps** with optional Plasma global favorites sync flag
- **System actions**: shut down, restart, log out, lock, suspend, hibernate, System Settings, Discover, switch user (with confirmations)
- **Theme engine**: follow Plasma theme or fully custom colors/fonts/radii/icon sizes
- **Category management**: hide, rename, reorder, custom icons
- **Keyboard navigation** and application context menus
- **i18n**: English template + Simplified Chinese and stubs for 20+ locales

## Requirements

- KDE Plasma 6 (`plasma-workspace` provides Kicker — no GMenu / Python scan)
- Qt 6 / KF6 (for CMake install)
- Kubuntu 24.04+ / openSUSE KDE / Fedora KDE / Arch / Manjaro KDE (or any Plasma 6 system)

## Quick install (per-user)

```bash
cd plasma-arcmenu
./install.sh
```

Then:

1. Right-click the panel → **Add Widgets** → **Arc Menu**, or
2. Right-click Kickoff → **Show Alternatives** → **Arc Menu**

No Plasma restart required.

## CMake install (system-wide)

```bash
cd plasma-arcmenu
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build
sudo cmake --install build
```

## Configuration

Right-click the Arc Menu button → **Configure Arc Menu…**

Settings categories:

1. **General** – button icon/label, hotkey, animation, multi-instance sharing
2. **Menu Layout** – layout picker, flip, search bar position, width/height
3. **Theme & Appearance** – system/custom theme, colors, fonts, icon sizes
4. **Menu Content** – categories, favorites, recent apps
5. **Search** – providers, placeholder, max results, descriptions
6. **System Actions** – visible power/session actions, confirmations, software center command
7. **About**

A KCM stub is also installed under Workspace behavior for discovery in System Settings.

## Layout notes

| Layout | Style |
|--------|-------|
| `arcmenu` | Official ArcMenu (pinned left, places/shortcuts right, search+session bottom) |
| `brisk` | Solus Brisk (search top, category sidebar left, apps right, session bottom) |
| `budgie` | Budgie style (search top, pinned/all/categories left, apps right) |
| `mint` | Linux Mint (left icon rail + categories + pinned) |
| `whisker` | XFCE Whisker (user bar + categories + pinned) |
| `eleven` | Windows 11 (pinned grid + recommended + footer) |
| `az` | A-Z compact (pinned + alphabetical all apps) |
| `enterprise` | Enterprise (user+search header, category sidebar, pinned grid) |
| `insider` | Insider (centered avatar + 5-col grid + utility rail) |
| `windows` | Windows (rail + frequent/A–Z list + pinned grid) |
| `zest` | Zest 三栏（左地点 / 中分类控制右栏 / 底搜索） |
| `chromebook` | Chromebook（竖长：顶部搜索 + 四列网格） |
| `raven` | Raven（全高左侧栏 + 固定/快捷方式侧板） |
| `elementary` | Elementary（顶部搜索 + 六列应用网格） |
| `plasma` | Plasma (user+search header, list, bottom tabs) |
| `pop` | Pop!_OS (search + 6-col grid + category tabs) |
| `redmond` | Windows-style (4-col grid + places sidebar) |
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
plasma-arcmenu/
├── package/                 # Plasmoid package
│   ├── metadata.json
│   └── contents/
│       ├── config/          # KConfig schema + ConfigModel
│       ├── code/            # JS helpers (layouts, pages, favorites, theme, distro)
│       └── ui/
│           ├── layouts/     # Layout shells (compose chrome + pages)
│           ├── pages/       # Page display modules (home / apps / search / …)
│           ├── components/  # Shared widgets + functional chrome modules
│           └── config/      # Settings pages
├── kcm/                     # System Settings registration stub
├── po/                      # Translations
├── icons/                   # SVG assets
├── tests/                   # Requirement structure checks
├── CMakeLists.txt
├── install.sh
└── COPYING                  # GPL-2.0-or-later
```

**Architecture note:** `code/LayoutRegistry.js` is the single source of layout metadata, including the QML source, preview kind, capabilities, defaults, and sizing policy. All selectable layouts inherit `ui/layouts/LayoutBase.qml`, which owns shared catalog projections, activation behavior, standard categories, and idle-time preloading. Layouts use `LayoutSearchField`, `LayoutAppList`, and `LayoutAppGrid` to inherit data/theme/event wiring while remaining responsible for navigation state, chrome, sizing, and visual composition. Full-catalog sorting and A–Z grouping are computed once in `MenuData.qml`.

To add a normal layout, create `ui/layouts/LayoutName.qml` inheriting `LayoutBase`, then add one metadata object to `LayoutRegistry.js`. The settings preview and structural checks discover the new layout from that object; they do not maintain separate layout-ID lists.

## Development checks

```bash
python3 tests/validate_requirements.py
```

## License

GPL-2.0-or-later — see `COPYING`.
