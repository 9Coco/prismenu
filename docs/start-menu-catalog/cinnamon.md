# Linux Mint Cinnamon

Mint 的默认菜单是「左图标轨 + 分类 + 应用列表 + 搜索」的桌面经典形态，也是 ArcMenu `mint` 布局的来源。社区插件 **Cinnamenu** 把同一壳升级成网格，并塞进文件、表情、书签、计算器，接近「菜单里的 KRunner」。

## 变体一览

| 名称 | 形态 | 现有布局 |
|------|------|----------|
| `mint-cinnamon-标准菜单` | 图标轨+分类+列表 | `mint` |
| `mint-cinnamenu-网格版` | 网格+多源搜索 | `cinnamenu-grid` |

---

## mint-cinnamon-标准菜单

![mint-cinnamon-标准菜单](previews/mint-cinnamon-标准菜单.png)

左窄轨：收藏位置、系统设置、锁屏/注销/关机。中分类（收藏、全部、freedesktop 类）。右应用。搜索多在顶部。固定应用可出现在收藏分类或轨上。

```mermaid
flowchart LR
  Rail["图标轨：位置 / 会话"]
  Cat["分类"]
  Apps["应用列表"]
  Search["搜索"]
  Search --> Rail
  Rail --> Cat --> Apps
```

**功能设计**

- 轨上电源永远可见，解决 Win8 式「找不到关机」。
- 收藏既是分类也是轨图标，新用户先改收藏就能用。
- 搜索覆盖应用名；默认不搜文件。
- 可改成悬停切换分类。

**可借鉴**

- 现有 `mint` 已是此骨架。保持：**轨上会话不被设置页藏掉**、分类与轨职责分离（轨=系统，分类=应用）。

---

## mint-cinnamenu-网格版

![mint-cinnamenu-网格版](previews/mint-cinnamenu-网格版.png)

Cinnamenu：应用可列表可网格；分类里多出「文件」「表情」；搜索模糊匹配，可查家目录、浏览器书签/历史、维基、内置计算器。会话按钮位置可配。

```mermaid
flowchart TB
  Search["模糊搜索（应用/文件/表情/书签/计算）"]
  subgraph Body[""]
    Cat["分类含文件与表情"]
    Grid["应用网格或列表"]
  end
  Session["会话（侧或底）"]
  Search --> Body --> Session
```

**功能设计**

- 菜单变成小型仪表盘：启动只是搜索源之一。
- 表情与文件浏览让菜单驻留时间变长，和「点一下就关」的 Kickoff 哲学不同。
- 专家快捷键：Ctrl+Enter 上下文、Shift+Enter 以 root 运行（Linux 特色，Windows 没有）。

**可借鉴**

- 网格模式可做 `mint` 的显示切换，不必新 id。
- 真正缺的是 **多源搜索**：`SearchExtras.js` 已有扩展点，可加 calculator、emoji、bookmarks。
- root 运行有安全含义，默认不要做，或仅高级选项。
