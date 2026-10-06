# Raven Layout

ArcMenu Raven / Budgie Raven style — **full-height left icon rail**.

```
┌─▮─┬─ Search… ──────────────────┐
│ ▮ │ 已固定 ─────────────────── │
│ · │ [文件] [Prismenu 设置]      │
│ · │ 快捷方式 ───────────────── │
│ · │ [软件][设置][优化][活动]   │
│ · │                            │
│ ⚙ │ [添加世界时钟…]            │
└───┴────────────────────────────┘
```

- Left rail spans the **full menu height** (auto-fills `Screen.desktopAvailableHeight` when Raven is active; other layouts keep the normal shared height ≤800px)
- Right: search, pinned, shortcuts, world-clock button
- Rail “apps” icon switches to all-applications list
- Shared Menu height in settings stays ≤800px; Raven tall size is runtime-only and does not affect other layouts

Entry: `../LayoutRaven.qml`  
