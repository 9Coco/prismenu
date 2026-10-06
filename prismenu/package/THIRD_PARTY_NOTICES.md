# Third-party notices

This is the canonical notice file for both the source repository and the
installed Prismenu package. Paths below are relative to this `package/`
directory unless another base is stated. Keep this file, `COPYING`, and
`LICENSES/` with redistributed packages.

Prismenu code is offered under **GPL-2.0-or-later**. That project statement does
not replace the separate artwork terms below or grant trademark rights.
The complete GPL version 2 text is in [COPYING](COPYING). Individual source
notices and the third-party scopes in this file remain applicable.

## KDE Plasma Kickoff helper

Affected file: `contents/code/KickoffTools.js`.

The favorite-action implementation is adapted from KDE Plasma Kickoff's
`applets/kickoff/package/contents/ui/code/tools.js`. Its upstream attribution is:

- Copyright 2013 Aurélien Gâteau <agateau@kde.org>
- Copyright 2013-2015 Eike Hein <hein@kde.org>
- Copyright 2017 Ivan Cukic <ivan.cukic@kde.org>
- Copyright 2022 ivan tkachenko <me@ratijas.tk>
- License: **GPL-2.0-or-later**; full text: [COPYING](COPYING).

Verified source: [KDE Plasma/6.3](https://github.com/KDE/plasma-desktop/blob/462c4f426e9bf683820d1fc04bb7d9ccdc8d90e4/applets/kickoff/package/contents/ui/code/tools.js),
commit `462c4f426e9bf683820d1fc04bb7d9ccdc8d90e4`.
This is the source revision used to verify the notices, not a reconstructed
claim about the exact revision originally consulted.

Prismenu Contributors adapted the helper for this package: the library has
local null guards and action-list handling, an extracted string-prefix helper,
and favorite-model/activity integration. The source header identifies the
adaptation and the date on which the attribution was restored.

## Google Material Symbols Outlined

Attribution: **Google LLC**, Material Symbols Outlined.
License: **Apache-2.0**; full text: [LICENSES/Apache-2.0.txt](LICENSES/Apache-2.0.txt).

Source platform supplied by the maintainer:
[Google Fonts Icons](https://fonts.google.com/icons?icon.size=32&icon.color=%23000000&icon.platform=web).
The local category catalog and settings SVG also identify Google Fonts Icons
as their source. The source project's license is available in
[Google's material-design-icons repository](https://github.com/google/material-design-icons/blob/737e3324305806514d7909874fa1818ae1808232/LICENSE).
That fixed revision was used to verify the license on 2026-10-07; the original
asset download revision was not recorded.

These 31 SVG assets retain Apache-2.0. Their local asset names and SVG
wrappers/currentColor integration are Prismenu adaptations. Each file carries
a source, license, and adaptation comment. The 2026-10-07 attribution update
added comments only; it did not change SVG geometry, colors, or rendering.

| Exact packaged path |
| --- |
| `contents/icons/categories/prismenu-cat-accessories-construction.svg` |
| `contents/icons/categories/prismenu-cat-accessories-handyman.svg` |
| `contents/icons/categories/prismenu-cat-accessories-hardware.svg` |
| `contents/icons/categories/prismenu-cat-av-headphones.svg` |
| `contents/icons/categories/prismenu-cat-av-movie.svg` |
| `contents/icons/categories/prismenu-cat-dev-brush.svg` |
| `contents/icons/categories/prismenu-cat-dev-code.svg` |
| `contents/icons/categories/prismenu-cat-dev-data.svg` |
| `contents/icons/categories/prismenu-cat-dev-terminal.svg` |
| `contents/icons/categories/prismenu-cat-edu-book.svg` |
| `contents/icons/categories/prismenu-cat-edu-school.svg` |
| `contents/icons/categories/prismenu-cat-games-controller.svg` |
| `contents/icons/categories/prismenu-cat-games-esports.svg` |
| `contents/icons/categories/prismenu-cat-graphics-image.svg` |
| `contents/icons/categories/prismenu-cat-graphics-palette.svg` |
| `contents/icons/categories/prismenu-cat-graphics-photo.svg` |
| `contents/icons/categories/prismenu-cat-internet-explore.svg` |
| `contents/icons/categories/prismenu-cat-internet-language.svg` |
| `contents/icons/categories/prismenu-cat-internet-public.svg` |
| `contents/icons/categories/prismenu-cat-office-barchart.svg` |
| `contents/icons/categories/prismenu-cat-office-document.svg` |
| `contents/icons/categories/prismenu-cat-office-work.svg` |
| `contents/icons/categories/prismenu-cat-other-apps.svg` |
| `contents/icons/categories/prismenu-cat-science-flask.svg` |
| `contents/icons/categories/prismenu-cat-system-computer.svg` |
| `contents/icons/categories/prismenu-cat-system-dns.svg` |
| `contents/icons/categories/prismenu-cat-system-settings.svg` |
| `contents/icons/categories/prismenu-cat-tools-build.svg` |
| `contents/icons/categories/prismenu-cat-tools-manufacturing.svg` |
| `contents/icons/categories/prismenu-cat-tools-tune.svg` |
| `contents/icons/prismenu-settings.svg` |

The Apache license and the Google Fonts source above apply to these Material
Symbols assets. They are not a license claim for the unrelated distribution
logos in the next section.

## ArcMenu menu-button artwork

The 118 files in `contents/icons/menu-button/*.svg` were copied from
[ArcMenu](https://gitlab.com/arcmenu/ArcMenu), commit
`2dc07366d7157411a6e48cb101de30cf2c9c5057`, directory
[`data/icons/scalable/actions/`](https://gitlab.com/arcmenu/ArcMenu/-/tree/2dc07366d7157411a6e48cb101de30cf2c9c5057/data/icons/scalable/actions).
The precise file inventory, license/notice scopes, and canonical SHA-256
checksums are in [LICENSES/ARCMENU_ASSET_SOURCES.md](LICENSES/ARCMENU_ASSET_SOURCES.md).

No artwork or SVG markup in these 118 copies was modified by Prismenu. During
the 2026-10-07 attribution update, all 118 copies matched the same-name files in
the official upstream checkout byte-for-byte, and their canonical Git blobs
matched that fixed upstream revision. Git may normalize line endings when
files are checked out on another platform.

### ArcMenu-original artwork: 72 files

Scope: all 72 `contents/icons/menu-button/icon-*.svg` files in the inventory.

Attribution: **AndyC (LinxGem33)**, ArcMenu founder and digital art designer.
The upstream statement credits AndyC for the ArcMenu logo and other ArcMenu
icon assets and licenses them under **CC BY-SA 4.0**. Prismenu preserves this
artwork license; it does not relicense these files under the code license.

- [Original attribution and license statement](https://gitlab.com/arcmenu/ArcMenu/-/raw/2dc07366d7157411a6e48cb101de30cf2c9c5057/README.md)
- [Creator](https://gitlab.com/LinxGem33)
- [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
- [Complete legal text](LICENSES/CC-BY-SA-4.0.txt)

These are unchanged copies. If adapting this artwork, retain its attribution,
identify your changes, and follow the applicable share-alike terms.

### NixOS artwork: 2 files

- `contents/icons/menu-button/distro-nixos.svg`
- `contents/icons/menu-button/distro-nixos-symbolic.svg`

Attribution: **Tim Cuthbertson**, NixOS logo designer.
The same fixed ArcMenu README identifies this artwork as **CC BY 4.0** through
its link to that license. Prismenu makes no further changes to the supplied
copies; any earlier upstream variations remain part of their source record.

- [Source attribution](https://gitlab.com/arcmenu/ArcMenu/-/raw/2dc07366d7157411a6e48cb101de30cf2c9c5057/README.md)
- [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- [Complete legal text](LICENSES/CC-BY-4.0.txt)

### Other distribution and desktop brand artwork: 44 files

Scope: the 44 `distro-*.svg` files in the inventory other than the two NixOS
files. Their directly observed source is the same fixed ArcMenu revision.
The maintainer has previously checked the logos' open-source availability.
This record preserves the observable upstream sources and its brand notices;
it does not assign a new blanket GPL, Apache, or Creative Commons license to
all distribution logos. Brand owners' applicable copyright and trademark
terms remain in effect.

The following notices are retained from that upstream README. Its wording is
preserved, with its copyright-image placeholders rendered as `©`:

> All brand icons are trademarks of their respective owners. The use of these
> trademarks does not indicate endorsement of the trademark holder by ArcMenu
> project, nor vice versa. Please do not use brand logos for any purpose except
> to represent the company, product, or service to which they refer.

- **UBUNTU ©** - Ubuntu name and Ubuntu logo is a trademark of Canonical © Ltd.
- **FEDORA ©** - Fedora and the Infinity design logo are trademarks of Red Hat, Inc.
- **DEBIAN ©** - is a registered trademark owned by Software in the Public Interest, Inc. Debian trademark is a registered United States trademark of Software in the Public Interest, Inc., managed by the Debian project.
- **MANJARO ©** - (logo) and name is a trademark of Manjaro GmbH & Co. KG
- **POP_OS! ©** - Name and (logo) is a trademark of system 76 © Inc.
- **ARCH LINUX ©** - The stylized Arch Linux logo are recognised trademarks of Arch Linux, copyright 2002-2017 Judd Vinet and Aaron Griffin
- **SOLUS** - name and logo is Copyright © 2014-2018 by Solus Project
- **KALI LINUX** - logo and name is part of © OffSec Services Limited 2020
- **PUREOS** - name and logo is developed by members of the Purism community
- **RASPBERRY PI** © - Logo and name is part of Raspberry Pi Foundation UK Registered Charity 1129409
- **Gentoo Authors©** 2001–2020. Gentoo is a trademark of the Gentoo Foundation, Inc.
- **Voyager © Linux** (name) and (logo)
- **MXLinux©** 2020 - Linux - is the registered trademark of Linus Torvalds in the U.S. and other countries.
- **Red Hat, Inc.©** Copyright 2020 (name) and (logo)
- **ZORIN OS** - The "Z" logomark is a registered trademark of Zorin Technology Group Ltd. Copyright © 2019 - 2021 Zorin Technology Group Ltd
- **Pardus** - Pardus is a trademark of the TUBITAK ULAKBIM. Copyright © 2003–2023 TUBITAK ULAKBIM

Prismenu likewise does not imply endorsement or affiliation by these brand
owners. For branded files not individually named in the upstream prose, the
inventory preserves their exact file names and source revision. Their presence
in ArcMenu's source repository is not a separate grant of trademark rights.

## Local Kubuntu preset

The project includes two identical local SVG copies:

- Packaged path: `contents/icons/distro-kubuntu.svg`
- Repository path: `prismenu/icons/distro-kubuntu.svg`

These are separate from the 118 copied ArcMenu assets. Their SVG source is a
project-rendered pictogram used to identify Kubuntu. The project license
statement does not grant rights in Kubuntu's name or branding or imply
endorsement by its owners. They are retained in this attribution update.

## Runtime icons supplied by the desktop

Theme names resolved through KDE, Qt, or the installed icon theme refer to
assets supplied by the user's desktop. This package does not redistribute
those theme files. Those assets retain the terms of their respective authors.
