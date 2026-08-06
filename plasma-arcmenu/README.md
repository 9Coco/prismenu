# Arc Menu for KDE Plasma

Feature-rich application menu plasmoid for **KDE Plasma 6**, targeting **Kubuntu** and other Plasma desktops. Provides **14 switchable layouts**, deep appearance customization, favorites/recents, Plasma Search–style app matching, system actions, and a full graphical settings UI.

## Features

- **15 layouts**: Arc Menu, Brisk, Mint, Whisker, Elementary, GNOME, Plasma Dash, Unity Dash, Redmond (Win7), Eleven (Win11), A-Z, Budgie, Kickoff, Kicker, Simple
- **Panel button** with distro auto-detect (Kubuntu-friendly), custom icons, optional label, Meta hotkey, popup animations
- **Browse / search / launch** applications from `.desktop` entries
- **Favorites & recent apps** with optional Plasma global favorites sync flag
- **System actions**: shut down, restart, log out, lock, suspend, hibernate, System Settings, Discover, switch user (with confirmations)
- **Theme engine**: follow Plasma theme or fully custom colors/fonts/radii/icon sizes
- **Category management**: hide, rename, reorder, custom icons
- **Keyboard navigation** and application context menus
- **i18n**: English template + Simplified Chinese and stubs for 20+ locales

## Requirements

- KDE Plasma 6
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
| `arcmenu` | Official ArcMenu (pinned left, places/shortcuts right, search+session bottom) — sources in `layouts/arcmenu/` |
| `brisk` | Solus Brisk (search top, category sidebar left, apps right, session bottom) — sources in `layouts/brisk/` |
| `budgie` | Budgie style (search top, pinned/all/categories left, apps right) — sources in `layouts/budgie/` |
| `gnome` | GNOME style (like Budgie + bottom Activities Overview) — sources in `layouts/gnome/` |
| `mint` | Linux Mint (left icon rail + categories + pinned) — sources in `layouts/mint/` |
| `whisker` | XFCE Whisker (user bar + categories + pinned) — sources in `layouts/whisker/` |
| `eleven` | Windows 11 (pinned grid + recommended + footer) — sources in `layouts/eleven/` |
| `az` | A-Z compact (pinned + alphabetical all apps) — sources in `layouts/az/` |
| `redmond` | Windows 7-like |
| `kickoff` / `kicker` | Plasma native styles |
| `whisker` / `mint` / `brisk` / `budgie` / `gnome` / `elementary` | Traditional Linux menus |
| `plasma-dash` / `unity-dash` / `simple` | Grid / minimal |

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

**Architecture note:** ArcMenu separates **page display** (`ui/pages` + `PageRegistry.js`) from **functional chrome** (sidebar / session / nav in `ui/components`). Layouts only compose the shell; new views are added as pages without rewriting chrome.
## Development checks

```bash
python3 tests/validate_requirements.py
```

## License

GPL-2.0-or-later — see `COPYING`.
