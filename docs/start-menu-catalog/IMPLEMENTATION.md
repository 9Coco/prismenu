# 布局实现映射

菜单布局分为三层：`LayoutRegistry.js` 只声明名称、来源分组、能力和尺寸；共享布局原型负责结构；`LayoutBase`、`MenuData` 与通用组件负责应用、搜索、分类、窗口、收藏和会话动作。新增同类菜单通常只需注册变体，不应复制一套数据逻辑。

| 共享原型 | 变体 |
|----------|------|
| `LayoutRunner.qml` | KRunner、Spotlight、COSMIC Launcher |
| `LayoutDrawer.qml` | GNOME 应用网格、Android、ChromeOS、Launchpad、iPadOS 主屏、DeX、Win11 紧凑网格 |
| `LayoutLibrary.qml` | Win11 分类、iPadOS App Library、COSMIC App Library |
| `LayoutDeepin.qml` | Deepin 窗口/全屏、Cinnamenu 网格 |
| `LayoutOverview.qml` | GNOME 活动概览 |
| `LayoutKickoffCompact.qml` | Plasma Kickoff 紧凑版 |

现阶段的“总览”使用现有窗口模型和应用图标卡片，不伪造窗口实时缩略图；工作区拖放、Runner 计算插件、网页建议、自动学习分类和可编辑文件夹属于后续后台能力。磁贴布局也应等共享网格支持跨行列尺寸后再接入。

`LayoutArcMenu.qml` 是长期使用的经典布局，保持独立，公共原型的扩展不应要求修改它。
