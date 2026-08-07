# Raven Layout

ArcMenu Raven / Budgie Raven style — **full-height left icon rail**.

```
┌─▮─┬─ Search… ──────────────────┐
│ ▮ │ 已固定 ─────────────────── │
│ · │ [文件] [ArcMenu 设置]      │
│ · │ 快捷方式 ───────────────── │
│ · │ [软件][设置][优化][活动]   │
│ · │                            │
│ ⚙ │ [添加世界时钟…]            │
└───┴────────────────────────────┘
```

- Left rail spans the **full menu height** (auto-fills `Screen.desktopAvailableHeight` when Raven is active)
- Right: search, pinned, shortcuts, world-clock button
- Rail “apps” icon switches to all-applications list
- Manual override: Configure Arc Menu → Menu Layout → Menu height (up to 1400px)

Entry: `../LayoutRaven.qml`  
Reference: `docs/reference-screenshots/raven/01-target.png`
