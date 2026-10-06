# Category icons

Unified **Material Symbols Outlined** icons from [Google Fonts Icons](https://fonts.google.com/icons), shipped as SVG under this folder.

Google LLC's Material Symbols artwork is licensed under **Apache-2.0**.
The 30 category SVG files retain that license; their local filenames and SVG
wrappers are Prismenu adaptations. Each file carries a source and adaptation
notice. See the [complete asset inventory and attribution](../../../THIRD_PARTY_NOTICES.md)
and the [full Apache license](../../../LICENSES/Apache-2.0.txt).

## Naming

`prismenu-cat-{group}-{variant}.svg`

Examples: `prismenu-cat-office-barchart.svg`, `prismenu-cat-tools-build.svg`

## Defaults (left “All Applications” list)

| Category     | Default id                         | Material name   |
|--------------|------------------------------------|-----------------|
| Office       | `prismenu-cat-office-barchart`      | bar_chart       |
| Development  | `prismenu-cat-dev-brush`            | brush           |
| Accessories  | `prismenu-cat-accessories-handyman` | handyman        |
| Utility      | `prismenu-cat-tools-build`          | build           |
| Network      | `prismenu-cat-internet-public`      | public          |
| Graphics     | `prismenu-cat-graphics-image`       | image           |
| System       | `prismenu-cat-system-settings`      | settings        |

Accessories and Utility intentionally use **different** icons (handyman vs wrench).

## Catalog API

See `package/contents/code/CategoryIcons.js`:

- `defaultIcon(categoryId)`
- `optionsFor(categoryId)` — multiple variants for a future custom-icon picker
- `isBundled(iconId)` / `allOptions()`

QML: use `components/ResolvedIcon.qml` (or `ShortcutRow`, which already wraps it).
