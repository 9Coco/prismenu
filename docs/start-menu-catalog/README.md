# 开始菜单布局目录

本目录是 **prismenu** 的布局研究库：对照常见桌面 / 平板系统里真正流行过的启动器，拆成可实现的结构，而不是只复述 ArcMenu 历史皮肤。

预览图是**结构示意**（区域、密度、交互重心），不是操作系统截图。可用 `tools/render_previews.py` 重新生成。

## 名称规则

```
平台名称-桌面名称-版本名称
```

例：`kde-plasma-kickoff紧凑版`、`windows-start-win11全应用分类`。

| 段 | 含义 |
|----|------|
| 平台 | 厂商或发行系：`windows` / `kde` / `gnome` / `macos` / `chromeos` / `android` / `ipados` / `xfce` / `mint` / `ubuntu` / `elementary` / `budgie` / `pop` / `deepin` |
| 桌面 | 壳层或启动器家族：`plasma`、`shell`、`start`、`ash`、`whisker`、`cinnamon`、`unity`、`pantheon`、`cosmic`、`dde` … |
| 版本 | 该家族里一个可独立实现的交互变体：`标准版`、`紧凑版`、`全屏磁贴`、`应用资料库` … |

每个桌面一份 Markdown，内含：**结构图、预览图、功能设计、对本项目的可借鉴点**。

## 文档

| 文件 | 桌面 | 变体数 |
|------|------|--------|
| [windows.md](windows.md) | Windows 开始菜单 | 6 |
| [kde.md](kde.md) | KDE Plasma 启动器 | 6 |
| [gnome.md](gnome.md) | GNOME Shell | 3 |
| [macos.md](macos.md) | macOS | 3 |
| [chromeos.md](chromeos.md) | ChromeOS Ash | 3 |
| [android.md](android.md) | Android / One UI / DeX | 3 |
| [ipados.md](ipados.md) | iPadOS | 3 |
| [xfce.md](xfce.md) | Xfce | 2 |
| [cinnamon.md](cinnamon.md) | Linux Mint Cinnamon | 2 |
| [unity.md](unity.md) | Ubuntu Unity | 2 |
| [elementary.md](elementary.md) | elementary OS Pantheon | 2 |
| [budgie.md](budgie.md) | Budgie | 2 |
| [cosmic.md](cosmic.md) | Pop!_OS COSMIC | 2 |
| [deepin.md](deepin.md) | Deepin DDE | 2 |

## 十种结构原型

实现新布局时，先对号入座，再填皮肤。当前仓库里多数布局只覆盖 1–4 类。

| 原型 | 代表 | 一句话 |
|------|------|--------|
| A. 级联菜单 | Kicker、Xfce Applications、GNOME Classic | 分类即子菜单，占位极小 |
| B. 双栏 | Win7、Whisker、Mint 标准 | 左应用 / 右位置或分类 |
| C. 侧栏 + 内容 | Plasma Kickoff、Brisk、Budgie | 分类导航与内容分离 |
| D. 固定网格 + 推荐 | Win11 21H2、Eleven | 先固定，再「所有应用」二级页 |
| E. 列表 + 磁贴混合 | Win10 | 左 A–Z 列表，右动态磁贴 |
| F. 全屏仪表盘 | Plasma Dashboard、Unity Dash、Launchpad | 占满屏幕，浏览优先 |
| G. 全屏总览 | GNOME Overview | **窗口 + 工作区 + Dash** 合一，不是纯应用墙 |
| H. 搜索优先 Runner | KRunner、Spotlight、COSMIC Launcher | 居中搜索条，结果即启动 |
| I. 应用抽屉 | Android、ChromeOS、Win11 紧凑网格 | 字母/分页网格，几乎无 chrome |
| J. 自动分类墙 | iPadOS App Library、Win11 2025 分类视图 | 系统自动把应用打成文件夹/卡片 |

## 实现状态

布局注册表已覆盖本文档中的非磁贴菜单形态。实现按结构原型复用 QML，不为每个名称复制整套菜单代码；映射和维护边界见 [IMPLEMENTATION.md](IMPLEMENTATION.md)。

| 状态 | 目录名称 | 当前实现 |
|------|----------|----------|
| 已接入 | `windows-start-win11全应用分类` | `win11-categories`，分类卡片可进入已有应用分类 |
| 已接入 | `gnome-shell-活动概览` | `gnome-overview`，接入现有窗口激活、搜索和收藏 Dash |
| 已接入 | `ipados-应用资料库` | `ipados-library`，分类卡片墙复用应用分类数据 |
| 已接入 | `pop-cosmic-启动器搜索` / `kde-plasma-krunner搜索` / Spotlight | 共享 Runner 壳，接入现有分组搜索和窗口结果 |
| 已接入 | Android / ChromeOS / Launchpad / iPadOS 主屏 | 共享应用抽屉壳，按预测行、分页点、Dash、会话栏配置变体 |
| 已接入 | Deepin 窗口 / 全屏、Cinnamenu 网格 | 共享分类网格数据，分别提供侧栏或字母索引外形 |
| 暂缓 | Win8 全屏磁贴、Win10 动态磁贴细节 | 需要跨格尺寸、磁贴编辑和动态内容；本轮按要求不实现 |
| 不作为菜单 | macOS Dock、Unity Launcher | 属于常驻任务栏/程序坞，应由 Plasma 面板或任务管理器承担 |

`ArcMenu (Classic)` 继续使用独立的 `LayoutArcMenu.qml`，本轮不修改其结构或行为。

## 交互重心对照

| 用户怎么启动应用 | 典型布局 |
|------------------|----------|
| 打字 | KRunner、Spotlight、COSMIC、GNOME 总览 |
| 点固定图标 | Win11、Launchpad、Dash、Dock |
| 扫分类 | Kickoff、Whisker、Mint、Win11 分类视图 |
| 扫字母表 | Android 抽屉、Win11 网格、COSMIC 应用库 |
| 看最近/推荐 | Win11 推荐、Pixel 预测行、Kickoff 收藏 |
| 先找窗口再找应用 | GNOME Overview、COSMIC Launcher |

新布局至少应明确：**默认打开时眼睛落在哪一块**（搜索、固定、分类、还是窗口）。

## 预览图一览

所有 PNG 在 [`previews/`](previews/)。文件名与布局名称一致。

重新生成：

```bash
pip install Pillow   # 需文泉驿微米黑：fonts-wqy-microhei
python3 docs/start-menu-catalog/tools/render_previews.py
```

## 目录结构

```
docs/start-menu-catalog/
├── README.md                 本索引
├── windows.md … deepin.md    各桌面功能设计
├── previews/                 结构预览图
└── tools/render_previews.py  预览图生成器
```
