# 开始菜单布局目录

本目录是 **plasma-arcmenu** 的布局研究库：对照常见桌面 / 平板系统里真正流行过的启动器，拆成可实现的结构，而不是再复述已有的 25 套 ArcMenu 皮肤。

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

## 与现有 25 套布局的缺口

已有实现偏 **ArcMenu 历史皮肤**（Whisker / Eleven / Redmond / Raven …）。下面这些流行形态**还没有对等布局**，按实现价值排序：

| 优先 | 目录名称 | 缺什么 |
|------|----------|--------|
| 高 | `windows-start-win11全应用分类` | 顶层分类卡片 + 分类/网格/列表三视图，不再把「所有应用」藏到二级页 |
| 高 | `gnome-shell-活动概览` | 窗口缩略图 + 工作区条 + Dash，启动器与任务切换合一 |
| 高 | `ipados-应用资料库` | 自动分类大文件夹墙（2×2 预览），不是手动分类侧栏 |
| 高 | `pop-cosmic-启动器搜索` | 打开窗口优先、1–10 数字快捷键、内联计算 |
| 高 | `kde-plasma-krunner搜索` | 居中 Runner，而不是再做一个 Kickoff 变体 |
| 中 | `android-pixel-应用抽屉` | 预测行 + A–Z 网格，平板/触控友好 |
| 中 | `chromeos-ash-启动器半屏` | 从 Shelf 向上长出的半屏抽屉（现有 chromebook 是竖长弹窗） |
| 中 | `deepin-dde-窗口启动器` | 拖角在窗口 ↔ 全屏之间变形 |
| 中 | `windows-start-win8全屏磁贴` | 可变尺寸磁贴墙（Win10 磁贴是弹窗，不是全屏） |
| 中 | `mint-cinnamenu-网格版` | 文件/表情/书签搜索混在同一网格 |
| 低 | `macos-aqua-启动台` | 分页 + 文件夹，和 elementary 全屏接近，可做变体 |
| 低 | `android-dex-桌面启动器` | 与 Win11 弹出网格接近，可复用 eleven/az chrome |

`kickoff` / `kicker` / `plasma-dash` 已经覆盖 Plasma 三条主线；本目录把它们拆成**经典页签 / 标准 / 紧凑 / 仪表盘 / Runner**，方便对照实现细节，而不是再注册五个同名布局。

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
