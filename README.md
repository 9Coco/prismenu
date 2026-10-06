# Prismenu

**Prismenu for KDE Plasma** 是一个可定制的 **KDE Plasma 6** 应用程序启动器。它通过 49 种可切换的布局、原生 Plasma 应用数据以及完整的图形化配置界面，为 Plasma 带来了 ArcMenu 风格的灵活性。

项目以长期日常使用为目标，优先考虑可靠的应用程序启动、原生 Plasma 集成、升级兼容性，以及能够随 Plasma 演进而持续维护的代码库。搭载 Plasma 6 的 Kubuntu 是主要目标环境；其他 Plasma 6 发行版也属于适配目标。

安装、配置和开发细节请参阅 [`prismenu/README.md`](prismenu/README.md)。

布局研究（结构图、名称、预览以及主流桌面/平板开始菜单的功能设计）位于 [`docs/start-menu-catalog/`](docs/start-menu-catalog/README.md)。

## 项目目标

- 为 Plasma 默认的应用程序启动器提供一个可靠的替代方案。
- 提供多种熟悉的菜单风格，同时不牺牲原生 Plasma 行为。
- 保持配置、收藏夹、搜索、会话操作和应用程序数据与 Plasma 集成。
- 优先使用可维护的共享组件，而非各布局重复造轮子。
- 在真实的日常桌面使用和支持的 Plasma 6 环境中验证更改。

## 快速开始

需要实际运行 **KDE Plasma 6**，并安装项目使用的 Qt 6 / KDE QML 模块。Kubuntu 24.04 默认搭载 [Plasma 5.27](https://kubuntu.org/news/kubuntu-24-04-lts-noble-numbat-released/)，不能直接视为兼容环境。具体依赖与安装方式见 [`prismenu/README.md`](prismenu/README.md#requirements)。

```bash
cd prismenu
./install.sh
python3 tests/validate_requirements.py
```

安装后，在面板上右键 → **添加部件** → **Prismenu**。设置入口是部件的右键菜单 → **配置 Prismenu…**，包含「菜单」「通用」「菜单按钮」三个分类；Plasma 另外提供「关于」页。项目没有独立的系统设置 KCM。

已有部件在更新后可能仍使用已加载的 QML。开发调试时，可使用脚本安装并替换 Plasma Shell，同时记录日志：

```bash
cd prismenu
./reload.sh
```

仓库的 Python / JavaScript 检查验证源码结构与辅助逻辑，不代表已完成原生 QML 加载、CMake 安装或各发行版桌面测试。发布前应在目标 Plasma 环境中验证实际功能；当前没有据此承诺跨发行版兼容矩阵。

## 许可证与第三方资源

项目代码采用 **GPL-2.0-or-later**，完整 GPL v2 文本见根目录 [`LICENSE`](LICENSE)。第三方图形资源保留各自的许可证，不能用项目的 GPL 声明代替；来源、作者、修改与许可范围统一记录在 [`prismenu/package/THIRD_PARTY_NOTICES.md`](prismenu/package/THIRD_PARTY_NOTICES.md)，独立图形许可文本位于 [`prismenu/package/LICENSES/`](prismenu/package/LICENSES/)。发行版标识另保留上游的版权与商标说明。

每种安装方式都会随部件安装 `package/COPYING`、`package/LICENSES/` 和 `package/THIRD_PARTY_NOTICES.md`。打包发布时应保留这些文件。完整说明见 [`prismenu/README.md`](prismenu/README.md#license-and-third-party-assets)。
