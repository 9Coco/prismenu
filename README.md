# arcMenuOnKde

**Arc Menu for KDE Plasma** 是一个可定制的 **KDE Plasma 6** 应用程序启动器。它通过 26 种可切换的布局、原生 Plasma 应用数据以及完整的图形化配置界面，为 Plasma 带来了 ArcMenu 风格的灵活性。

这是一个长期日常使用的项目，而非一次性的视觉原型。项目优先考虑可靠的应用程序启动、原生 Plasma 集成、升级兼容性，以及能够随 Plasma 演进而持续维护的代码库。Kubuntu 是主要目标环境，同时也尽实际可能支持其他 Plasma 6 发行版。

安装、配置和开发细节请参阅 [`plasma-arcmenu/README.md`](plasma-arcmenu/README.md)。

布局研究（结构图、名称、预览以及主流桌面/平板开始菜单的功能设计）位于 [`docs/start-menu-catalog/`](docs/start-menu-catalog/README.md)。

## 项目目标

- 为 Plasma 默认的应用程序启动器提供一个可靠的替代方案。
- 提供多种熟悉的菜单风格，同时不牺牲原生 Plasma 行为。
- 保持配置、收藏夹、搜索、会话操作和应用程序数据与 Plasma 集成。
- 优先使用可维护的共享组件，而非各布局重复造轮子。
- 在真实的日常桌面使用和支持的 Plasma 6 环境中验证更改。

## 快速开始

```bash
cd plasma-arcmenu
./install.sh
python3 tests/validate_requirements.py
```

如需重启，可使用一条命令完成安装并重启 Plasma Shell：

```bash
cd plasma-arcmenu
./install.sh && plasmashell --replace &
```
