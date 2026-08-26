#!/usr/bin/env python3
"""Render annotated structural preview mockups for the start-menu catalog.

These are original wireframe-style diagrams (not OS screenshots): they show
region layout, density, and chrome so a Plasma ArcMenu layout can be designed
from them. Chinese labels use WenQuanYi Micro Hei.
"""

from __future__ import annotations

import os
from dataclasses import dataclass

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "previews")
FONT_PATH = "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc"

W, H = 1200, 675

ICON_PALETTE = [
    (88, 166, 255), (255, 138, 91), (110, 201, 130), (186, 148, 255),
    (255, 196, 72), (90, 200, 196), (245, 120, 154), (130, 170, 255),
    (180, 210, 90), (255, 160, 122), (120, 150, 255), (90, 220, 170),
]


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_PATH, size)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def rr(draw: ImageDraw.ImageDraw, box, r, fill=None, outline=None, width=1):
    draw.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)


@dataclass
class Canvas:
    img: Image.Image
    draw: ImageDraw.ImageDraw
    name: str

    @classmethod
    def desktop(cls, name: str, wallpaper=(28, 34, 48), taskbar="bottom",
                taskbar_color=(22, 24, 30), accent=(80, 160, 230)):
        img = Image.new("RGB", (W, H), wallpaper)
        d = ImageDraw.Draw(img, "RGBA")
        # subtle wallpaper orbs
        overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        od.ellipse((-120, -80, 420, 360), fill=(*accent, 28))
        od.ellipse((780, 220, 1380, 820), fill=(40, 80, 120, 40))
        img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
        d = ImageDraw.Draw(img, "RGBA")
        tb = 42
        if taskbar == "bottom":
            d.rectangle((0, H - tb, W, H), fill=taskbar_color + (235,))
            # start orb
            d.ellipse((14, H - tb + 7, 14 + 28, H - 7), fill=accent + (255,))
            d.rectangle((56, H - 18, 220, H - 12), fill=(255, 255, 255, 40))
        elif taskbar == "top":
            d.rectangle((0, 0, W, 36), fill=taskbar_color + (235,))
        elif taskbar == "left":
            d.rectangle((0, 0, 56, H), fill=taskbar_color + (235,))
        elif taskbar == "shelf":
            d.rounded_rectangle((W // 2 - 260, H - 54, W // 2 + 260, H - 10),
                                22, fill=taskbar_color + (230,))
        c = cls(img, d, name)
        return c

    def panel(self, box, r=16, fill=(32, 36, 44, 240), outline=(255, 255, 255, 28), width=1):
        rr(self.draw, box, r, fill=fill, outline=outline, width=width)
        return box

    def label(self, xy, text, size=13, fill=(255, 255, 255, 220), anchor="lt"):
        self.draw.text(xy, text, font=font(size), fill=fill, anchor=anchor)

    def tag(self, x, y, text, bg=(20, 24, 32, 210), fg=(255, 255, 255, 240)):
        f = font(11)
        bbox = self.draw.textbbox((0, 0), text, font=f)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        pad_x, pad_y = 7, 3
        box = (x, y, x + tw + pad_x * 2, y + th + pad_y * 2)
        rr(self.draw, box, 8, fill=bg, outline=(255, 255, 255, 40))
        self.draw.text((x + pad_x, y + pad_y - 1), text, font=f, fill=fg)
        return box

    def search(self, box, placeholder="搜索应用程序…", fill=(255, 255, 255, 22),
               r=10, icon=True):
        rr(self.draw, box, r, fill=fill, outline=(255, 255, 255, 36))
        x0, y0, x1, y1 = box
        cy = (y0 + y1) // 2
        if icon:
            self.draw.ellipse((x0 + 12, cy - 7, x0 + 26, cy + 7), outline=(200, 210, 220, 200), width=2)
        self.label((x0 + (36 if icon else 14), cy), placeholder, 14, (210, 218, 228, 180), "lm")

    def icon_cell(self, cx, cy, s, color, letter="", labeled=None, text_fill=(230, 234, 240, 220)):
        half = s // 2
        rr(self.draw, (cx - half, cy - half, cx + half, cy + half), max(6, s // 5), fill=color + (255,))
        if letter:
            self.draw.text((cx, cy), letter, font=font(max(10, s // 2)), fill=(255, 255, 255, 235), anchor="mm")
        if labeled:
            self.draw.text((cx, cy + half + 10), labeled, font=font(11), fill=text_fill, anchor="mt")

    def grid(self, box, cols, rows, colors=None, letters=None, names=None,
             gap=18, icon=36, with_names=True):
        x0, y0, x1, y1 = box
        colors = colors or ICON_PALETTE
        cell_w = (x1 - x0) / cols
        cell_h = (y1 - y0) / rows
        n = 0
        for r in range(rows):
            for c in range(cols):
                cx = int(x0 + cell_w * (c + 0.5))
                cy = int(y0 + cell_h * (r + 0.5) - (8 if with_names else 0))
                letter = (letters[n] if letters and n < len(letters) else "ABCDEFGHJKLMNPQR"[n % 16])
                name = names[n] if names and n < len(names) else None
                self.icon_cell(cx, cy, icon, colors[n % len(colors)], letter,
                               labeled=name if with_names else None)
                n += 1
        return n

    def list_rows(self, box, count, titles=None, with_icon=True, row_h=34):
        x0, y0, x1, y1 = box
        titles = titles or [f"应用程序 {i + 1}" for i in range(count)]
        for i in range(count):
            y = y0 + i * row_h
            if y + row_h > y1:
                break
            if with_icon:
                col = ICON_PALETTE[i % len(ICON_PALETTE)]
                rr(self.draw, (x0 + 8, y + 6, x0 + 30, y + 28), 5, fill=col + (255,))
                self.label((x0 + 40, y + row_h // 2), titles[i], 13, (230, 234, 240, 220), "lm")
            else:
                self.label((x0 + 12, y + row_h // 2), titles[i], 13, (230, 234, 240, 220), "lm")

    def avatar(self, xy, s=28, fill=(120, 170, 220)):
        x, y = xy
        self.draw.ellipse((x, y, x + s, y + s), fill=fill + (255,))

    def power_dots(self, x, y, n=3, gap=28, fill=(220, 226, 234, 210)):
        glyphs = ["⏻", "⚙", "⏻"] if n == 3 else ["⏻"] * n
        # WenQuanYi may not have all glyphs; draw simple shapes instead
        shapes = ["power", "gear", "user"]
        for i in range(n):
            cx = x + i * gap
            if i == 0:
                self.draw.ellipse((cx, y, cx + 16, y + 16), outline=fill, width=2)
                self.draw.line((cx + 8, y - 1, cx + 8, y + 7), fill=fill, width=2)
            elif i == 1:
                self.draw.ellipse((cx, y, cx + 16, y + 16), outline=fill, width=2)
                self.draw.ellipse((cx + 5, y + 5, cx + 11, y + 11), fill=fill)
            else:
                self.draw.ellipse((cx, y, cx + 16, y + 16), fill=(140, 180, 220, 255))

    def caption(self):
        bar = (0, H - 42, W, H)
        # already have taskbar; put name badge top-left
        self.tag(16, 14, self.name, bg=(12, 14, 20, 210), fg=(240, 246, 255, 245))

    def save(self):
        self.caption()
        path = os.path.join(OUT, f"{self.name}.png")
        self.img.convert("RGB").save(path, "PNG", optimize=True)
        print("wrote", os.path.relpath(path, ROOT))
        return path


# ---------- Windows ----------

def windows_start_win7双栏():
    c = Canvas.desktop("windows-start-win7双栏", wallpaper=(18, 52, 90),
                       taskbar_color=(16, 40, 70), accent=(80, 180, 70))
    p = c.panel((24, 118, 560, 632), r=8, fill=(236, 242, 248, 236), outline=(255, 255, 255, 80))
    # left column
    c.draw.rectangle((32, 128, 300, 560), fill=(248, 250, 252, 255))
    c.tag(40, 136, "固定 / 最近")
    c.list_rows((36, 168, 292, 500), 9,
                ["Internet Explorer", "文档", "图片", "音乐", "游戏",
                 "计算器", "记事本", "画图", "命令提示符"], row_h=36)
    rr(c.draw, (40, 568, 292, 600), 4, fill=(220, 228, 236, 255))
    c.label((166, 584), "所有程序  ▸", 13, (40, 50, 70, 230), "mm")
    # search
    rr(c.draw, (40, 608, 292, 624), 3, fill=(255, 255, 255, 255), outline=(160, 180, 200))
    c.label((48, 616), "搜索程序和文件", 11, (100, 110, 120, 200), "lm")
    c.tag(40, 608 - 18, "搜索")
    # right column places
    c.tag(318, 136, "位置 / 系统")
    places = ["Administrator", "文档", "图片", "音乐", "游戏", "计算机", "控制面板", "设备和打印机"]
    for i, t in enumerate(places):
        y = 168 + i * 42
        c.label((328, y + 10), t, 15, (30, 40, 55, 230), "lt")
    rr(c.draw, (318, 560, 540, 622), 6, fill=(40, 90, 40, 255))
    c.label((360, 591), "关机  ▾", 14, (255, 255, 255, 240), "lm")
    c.tag(430, 568, "会话")
    c.save()


def windows_start_win8全屏磁贴():
    c = Canvas.desktop("windows-start-win8全屏磁贴", wallpaper=(0, 120, 215),
                       taskbar="none", taskbar_color=(0, 0, 0))
    # no taskbar — fill full
    c.draw.rectangle((0, 0, W, H), fill=(0, 120, 215, 255))
    c.label((48, 36), "开始", 28, (255, 255, 255, 240), "lt")
    c.avatar((W - 70, 24), 36)
    c.tag(48, 78, "动态磁贴墙")
    tiles = [
        (48, 120, 220, 220, (0, 99, 177), "邮件"),
        (236, 120, 408, 220, (210, 71, 38), "日历"),
        (424, 120, 768, 220, (0, 130, 114), "天气"),
        (784, 120, 956, 220, (90, 50, 140), "商店"),
        (972, 120, 1144, 220, (16, 124, 16), "Xbox"),
        (48, 236, 220, 420, (200, 80, 0), "照片"),
        (236, 236, 580, 420, (0, 80, 160), "地图"),
        (596, 236, 768, 328, (180, 30, 70), "新闻"),
        (784, 236, 956, 328, (70, 70, 70), "桌面"),
        (972, 236, 1144, 328, (0, 150, 136), "OneNote"),
        (596, 344, 768, 420, (0, 99, 177), "人脉"),
        (784, 344, 1144, 420, (90, 30, 120), "音乐"),
        (48, 436, 220, 532, (0, 130, 114), "视频"),
        (236, 436, 408, 532, (200, 80, 0), "阅读器"),
        (424, 436, 580, 532, (16, 124, 16), "游戏"),
        (596, 436, 768, 532, (0, 99, 177), "SkyDrive"),
        (784, 436, 956, 532, (70, 70, 70), "IE"),
        (972, 436, 1144, 532, (180, 30, 70), "财经"),
    ]
    for x0, y0, x1, y1, col, t in tiles:
        rr(c.draw, (x0, y0, x1, y1), 2, fill=col + (255,))
        c.label(((x0 + x1) // 2, y1 - 22), t, 14, (255, 255, 255, 240), "mm")
    c.tag(48, 548, "全屏 · 磁贴尺寸可变 · 无搜索栏（Charm / 直接打字）")
    c.save()


def windows_start_win10磁贴混合():
    c = Canvas.desktop("windows-start-win10磁贴混合", wallpaper=(16, 22, 32),
                       taskbar_color=(24, 24, 24), accent=(0, 120, 215))
    p = c.panel((18, 70, 980, 632), r=0, fill=(24, 24, 24, 245), outline=(80, 80, 80, 80))
    # left rail
    c.draw.rectangle((18, 70, 70, 632), fill=(18, 18, 18, 255))
    c.tag(18, 78, "图标轨")
    for i, y in enumerate((120, 480, 530, 580)):
        col = ICON_PALETTE[i]
        rr(c.draw, (30, y, 58, y + 28), 4, fill=col + (255,))
    # all apps list
    c.tag(86, 84, "全部应用 A–Z")
    c.list_rows((78, 112, 360, 600), 13,
                ["常用", "报警", "便笺", "设置", "计算器", "相机",
                 "电影和电视", "反馈中心", "邮件", "日历", "画图 3D", "混音器", "边缘"],
                row_h=36)
    # live tiles
    c.tag(392, 84, "动态磁贴")
    tiles = [
        (392, 118, 560, 250, (0, 120, 215), "邮件"),
        (572, 118, 740, 250, (210, 71, 38), "日历"),
        (752, 118, 960, 250, (0, 150, 136), "天气"),
        (392, 262, 560, 394, (16, 124, 16), "Xbox"),
        (572, 262, 740, 328, (90, 50, 140), "商店"),
        (752, 262, 960, 328, (180, 30, 70), "新闻"),
        (572, 340, 740, 394, (70, 70, 70), "照片"),
        (752, 340, 960, 394, (0, 99, 177), "OneNote"),
        (392, 406, 560, 500, (200, 80, 0), "地图"),
        (572, 406, 740, 500, (0, 130, 114), "Groove"),
        (752, 406, 960, 500, (90, 30, 120), "人脉"),
    ]
    for box in tiles:
        x0, y0, x1, y1, col, t = box
        rr(c.draw, (x0, y0, x1, y1), 2, fill=col + (255,))
        c.label((x0 + 12, y1 - 18), t, 13, (255, 255, 255, 240), "lt")
    c.tag(392, 512, "搜索在任务栏，不在菜单内")
    c.save()


def windows_start_win11固定推荐():
    c = Canvas.desktop("windows-start-win11固定推荐", wallpaper=(32, 48, 64),
                       taskbar="shelf", taskbar_color=(32, 36, 44), accent=(80, 160, 230))
    p = c.panel((300, 70, 900, 600), r=20, fill=(40, 44, 52, 242))
    c.search((324, 90, 876, 132), "搜索应用程序、文档等")
    c.tag(324, 142, "已固定")
    c.label((820, 154), "所有应用  ›", 13, (160, 200, 255, 230), "rm")
    names = ["Edge", "Word", "Excel", "设置", "商店", "照片",
             "邮件", "日历", "Spotify", "VS Code", "终端", "计算器"]
    c.grid((330, 168, 870, 360), 6, 2, names=names, icon=40, with_names=True)
    c.tag(324, 380, "推荐")
    rec = ["季度报告.docx", "设计稿.fig", "旅行计划.xlsx", "会议纪要.pdf"]
    for i, t in enumerate(rec):
        x = 340 + (i % 2) * 270
        y = 412 + (i // 2) * 48
        col = ICON_PALETTE[i]
        rr(c.draw, (x, y, x + 28, y + 28), 5, fill=col + (255,))
        c.label((x + 38, y + 14), t, 13, (230, 234, 240, 220), "lm")
    c.avatar((330, 540), 28)
    c.label((368, 554), "Alex", 13, (230, 234, 240, 220), "lm")
    c.power_dots(820, 548, 1)
    c.tag(700, 536, "用户 / 电源")
    c.save()


def windows_start_win11全应用分类():
    c = Canvas.desktop("windows-start-win11全应用分类", wallpaper=(28, 36, 48),
                       taskbar="shelf", taskbar_color=(30, 34, 42), accent=(80, 160, 230))
    p = c.panel((80, 48, 1040, 612), r=20, fill=(38, 42, 50, 244))
    c.search((104, 68, 760, 108), "搜索")
    # view switcher
    rr(c.draw, (780, 72, 1016, 104), 10, fill=(255, 255, 255, 18))
    c.label((898, 88), "分类  ·  网格  ·  列表", 12, (220, 230, 240, 230), "mm")
    c.tag(780, 48, "视图切换")
    cats = [
        ("效率", ["Word", "Excel", "Outlook", "OneNote"], (80, 160, 230)),
        ("创作", ["照片", "Clipchamp", "画图", "录音机"], (255, 138, 91)),
        ("娱乐", ["Spotify", "Xbox", "电影", "新闻"], (186, 148, 255)),
        ("系统", ["设置", "终端", "资源管理器", "计算器"], (110, 201, 130)),
        ("已安装", ["Chrome", "VS Code", "Steam", "Discord"], (255, 196, 72)),
        ("最近", ["Edge", "邮件", "日历", "商店"], (90, 200, 196)),
    ]
    c.tag(104, 120, "分类卡片（常用应用前置）")
    for i, (title, apps, col) in enumerate(cats):
        col_i, row_i = i % 3, i // 3
        x0 = 104 + col_i * 300
        y0 = 148 + row_i * 180
        rr(c.draw, (x0, y0, x0 + 284, y0 + 164), 14, fill=(255, 255, 255, 16))
        c.label((x0 + 14, y0 + 14), title, 15, (240, 244, 250, 240), "lt")
        for j, a in enumerate(apps):
            cx = x0 + 40 + j * 64
            cy = y0 + 88
            c.icon_cell(cx, cy, 36, ICON_PALETTE[(i * 4 + j) % 12], a[0], labeled=a)
    c.avatar((110, 540), 28)
    c.label((148, 554), "Alex", 13, (230, 234, 240, 220), "lm")
    c.power_dots(700, 548, 1)
    # phone sliver
    rr(c.draw, (920, 68, 1024, 560), 14, fill=(255, 255, 255, 14), outline=(255, 255, 255, 30))
    c.tag(920, 76, "手机条")
    c.label((972, 160), "电池 82%", 12, (200, 220, 200, 230), "mm")
    c.label((972, 220), "短信", 12, (200, 210, 230, 200), "mm")
    c.label((972, 280), "照片", 12, (200, 210, 230, 200), "mm")
    c.label((972, 340), "通话", 12, (200, 210, 230, 200), "mm")
    c.save()


def windows_start_win11紧凑网格():
    c = Canvas.desktop("windows-start-win11紧凑网格", wallpaper=(24, 32, 44),
                       taskbar="shelf", taskbar_color=(28, 32, 40), accent=(80, 160, 230))
    p = c.panel((340, 60, 860, 600), r=18, fill=(36, 40, 48, 244))
    c.search((360, 80, 840, 118), "搜索")
    c.tag(360, 128, "全部应用 · 字母网格")
    letters = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ012")
    c.grid((360, 156, 840, 520), 6, 5, letters=letters, icon=34, with_names=False)
    c.avatar((368, 544), 26)
    c.power_dots(790, 550, 1)
    c.tag(500, 540, "无推荐 · 类似应用抽屉")
    c.save()


# ---------- KDE ----------

def kde_plasma_kicker传统菜单():
    c = Canvas.desktop("kde-plasma-kicker传统菜单", wallpaper=(30, 36, 48),
                       taskbar_color=(34, 40, 52), accent=(61, 174, 233))
    p = c.panel((24, 160, 340, 632), r=6, fill=(42, 46, 54, 246))
    c.tag(32, 172, "收藏")
    c.list_rows((28, 200, 328, 340), 4, ["Dolphin", "Konsole", "Firefox", "系统设置"], row_h=34)
    c.draw.line((40, 348, 320, 348), fill=(255, 255, 255, 30), width=1)
    c.tag(32, 356, "分类级联")
    cats = ["互联网", "办公", "图形", "多媒体", "系统", "开发", "工具", "设置"]
    c.list_rows((28, 384, 328, 620), 8, [x + "   ▸" for x in cats], row_h=28)
    # flyout
    c.panel((340, 380, 560, 600), r=6, fill=(48, 52, 62, 246))
    c.tag(352, 392, "子菜单")
    c.list_rows((348, 424, 548, 588), 5, ["Dolphin", "Kate", "KWrite", "Discover", "分区管理"], row_h=30)
    c.save()


def kde_plasma_kickoff经典页签():
    c = Canvas.desktop("kde-plasma-kickoff经典页签", wallpaper=(32, 38, 50),
                       taskbar_color=(36, 42, 54), accent=(61, 174, 233))
    p = c.panel((24, 90, 520, 632), r=10, fill=(44, 48, 58, 246))
    c.search((40, 108, 504, 146), "搜索…")
    c.tag(40, 158, "收藏列表")
    c.list_rows((36, 188, 504, 520), 9,
                ["Firefox", "Dolphin", "Konsole", "系统设置", "Kate",
                 "Okular", "Gwenview", "Discover", "Spectacle"], row_h=36)
    # bottom tabs
    tabs = ["收藏", "应用", "计算机", "历史", "离开"]
    for i, t in enumerate(tabs):
        x0 = 40 + i * 92
        fill = (61, 174, 233, 200) if i == 0 else (255, 255, 255, 16)
        rr(c.draw, (x0, 548, x0 + 84, 612), 8, fill=fill)
        c.label((x0 + 42, 580), t, 12, (240, 246, 255, 240), "mm")
    c.tag(40, 528, "底部分类页签")
    c.save()


def kde_plasma_kickoff标准版():
    c = Canvas.desktop("kde-plasma-kickoff标准版", wallpaper=(28, 34, 46),
                       taskbar_color=(32, 38, 50), accent=(61, 174, 233))
    p = c.panel((24, 80, 620, 632), r=14, fill=(40, 44, 54, 246))
    c.search((40, 98, 600, 138), "搜索应用程序…")
    # main apps
    c.tag(40, 150, "收藏 / 应用网格")
    names = ["Firefox", "Dolphin", "Konsole", "设置", "Kate", "Okular",
             "Gwenview", "Discover", "Spectacle", "Krita", "VLC", "Telegram"]
    c.grid((40, 176, 430, 500), 4, 3, names=names, icon=42)
    # category sidebar RIGHT (Plasma 6 default)
    rr(c.draw, (450, 160, 600, 540), 10, fill=(255, 255, 255, 12))
    c.tag(458, 168, "分类侧栏")
    cats = ["收藏", "全部", "互联网", "办公", "图形", "系统", "开发"]
    for i, t in enumerate(cats):
        y = 200 + i * 42
        if i == 0:
            rr(c.draw, (458, y - 6, 592, y + 26), 8, fill=(61, 174, 233, 80))
        c.label((476, y + 10), t, 13, (230, 236, 244, 230), "lm")
    c.avatar((48, 568), 28)
    c.label((86, 582), "coco", 13, (230, 234, 240, 220), "lm")
    c.power_dots(520, 574, 3)
    c.tag(200, 560, "用户 + 会话")
    c.save()


def kde_plasma_kickoff紧凑版():
    c = Canvas.desktop("kde-plasma-kickoff紧凑版", wallpaper=(26, 32, 44),
                       taskbar_color=(30, 36, 48), accent=(61, 174, 233))
    p = c.panel((24, 140, 420, 632), r=12, fill=(40, 44, 54, 246))
    c.search((40, 156, 404, 192), "搜索")
    c.tag(40, 204, "单列列表 · 无网格")
    c.list_rows((32, 232, 408, 540), 9,
                ["收藏 · Firefox", "Dolphin", "Konsole", "系统设置", "Kate",
                 "互联网 ▸", "办公 ▸", "系统 ▸", "全部应用"], row_h=34)
    c.avatar((40, 572), 24)
    c.power_dots(340, 576, 2)
    c.save()


def kde_plasma_仪表盘全屏():
    c = Canvas.desktop("kde-plasma-仪表盘全屏", wallpaper=(20, 24, 34),
                       taskbar="none")
    c.draw.rectangle((0, 0, W, H), fill=(16, 20, 30, 255))
    # dim overlay already dark
    c.search((360, 36, 840, 80), "搜索应用程序、文件…")
    # left favorites
    rr(c.draw, (40, 110, 280, 620), 14, fill=(255, 255, 255, 12))
    c.tag(52, 122, "常用")
    names = ["Firefox", "Dolphin", "Konsole", "设置", "Kate", "Okular"]
    c.grid((52, 160, 268, 480), 2, 3, names=names, icon=44)
    c.power_dots(70, 560, 3)
    c.tag(52, 530, "会话")
    # center grid
    rr(c.draw, (300, 110, 900, 620), 14, fill=(255, 255, 255, 10))
    c.tag(312, 122, "全部应用")
    c.grid((320, 160, 880, 560), 5, 4, icon=40, with_names=True,
           names=["浏览器", "文件", "终端", "邮件", "音乐",
                  "视频", "图像", "办公", "开发", "游戏",
                  "系统", "设置", "商店", "帮助", "工具", "其他",
                  "聊天", "地图", "笔记", "时钟"])
    # right
    rr(c.draw, (920, 110, 1160, 620), 14, fill=(255, 255, 255, 12))
    c.tag(932, 122, "最近 / 分类")
    c.list_rows((928, 160, 1148, 400), 6, ["最近文档", "最近应用", "全部应用", "互联网", "办公", "系统"], row_h=36)
    c.list_rows((928, 430, 1148, 600), 4, ["关机", "重启", "注销", "锁定"], row_h=34)
    c.save()


def kde_plasma_krunner搜索():
    c = Canvas.desktop("kde-plasma-krunner搜索", wallpaper=(36, 48, 64),
                       taskbar_color=(32, 38, 50), accent=(61, 174, 233))
    p = c.panel((300, 80, 900, 420), r=16, fill=(36, 40, 50, 246))
    c.search((320, 100, 880, 150), "输入以搜索…", r=12)
    c.tag(320, 164, "即时结果 · 插件分类")
    rows = [("应用", "Firefox  浏览器"), ("应用", "Dolphin  文件管理"),
            ("命令", "fire  →  执行"), ("文件", "~/docs/firefox-notes.md"),
            ("网页", "搜索：firefox"), ("计算", "2+2 = 4")]
    for i, (k, t) in enumerate(rows):
        y = 196 + i * 34
        rr(c.draw, (332, y, 390, y + 22), 6, fill=(61, 174, 233, 70))
        c.label((361, y + 11), k, 11, (200, 230, 255, 240), "mm")
        c.label((406, y + 11), t, 13, (230, 234, 240, 230), "lm")
    c.save()


# ---------- GNOME ----------

def gnome_shell_活动概览():
    c = Canvas.desktop("gnome-shell-活动概览", wallpaper=(48, 32, 56),
                       taskbar="top", taskbar_color=(20, 16, 24))
    c.draw.rectangle((0, 0, W, 36), fill=(20, 16, 24, 255))
    c.label((24, 18), "活动", 14, (240, 240, 245, 240), "lm")
    c.search((400, 52, 800, 92), "输入以搜索")
    c.tag(48, 110, "窗口缩略图")
    # window thumbs
    wins = [(80, 140, 420, 380), (440, 140, 760, 300), (440, 316, 760, 480),
            (80, 400, 300, 560)]
    for i, box in enumerate(wins):
        rr(c.draw, box, 10, fill=(30 + i * 8, 28, 40, 230), outline=(255, 255, 255, 40))
        c.label(((box[0] + box[2]) // 2, box[1] + 18), f"窗口 {i + 1}", 12, (220, 220, 230, 200), "mt")
    # dash
    rr(c.draw, (80, 600, 520, 654), 20, fill=(20, 16, 24, 230))
    c.tag(80, 568, "Dash 收藏")
    for i in range(7):
        c.icon_cell(120 + i * 56, 627, 32, ICON_PALETTE[i], "")
    # workspaces
    rr(c.draw, (980, 80, 1170, 640), 12, fill=(255, 255, 255, 10))
    c.tag(990, 92, "工作区")
    for i in range(3):
        y = 140 + i * 150
        rr(c.draw, (1000, y, 1150, y + 120), 8, fill=(40, 30, 50, 220), outline=(255, 255, 255, 30))
        c.label((1075, y + 60), f"工作区 {i + 1}", 12, (220, 220, 230, 200), "mm")
    c.save()


def gnome_shell_应用网格():
    c = Canvas.desktop("gnome-shell-应用网格", wallpaper=(44, 30, 52),
                       taskbar="top", taskbar_color=(20, 16, 24))
    c.search((400, 52, 800, 92), "搜索应用")
    c.tag(80, 110, "分页图标网格 · 可建文件夹")
    names = ["Firefox", "文件", "软件", "设置", "音乐", "视频",
             "照片", "办公", "终端", "帮助", "天气", "时钟",
             "地图", "联系人", "日历", "相机", "邮件", "盒子"]
    c.grid((120, 140, 1080, 520), 6, 3, names=names, icon=48)
    # page dots
    for i in range(3):
        fill = (255, 255, 255, 220) if i == 0 else (255, 255, 255, 70)
        c.draw.ellipse((560 + i * 22, 548, 572 + i * 22, 560), fill=fill)
    c.tag(520, 572, "分页点")
    rr(c.draw, (340, 600, 860, 654), 20, fill=(20, 16, 24, 230))
    for i in range(8):
        c.icon_cell(390 + i * 56, 627, 32, ICON_PALETTE[i], "")
    c.save()


def gnome_classic_传统菜单():
    c = Canvas.desktop("gnome-classic-传统菜单", wallpaper=(40, 44, 40),
                       taskbar="top", taskbar_color=(40, 40, 40))
    c.label((16, 18), "应用程序   位置   系统", 14, (240, 240, 240, 240), "lm")
    p = c.panel((12, 36, 280, 420), r=0, fill=(48, 48, 48, 250))
    c.tag(20, 44, "顶栏级联")
    c.list_rows((16, 76, 272, 400), 9,
                ["收藏 ▸", "附件", "游戏", "图形", "互联网", "办公", "声音与视频", "系统工具", "系统设置"],
                row_h=32)
    c.panel((280, 140, 500, 340), r=0, fill=(52, 52, 52, 250))
    c.tag(292, 148, "子菜单")
    c.list_rows((284, 180, 492, 328), 4, ["Firefox", "Evolution", "Pidgin", "传输"], row_h=32)
    c.save()


# ---------- macOS ----------

def macos_aqua_启动台():
    c = Canvas.desktop("macos-aqua-启动台", wallpaper=(40, 70, 110),
                       taskbar="none")
    # blurred full
    c.draw.rectangle((0, 0, W, H), fill=(50, 80, 120, 255))
    c.search((420, 28, 780, 64), "搜索", r=16, fill=(255, 255, 255, 40))
    c.tag(80, 88, "全屏网格 · 文件夹 · 分页")
    names = ["Safari", "邮件", "地图", "照片", "FaceTime", "日历", "备忘录",
             "提醒", "音乐", "播客", "电视", "新闻", "股市", "语音备忘录",
             "家庭", "快捷指令", "设置", "App Store", "预览", "文本编辑",
             "终端", "活动监视器", "计算器", "词典", "Find My", "Time Machine",
             "图书", "联系人", "信息", "自由表格"]
    c.grid((90, 110, 1110, 560), 7, 4, names=names[:28], icon=46)
    for i in range(4):
        fill = (255, 255, 255, 230) if i == 0 else (255, 255, 255, 70)
        c.draw.ellipse((560 + i * 18, 590, 570 + i * 18, 600), fill=fill)
    # dock
    rr(c.draw, (280, 620, 920, 666), 16, fill=(30, 40, 55, 200))
    for i in range(10):
        c.icon_cell(330 + i * 56, 643, 28, ICON_PALETTE[i], "")
    c.tag(80, 620, "Dock")
    c.save()


def macos_spotlight_搜索():
    c = Canvas.desktop("macos-spotlight-搜索", wallpaper=(70, 90, 120),
                       taskbar="none")
    p = c.panel((320, 90, 880, 470), r=18, fill=(245, 246, 248, 240), outline=(255, 255, 255, 80))
    c.search((340, 108, 860, 156), "Spotlight 搜索", fill=(255, 255, 255, 255), r=12)
    c.tag(340, 168, "应用 / 文件 / 词典 / 计算 / 网页")
    rows = ["Safari", "系统设置", "访达 — 文稿", "计算  128+64 = 192", "定义  start", "网页搜索"]
    for i, t in enumerate(rows):
        y = 196 + i * 40
        if i == 0:
            rr(c.draw, (348, y - 6, 852, y + 30), 8, fill=(0, 122, 255, 40))
        c.icon_cell(372, y + 12, 22, ICON_PALETTE[i], "")
        c.label((396, y + 12), t, 14, (30, 34, 40, 230), "lm")
    c.save()


def macos_dock_程序坞():
    c = Canvas.desktop("macos-dock-程序坞", wallpaper=(80, 120, 160),
                       taskbar="none")
    c.tag(80, 480, "程序坞即启动器 · 放大 · 启动台入口")
    rr(c.draw, (180, 520, 1020, 650), 28, fill=(255, 255, 255, 70), outline=(255, 255, 255, 90))
    sizes = [42, 46, 52, 64, 84, 64, 52, 46, 42, 40, 38, 36]
    x = 220
    for i, s in enumerate(sizes):
        c.icon_cell(x, 600 - s // 6, s, ICON_PALETTE[i % 12], "")
        x += s + 14
    c.label((600, 500), "访达    启动台    Safari    邮件    音乐    系统设置", 13, (255, 255, 255, 210), "mm")
    c.save()


# ---------- ChromeOS ----------

def chromeos_ash_启动器半屏():
    c = Canvas.desktop("chromeos-ash-启动器半屏", wallpaper=(60, 80, 70),
                       taskbar="shelf", taskbar_color=(40, 48, 44), accent=(66, 133, 244))
    p = c.panel((180, 160, 1020, 600), r=22, fill=(32, 36, 34, 240))
    c.search((360, 180, 840, 222), "搜索应用、设置和网页")
    c.tag(200, 180, "继续 / 建议")
    for i in range(5):
        c.icon_cell(250 + i * 70, 270, 36, ICON_PALETTE[i], "", labeled=["Gmail", "文档", "YouTube", "文件", "设置"][i])
    c.tag(200, 320, "应用网格")
    names = ["Chrome", "Play", "Gmail", "地图", "照片", "Keep",
             "日历", "Drive", "Meet", "商店", "相机", "时钟"]
    c.grid((220, 350, 980, 560), 6, 2, names=names, icon=40)
    c.save()


def chromeos_ash_启动器全屏():
    c = Canvas.desktop("chromeos-ash-启动器全屏", wallpaper=(50, 70, 64),
                       taskbar="shelf", taskbar_color=(36, 44, 40), accent=(66, 133, 244))
    c.draw.rectangle((0, 0, W, H - 64), fill=(28, 32, 30, 240))
    c.search((360, 36, 840, 78), "搜索")
    c.tag(80, 100, "全屏抽屉 · 文件夹 · 可分页")
    names = [f"应用{i+1}" for i in range(24)]
    c.grid((100, 130, 1100, 560), 6, 4, names=names, icon=42)
    c.save()


def chromeos_tablet_主屏幕():
    c = Canvas.desktop("chromeos-tablet-主屏幕", wallpaper=(70, 90, 80),
                       taskbar="shelf", taskbar_color=(40, 48, 44), accent=(66, 133, 244))
    c.tag(40, 24, "平板模式：主屏即应用墙（少小部件）")
    names = [f"应用{i+1}" for i in range(20)]
    c.grid((60, 70, 1140, 560), 5, 4, names=names, icon=52)
    c.save()


# ---------- Android / iPad ----------

def android_pixel_应用抽屉():
    c = Canvas.desktop("android-pixel-应用抽屉", wallpaper=(30, 50, 48),
                       taskbar="none")
    c.search((80, 40, 1120, 96), "搜索应用", r=24, fill=(255, 255, 255, 24))
    c.tag(80, 112, "预测行")
    for i, n in enumerate(["电话", "信息", "Chrome", "Gmail", "相机"]):
        c.icon_cell(140 + i * 90, 170, 44, ICON_PALETTE[i], n[0], labeled=n)
    c.tag(80, 230, "A–Z 网格")
    names = ["时钟", "文件", "照片", "YouTube", "地图", "设置",
             "Play", "Drive", "日历", "联系人", "天气", "录音"]
    c.grid((80, 260, 1120, 620), 6, 2, names=names, icon=48)
    c.save()


def android_oneui_应用抽屉():
    c = Canvas.desktop("android-oneui-应用抽屉", wallpaper=(24, 28, 40),
                       taskbar="none")
    c.search((80, 36, 1120, 88), "搜索", r=20)
    c.tag(80, 104, "自定义排序网格 · 分页")
    names = [f"应用{i+1}" for i in range(24)]
    c.grid((80, 140, 1120, 560), 6, 4, names=names, icon=44, with_names=True)
    for i in range(3):
        fill = (255, 255, 255, 220) if i == 0 else (255, 255, 255, 70)
        c.draw.ellipse((560 + i * 20, 600, 572 + i * 20, 612), fill=fill)
    c.save()


def android_dex_桌面启动器():
    c = Canvas.desktop("android-dex-桌面启动器", wallpaper=(20, 24, 36),
                       taskbar_color=(18, 20, 28), accent=(20, 80, 180))
    p = c.panel((24, 80, 640, 632), r=16, fill=(28, 32, 44, 246))
    c.search((44, 100, 620, 140), "搜索应用")
    c.tag(44, 152, "DeX 弹出网格 · 类 Win11")
    names = ["电话", "信息", "Chrome", "文件", "设置", "笔记",
             "相册", "日历", "邮件", "商店", "相机", "时钟",
             "音乐", "视频", "地图", "天气"]
    c.grid((44, 180, 620, 560), 4, 4, names=names, icon=40)
    c.avatar((48, 580), 26)
    c.power_dots(560, 584, 1)
    c.save()


def ipados_主屏幕分页():
    c = Canvas.desktop("ipados-主屏幕分页", wallpaper=(90, 130, 190),
                       taskbar="none")
    c.tag(40, 24, "小组件 + 图标分页")
    rr(c.draw, (40, 70, 430, 520), 24, fill=(255, 255, 255, 40))
    c.label((235, 100), "日历 / 天气 小组件", 16, (255, 255, 255, 230), "mm")
    c.label((235, 280), "11:42", 42, (255, 255, 255, 240), "mm")
    names = ["Safari", "邮件", "文件", "照片", "备忘录", "日历",
             "Keynote", "Pages", "Numbers", "音乐", "TV", "设置"]
    c.grid((460, 70, 1160, 520), 4, 3, names=names, icon=56)
    rr(c.draw, (220, 560, 980, 650), 22, fill=(255, 255, 255, 50))
    c.tag(40, 560, "Dock")
    for i in range(8):
        c.icon_cell(300 + i * 80, 605, 44, ICON_PALETTE[i], "")
    c.save()


def ipados_应用资料库():
    c = Canvas.desktop("ipados-应用资料库", wallpaper=(70, 100, 150),
                       taskbar="none")
    c.search((320, 24, 880, 64), "应用资料库", r=16, fill=(255, 255, 255, 50))
    c.tag(40, 84, "自动分类文件夹墙")
    folders = [
        ("建议", 4), ("最近添加", 4), ("效率", 8), ("娱乐", 8),
        ("社交", 6), ("创意", 6), ("工具", 8), ("其他", 8),
    ]
    for i, (title, n) in enumerate(folders):
        col, row = i % 4, i // 4
        x0 = 40 + col * 290
        y0 = 120 + row * 250
        rr(c.draw, (x0, y0, x0 + 270, y0 + 220), 28, fill=(255, 255, 255, 36))
        # mini icons 2x2
        for j in range(min(4, n)):
            cx = x0 + 70 + (j % 2) * 90
            cy = y0 + 70 + (j // 2) * 70
            c.icon_cell(cx, cy, 40, ICON_PALETTE[(i * 4 + j) % 12], "")
        c.label((x0 + 135, y0 + 200), title, 14, (255, 255, 255, 240), "mm")
    c.save()


def ipados_聚焦搜索():
    c = Canvas.desktop("ipados-聚焦搜索", wallpaper=(80, 110, 160),
                       taskbar="none")
    c.search((280, 80, 920, 140), "聚焦搜索", r=18, fill=(255, 255, 255, 55))
    c.tag(280, 160, "Siri 建议 / 应用 / 文件 / 网页")
    p = c.panel((280, 190, 920, 520), r=18, fill=(255, 255, 255, 40))
    rows = ["Safari", "无边记", "文件 — 设计稿", "快捷指令  开始会议", "网页  start menu"]
    for i, t in enumerate(rows):
        c.icon_cell(330, 230 + i * 52, 28, ICON_PALETTE[i], "")
        c.label((360, 230 + i * 52), t, 16, (255, 255, 255, 235), "lm")
    c.save()


# ---------- Linux desktops ----------

def xfce_whisker_标准版():
    c = Canvas.desktop("xfce-whisker-标准版", wallpaper=(36, 44, 40),
                       taskbar_color=(40, 48, 44), accent=(120, 180, 80))
    p = c.panel((24, 100, 560, 632), r=8, fill=(48, 54, 50, 246))
    c.search((40, 116, 544, 154), "搜索应用程序")
    c.avatar((48, 170), 32)
    c.label((92, 178), "user  @  xfce", 13, (230, 234, 240, 220), "lt")
    c.tag(300, 170, "用户条")
    c.tag(40, 220, "分类")
    cats = ["收藏", "最近", "全部", "附件", "开发", "网络", "办公", "系统"]
    for i, t in enumerate(cats):
        y = 248 + i * 32
        if i == 0:
            rr(c.draw, (40, y - 4, 200, y + 24), 4, fill=(120, 180, 80, 80))
        c.label((52, y + 10), t, 13, (230, 236, 240, 230), "lm")
    c.tag(220, 220, "应用 / 收藏")
    c.list_rows((214, 248, 544, 540), 8,
                ["Firefox", "Thunar", "终端", "Mousepad", "Ristretto", "Parole", "任务管理器", "设置管理器"],
                row_h=34)
    c.power_dots(40, 580, 3)
    c.tag(120, 572, "会话")
    c.save()


def xfce_applicationsmenu_传统级联():
    c = Canvas.desktop("xfce-applicationsmenu-传统级联", wallpaper=(40, 48, 44),
                       taskbar_color=(46, 54, 50), accent=(120, 180, 80))
    p = c.panel((18, 220, 280, 632), r=0, fill=(52, 58, 54, 250))
    c.tag(26, 228, "经典 Applications")
    c.list_rows((22, 260, 272, 620), 10,
                ["收藏 ▸", "最近 ▸", "设置 ▸", "附件", "开发", "教育", "游戏", "图形", "网络", "办公"],
                row_h=32)
    c.panel((280, 260, 500, 500), r=0, fill=(56, 62, 58, 250))
    c.list_rows((284, 280, 492, 488), 5, ["Firefox", "Thunderbird", "Pidgin", "传输", "中转"], row_h=32)
    c.save()


def mint_cinnamon_标准菜单():
    c = Canvas.desktop("mint-cinnamon-标准菜单", wallpaper=(32, 48, 32),
                       taskbar_color=(36, 52, 36), accent=(135, 207, 62))
    p = c.panel((18, 80, 640, 632), r=8, fill=(40, 48, 40, 246))
    c.search((100, 96, 620, 134), "输入以搜索…")
    # icon rail
    c.draw.rectangle((18, 80, 86, 632), fill=(32, 40, 32, 255))
    c.tag(18, 88, "图标轨")
    for i, y in enumerate((140, 190, 240, 480, 530, 580)):
        c.icon_cell(52, y + 12, 24, ICON_PALETTE[i], "")
    c.tag(100, 148, "分类")
    cats = ["收藏", "全部", "互联网", "办公", "图形", "声音和视频", "系统", "偏好"]
    for i, t in enumerate(cats):
        y = 180 + i * 36
        if i == 0:
            rr(c.draw, (100, y - 6, 280, y + 26), 6, fill=(135, 207, 62, 70))
        c.label((112, y + 10), t, 13, (230, 240, 230, 230), "lm")
    c.tag(300, 148, "固定 / 应用")
    c.list_rows((292, 176, 624, 600), 11,
                ["Firefox", "Mint 欢迎", "软件管理器", "更新管理器", "终端",
                 "文件", "文本编辑器", "截图", "系统设置", "Timeshift", "磁盘"],
                row_h=36)
    c.save()


def mint_cinnamenu_网格版():
    c = Canvas.desktop("mint-cinnamenu-网格版", wallpaper=(30, 46, 32),
                       taskbar_color=(34, 50, 34), accent=(135, 207, 62))
    p = c.panel((18, 60, 820, 632), r=10, fill=(40, 48, 40, 246))
    c.search((36, 76, 800, 114), "搜索应用、文件、表情、书签…")
    rr(c.draw, (36, 130, 220, 560), 8, fill=(255, 255, 255, 10))
    c.tag(44, 140, "分类")
    for i, t in enumerate(["收藏", "全部", "文件", "表情", "互联网", "办公", "系统"]):
        y = 176 + i * 44
        c.label((56, y), t, 13, (230, 240, 230, 230), "lm")
    c.tag(240, 140, "应用网格")
    names = ["Firefox", "终端", "文件", "编辑器", "设置", "软件",
             "更新", "截图", "磁盘", "Timeshift", "VLC", "GIMP"]
    c.grid((240, 168, 800, 520), 4, 3, names=names, icon=42)
    c.power_dots(44, 584, 3)
    c.tag(120, 576, "会话可放侧栏或底部")
    c.save()


def ubuntu_unity_dash全屏():
    c = Canvas.desktop("ubuntu-unity-dash全屏", wallpaper=(80, 40, 20),
                       taskbar="left", taskbar_color=(44, 0, 30), accent=(233, 84, 32))
    c.draw.rectangle((56, 0, W, H), fill=(40, 10, 20, 180))
    c.search((200, 40, 1000, 92), "搜索应用、文件、音乐…", r=8, fill=(255, 255, 255, 30))
    c.tag(200, 108, "Lens / Scope 页签")
    for i, t in enumerate(["主页", "应用", "文件", "音乐", "视频", "照片"]):
        x = 200 + i * 100
        fill = (233, 84, 32, 200) if i == 1 else (255, 255, 255, 20)
        rr(c.draw, (x, 128, x + 88, 156), 6, fill=fill)
        c.label((x + 44, 142), t, 12, (255, 255, 255, 240), "mm")
    names = [f"应用{i+1}" for i in range(18)]
    c.grid((180, 180, 1120, 600), 6, 3, names=names, icon=48)
    # launcher
    for i in range(8):
        c.icon_cell(28, 50 + i * 52, 28, ICON_PALETTE[i], "")
    c.tag(8, 470, "启动器")
    c.save()


def ubuntu_unity_启动器侧栏():
    c = Canvas.desktop("ubuntu-unity-启动器侧栏", wallpaper=(90, 50, 24),
                       taskbar="left", taskbar_color=(44, 0, 30), accent=(233, 84, 32))
    c.tag(80, 24, "常驻图标坞 · 运行指示点 · Dash 入口在顶部")
    for i, n in enumerate(["Dash", "Nautilus", "Firefox", "LibreOffice", "终端", "商店", "系统设置", "回收站"]):
        c.icon_cell(28, 48 + i * 58, 32, ICON_PALETTE[i], "")
        c.label((80, 48 + i * 58), n, 14, (255, 255, 255, 220), "lm")
        if i in (2, 3):
            c.draw.ellipse((6, 48 + i * 58 - 4, 14, 48 + i * 58 + 4), fill=(255, 255, 255, 230))
    c.save()


def elementary_pantheon_slingshot窗口():
    c = Canvas.desktop("elementary-pantheon-slingshot窗口", wallpaper=(200, 160, 140),
                       taskbar="top", taskbar_color=(50, 50, 50), accent=(54, 137, 220))
    p = c.panel((260, 50, 940, 560), r=12, fill=(245, 245, 245, 240), outline=(0, 0, 0, 20))
    c.search((280, 68, 780, 108), "搜索应用…", fill=(255, 255, 255, 255), r=8)
    rr(c.draw, (800, 72, 920, 104), 8, fill=(54, 137, 220, 40))
    c.label((860, 88), "分类 ▾", 12, (40, 50, 70, 230), "mm")
    c.tag(280, 120, "六列网格")
    names = ["浏览器", "邮件", "日历", "音乐", "视频", "照片",
             "文件", "终端", "编辑器", "设置", "应用中心", "相机",
             "任务", "邮件", "计算器", "截图", "字体", "系统监视"]
    # dark text labels
    x0, y0, x1, y1 = 280, 150, 920, 500
    cols, rows = 6, 3
    cell_w = (x1 - x0) / cols
    cell_h = (y1 - y0) / rows
    n = 0
    for r in range(rows):
        for col in range(cols):
            cx = int(x0 + cell_w * (col + 0.5))
            cy = int(y0 + cell_h * (r + 0.5) - 8)
            c.icon_cell(cx, cy, 42, ICON_PALETTE[n % 12], names[n][0],
                        labeled=names[n], text_fill=(40, 44, 50, 220))
            n += 1
    for i in range(3):
        fill = (80, 80, 80, 220) if i == 0 else (80, 80, 80, 70)
        c.draw.ellipse((580 + i * 18, 520, 590 + i * 18, 530), fill=fill)
    c.save()


def elementary_pantheon_slingshot全屏():
    c = Canvas.desktop("elementary-pantheon-slingshot全屏", wallpaper=(180, 150, 130),
                       taskbar="top", taskbar_color=(50, 50, 50))
    c.draw.rectangle((0, 36, W, H), fill=(30, 28, 32, 200))
    c.search((360, 60, 840, 104), "搜索", r=10, fill=(255, 255, 255, 24))
    c.tag(80, 120, "全屏 Slingshot")
    names = [f"应用{i+1}" for i in range(24)]
    c.grid((80, 150, 1120, 600), 6, 4, names=names, icon=46)
    c.save()


def budgie_menu_分类列表():
    c = Canvas.desktop("budgie-menu-分类列表", wallpaper=(34, 40, 52),
                       taskbar="top", taskbar_color=(40, 44, 56), accent=(83, 151, 199))
    p = c.panel((16, 44, 560, 620), r=10, fill=(42, 46, 58, 246))
    c.search((32, 60, 544, 100), "搜索")
    c.tag(32, 112, "固定 / 分类")
    for i, t in enumerate(["固定", "全部", "互联网", "办公", "多媒体", "系统"]):
        y = 144 + i * 40
        if i == 0:
            rr(c.draw, (32, y - 6, 200, y + 28), 6, fill=(83, 151, 199, 80))
        c.label((48, y + 10), t, 13, (230, 234, 244, 230), "lm")
    c.tag(220, 112, "应用列表")
    c.list_rows((214, 140, 544, 560), 11,
                ["Firefox", "Nautilus", "终端", "gedit", "设置", "软件",
                 "Rhythmbox", "Totem", "GNOME 截图", "计算器", "磁盘"],
                row_h=36)
    c.avatar((36, 572), 26)
    c.save()


def budgie_raven_侧栏():
    c = Canvas.desktop("budgie-raven-侧栏", wallpaper=(36, 42, 54),
                       taskbar="top", taskbar_color=(40, 44, 56), accent=(83, 151, 199))
    p = c.panel((820, 44, 1184, 660), r=0, fill=(36, 40, 52, 250))
    c.tag(836, 56, "全高 Raven")
    c.label((1000, 100), "10:42", 28, (240, 244, 250, 240), "mm")
    c.label((1000, 136), "星期三  8 月 26 日", 13, (200, 210, 220, 200), "mm")
    rr(c.draw, (844, 170, 1160, 280), 10, fill=(255, 255, 255, 12))
    c.label((1002, 210), "媒体小组件", 14, (220, 226, 234, 200), "mm")
    rr(c.draw, (844, 300, 1160, 430), 10, fill=(255, 255, 255, 12))
    c.label((1002, 350), "通知", 14, (220, 226, 234, 200), "mm")
    c.tag(844, 450, "固定应用 / 快捷方式")
    names = ["文件", "终端", "设置", "软件", "Firefox", "编辑器"]
    c.grid((844, 484, 1160, 640), 3, 2, names=names, icon=36)
    c.save()


def pop_cosmic_启动器搜索():
    c = Canvas.desktop("pop-cosmic-启动器搜索", wallpaper=(24, 28, 40),
                       taskbar="none")
    p = c.panel((280, 80, 920, 520), r=16, fill=(32, 36, 48, 250))
    c.search((300, 100, 900, 150), "输入以启动…", r=12)
    c.tag(300, 164, "打开窗口优先 · 数字快捷键")
    rows = [
        ("1", "Firefox  —  打开的窗口"),
        ("2", "VS Code  —  打开的窗口"),
        ("3", "终端"),
        ("4", "文件"),
        ("5", "COSMIC 设置"),
        ("6", "计算  =  24*3"),
    ]
    for i, (k, t) in enumerate(rows):
        y = 196 + i * 48
        rr(c.draw, (312, y, 888, y + 40), 8, fill=(255, 255, 255, 12 if i else 22))
        rr(c.draw, (324, y + 8, 352, y + 32), 6, fill=(255, 140, 0, 200))
        c.label((338, y + 20), k, 13, (255, 255, 255, 240), "mm")
        c.label((368, y + 20), t, 14, (230, 234, 244, 230), "lm")
    c.save()


def pop_cosmic_应用库():
    c = Canvas.desktop("pop-cosmic-应用库", wallpaper=(22, 26, 38),
                       taskbar="none")
    c.search((360, 36, 840, 80), "搜索应用或商店")
    c.tag(80, 100, "字母网格")
    names = [f"应用{i+1}" for i in range(18)]
    c.grid((80, 130, 1120, 520), 6, 3, names=names, icon=46)
    c.tag(80, 540, "底部分类文件夹")
    folders = ["全部", "办公", "系统", "实用", "游戏", "其他"]
    for i, t in enumerate(folders):
        x = 80 + i * 180
        fill = (255, 140, 0, 180) if i == 0 else (255, 255, 255, 16)
        rr(c.draw, (x, 572, x + 160, 640), 12, fill=fill)
        c.label((x + 80, 606), t, 14, (255, 255, 255, 240), "mm")
    c.save()


def deepin_dde_窗口启动器():
    c = Canvas.desktop("deepin-dde-窗口启动器", wallpaper=(40, 70, 110),
                       taskbar_color=(30, 50, 80), accent=(0, 150, 255))
    p = c.panel((200, 80, 1000, 600), r=16, fill=(245, 247, 250, 240), outline=(255, 255, 255, 80))
    c.search((220, 100, 800, 140), "搜索", fill=(255, 255, 255, 255), r=10)
    c.tag(820, 104, "可拖角变全屏")
    rr(c.draw, (220, 160, 360, 560), 10, fill=(0, 0, 0, 10))
    c.tag(228, 168, "分类")
    for i, t in enumerate(["全部", "互联网", "办公", "视频", "音乐", "游戏", "开发", "系统"]):
        y = 204 + i * 40
        col = (0, 150, 255, 50) if i == 0 else (0, 0, 0, 0)
        rr(c.draw, (228, y - 6, 352, y + 26), 6, fill=col)
        c.label((244, y + 10), t, 13, (40, 50, 70, 230), "lm")
    names = ["浏览器", "文件", "商店", "邮件", "音乐", "电影",
             "相册", "终端", "文本", "设置", "日历", "下载"]
    x0, y0 = 380, 170
    cols, rows = 4, 3
    n = 0
    for r in range(rows):
        for col in range(cols):
            cx = x0 + col * 140 + 50
            cy = y0 + r * 120 + 40
            c.icon_cell(cx, cy, 42, ICON_PALETTE[n], names[n][0],
                        labeled=names[n], text_fill=(40, 44, 52, 220))
            n += 1
    c.save()


def deepin_dde_全屏启动器():
    c = Canvas.desktop("deepin-dde-全屏启动器", wallpaper=(30, 60, 100),
                       taskbar_color=(24, 44, 74), accent=(0, 150, 255))
    c.draw.rectangle((0, 0, W, H - 42), fill=(20, 40, 70, 200))
    c.search((360, 30, 840, 74), "搜索")
    c.tag(80, 90, "全屏网格")
    names = [f"应用{i+1}" for i in range(20)]
    c.grid((80, 120, 1040, 600), 5, 4, names=names, icon=44)
    # letter index
    c.tag(1080, 90, "字母索引")
    for i, ch in enumerate("ABCDEFGH"):
        c.label((1120, 140 + i * 28), ch, 13, (220, 230, 240, 220), "mm")
    c.save()


def render_all():
    os.makedirs(OUT, exist_ok=True)
    fns = [
        windows_start_win7双栏,
        windows_start_win8全屏磁贴,
        windows_start_win10磁贴混合,
        windows_start_win11固定推荐,
        windows_start_win11全应用分类,
        windows_start_win11紧凑网格,
        kde_plasma_kicker传统菜单,
        kde_plasma_kickoff经典页签,
        kde_plasma_kickoff标准版,
        kde_plasma_kickoff紧凑版,
        kde_plasma_仪表盘全屏,
        kde_plasma_krunner搜索,
        gnome_shell_活动概览,
        gnome_shell_应用网格,
        gnome_classic_传统菜单,
        macos_aqua_启动台,
        macos_spotlight_搜索,
        macos_dock_程序坞,
        chromeos_ash_启动器半屏,
        chromeos_ash_启动器全屏,
        chromeos_tablet_主屏幕,
        android_pixel_应用抽屉,
        android_oneui_应用抽屉,
        android_dex_桌面启动器,
        ipados_主屏幕分页,
        ipados_应用资料库,
        ipados_聚焦搜索,
        xfce_whisker_标准版,
        xfce_applicationsmenu_传统级联,
        mint_cinnamon_标准菜单,
        mint_cinnamenu_网格版,
        ubuntu_unity_dash全屏,
        ubuntu_unity_启动器侧栏,
        elementary_pantheon_slingshot窗口,
        elementary_pantheon_slingshot全屏,
        budgie_menu_分类列表,
        budgie_raven_侧栏,
        pop_cosmic_启动器搜索,
        pop_cosmic_应用库,
        deepin_dde_窗口启动器,
        deepin_dde_全屏启动器,
    ]
    for fn in fns:
        fn()


if __name__ == "__main__":
    render_all()
