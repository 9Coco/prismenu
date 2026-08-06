# Reference screenshots（目标效果图）

对话中提供的 ArcMenu / Brisk / Budgie 参考图与过程截图，供后续布局对照。

## 目录

```
docs/reference-screenshots/
├── arcmenu/     # ArcMenu 官方布局 — 目标效果
├── brisk/       # Brisk 布局 — 目标效果
├── budgie/      # Budgie 布局 — 目标效果
├── gnome/       # GNOME 布局 — 目标效果
├── mint/        # Mint 布局 — 目标效果
├── whisker/     # Whisker 布局 — 目标效果
└── progress/    # 开发过程中的「当前实现」截图（非目标）
```

## 目标效果（targets）

| 布局 | 文件 | 说明 |
|------|------|------|
| ArcMenu | `arcmenu/01-official-target.png` | 首张官方布局效果图 |
| ArcMenu | `arcmenu/02-official-target.png` | 官方布局效果图（对照用） |
| ArcMenu | `arcmenu/03-official-target.png` | 官方布局效果图（对照用） |
| Brisk | `brisk/01-target.png` | Brisk 完整效果（含软件/设置/电源） |
| Brisk | `brisk/02-target-with-categories.png` | Brisk 含分类与固定应用内容 |
| Budgie | `budgie/01-target.png` | Budgie 效果（固定/分类，无底栏电源） |
| GNOME | `gnome/01-target.png` | GNOME 效果（固定/分类 + 底栏活动概况） |
| Mint | `mint/01-target.png` | Mint 效果（左侧图标栏 + 分类 + 固定应用） |
| Whisker | `whisker/01-target.png` | Whisker 效果（搜索 + 用户栏 + 分类/内容） |

## 过程截图（progress）

仅作历史对照，**不是**目标样式：

| 文件 | 说明 |
|------|------|
| `progress/arcmenu-wip-incomplete-sidebar.png` | 侧栏未齐 |
| `progress/arcmenu-wip-missing-places.png` | Places 缺失 |
| `progress/black-box-qml-load-failure.png` | QML 加载失败黑框 |
| `progress/layout-switch-stuck-on-arcmenu.png` | 布局切换未生效 |
| `progress/brisk-wip-empty-pinned.png` | Brisk 固定区为空 |

实现某布局时，以对应 `*/0x-*.png` 目标图为准。
