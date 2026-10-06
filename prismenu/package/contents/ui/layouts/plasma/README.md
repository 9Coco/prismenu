# Plasma layouts

## Application Dashboard (`plasma-dash`)

Fullscreen-style three-column launcher matching Plasma’s Application Dashboard:

```
              [ Search… ]
常用应用程序 │ 应用程序 / A–Z / 文件 / 系统操作 │ 最近应用程序
  (3-col grid)│  icon grid                        │ 最近文件
  注销 重启 关机│                                   │ 全部应用程序
              │                                   │ 分类…
              │                                   │ 电源 / 会话
```

Entry: `../LayoutPlasmaDash.qml`

## Tabbed Plasma (`plasma`)

```
┌─ 👤 user ────────────────────────────────┐
│    coco                                  │
│    [Search…]                             │
│ ─────────────────────────────────────── │
│ 文件 / Prismenu 设置 / …                  │
│                                          │
│ ─────────────────────────────────────── │
│ 已固定 │ 应用 │ 电脑 │ 离开              │
└──────────────────────────────────────────┘
```

Entry: `../LayoutPlasma.qml`
