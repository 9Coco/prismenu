# Category icons

Unified **Material Symbols Outlined** icons from [Google Fonts Icons](https://fonts.google.com/icons), shipped as SVG under this folder.

## Naming

`arcmenu-cat-{group}-{variant}.svg`

Examples: `arcmenu-cat-office-barchart.svg`, `arcmenu-cat-tools-build.svg`

## Defaults (left “All Applications” list)

| Category     | Default id                         | Material name   |
|--------------|------------------------------------|-----------------|
| Office       | `arcmenu-cat-office-barchart`      | bar_chart       |
| Development  | `arcmenu-cat-dev-brush`            | brush           |
| Accessories  | `arcmenu-cat-accessories-handyman` | handyman        |
| Utility      | `arcmenu-cat-tools-build`          | build           |
| Network      | `arcmenu-cat-internet-public`      | public          |
| Graphics     | `arcmenu-cat-graphics-image`       | image           |
| System       | `arcmenu-cat-system-settings`      | settings        |

Accessories and Utility intentionally use **different** icons (handyman vs wrench).

## Catalog API

See `package/contents/code/CategoryIcons.js`:

- `defaultIcon(categoryId)`
- `optionsFor(categoryId)` — multiple variants for a future custom-icon picker
- `isBundled(iconId)` / `allOptions()`

QML: use `components/ResolvedIcon.qml` (or `ShortcutRow`, which already wraps it).
