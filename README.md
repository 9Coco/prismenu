# arcMenuOnKde

**Arc Menu for KDE Plasma** is a customizable application launcher for **KDE Plasma 6**. It brings ArcMenu-style flexibility to Plasma through 26 switchable layouts, native Plasma application data, and a complete graphical configuration interface.

This is a long-term, daily-use project rather than a one-off visual prototype. The project prioritizes reliable application launching, native Plasma integration, upgrade compatibility, and a codebase that can be maintained as Plasma evolves. Kubuntu is the primary target environment, while other Plasma 6 distributions are supported where practical.

See [`plasma-arcmenu/README.md`](plasma-arcmenu/README.md) for install, configuration, and development details.

## Project goals

- Provide a dependable replacement for Plasma's default application launchers.
- Offer multiple familiar menu styles without sacrificing native Plasma behavior.
- Keep configuration, favorites, search, session actions, and application data integrated with Plasma.
- Favor maintainable shared components over layout-specific duplication.
- Validate changes against real daily desktop use and supported Plasma 6 environments.

## Quick start

```bash
cd plasma-arcmenu
./install.sh
python3 tests/validate_requirements.py
```

Install and restart Plasma Shell in one command when a restart is needed:

```bash
cd plasma-arcmenu
./install.sh && plasmashell --replace &
```
