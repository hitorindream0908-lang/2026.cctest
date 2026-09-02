# -*- coding: utf-8 -*-
"""
定年後のお父さん 一言LINEスタンプ ジェネレーター
共通の「お父さん」キャラを描き、表情・ポーズ・一言を差し替えて
LINEスタンプ規格(370x320, 透過)のSVGを書き出す。
"""
import os

W, H = 370, 320
HEAD_CX, HEAD_CY = 185, 118
HEAD_RX, HEAD_RY = 60, 63

# --- 配色 -------------------------------------------------------------
SKIN      = "#f7d7bd"
SKIN_SH   = "#efc3a2"   # 影
HAIR      = "#c9cbd1"   # 白髪グレー
HAIR_SH   = "#b0b3bb"
GLASS     = "#6b5847"   # メガネフレーム(茶)
SHIRT     = "#5aa0a0"   # ポロシャツ(落ち着いたティール)
SHIRT_SH  = "#4c8b8b"
COLLAR    = "#eef3f3"
LINE_C    = "#5b4a3d"   # 顔の線(こげ茶)
BLUSH     = "#f6a98f"
TEXT_C    = "#43423f"
TEXT_HALO = "#ffffff"
ACCENT    = "#ef8a7a"   # ハートなど

FONT = "'IPAPGothic','IPAGothic','Noto Sans CJK JP',sans-serif"


# --- パーツ描画 -------------------------------------------------------
def hair():
    # 薄くなった白髪：両サイドともみあげ＋てっぺんに少しの毛
    return f'''
  <path d="M126,118 Q118,72 150,58 Q140,74 138,96 Q131,104 126,118 Z" fill="{HAIR}"/>
  <path d="M244,118 Q252,72 220,58 Q230,74 232,96 Q239,104 244,118 Z" fill="{HAIR}"/>
  <path d="M150,64 Q185,50 220,64 Q205,58 185,58 Q165,58 150,64 Z" fill="{HAIR}"/>
  <path d="M132,108 Q128,88 140,74 Q136,92 138,110 Z" fill="{HAIR_SH}"/>
  <path d="M238,108 Q242,88 230,74 Q234,92 232,110 Z" fill="{HAIR_SH}"/>'''


def ears():
    return f'''
  <ellipse cx="{HEAD_CX-HEAD_RX+2}" cy="{HEAD_CY+6}" rx="10" ry="14" fill="{SKIN}" stroke="{LINE_C}" stroke-width="2.5"/>
  <ellipse cx="{HEAD_CX+HEAD_RX-2}" cy="{HEAD_CY+6}" rx="10" ry="14" fill="{SKIN}" stroke="{LINE_C}" stroke-width="2.5"/>'''


def head():
    return f'''
  <ellipse cx="{HEAD_CX}" cy="{HEAD_CY}" rx="{HEAD_RX}" ry="{HEAD_RY}" fill="{SKIN}" stroke="{LINE_C}" stroke-width="2.8"/>'''


def glasses():
    lx, rx, cy, r = 163, 207, 116, 21
    return f'''
  <line x1="{lx+r-3}" y1="{cy}" x2="{rx-r+3}" y2="{cy}" stroke="{GLASS}" stroke-width="3"/>
  <line x1="{lx-r}" y1="{cy-2}" x2="{HEAD_CX-HEAD_RX+6}" y2="{cy-6}" stroke="{GLASS}" stroke-width="3"/>
  <line x1="{rx+r}" y1="{cy-2}" x2="{HEAD_CX+HEAD_RX-6}" y2="{cy-6}" stroke="{GLASS}" stroke-width="3"/>
  <circle cx="{lx}" cy="{cy}" r="{r}" fill="#ffffff" fill-opacity="0.18" stroke="{GLASS}" stroke-width="3.5"/>
  <circle cx="{rx}" cy="{cy}" r="{r}" fill="#ffffff" fill-opacity="0.18" stroke="{GLASS}" stroke-width="3.5"/>'''


def brows(kind="normal"):
    ly, ry = 92, 92
    if kind == "raised":
        return f'''
  <path d="M148,90 Q163,82 178,88" stroke="{HAIR_SH}" stroke-width="4.5" fill="none" stroke-linecap="round"/>
  <path d="M192,88 Q207,82 222,90" stroke="{HAIR_SH}" stroke-width="4.5" fill="none" stroke-linecap="round"/>'''
    if kind == "worried":
        return f'''
  <path d="M150,96 Q164,90 178,94" stroke="{HAIR_SH}" stroke-width="4.5" fill="none" stroke-linecap="round"/>
  <path d="M192,94 Q206,90 220,96" stroke="{HAIR_SH}" stroke-width="4.5" fill="none" stroke-linecap="round"/>'''
    return f'''
  <path d="M149,93 Q164,88 178,92" stroke="{HAIR_SH}" stroke-width="4.5" fill="none" stroke-linecap="round"/>
  <path d="M192,92 Q206,88 221,93" stroke="{HAIR_SH}" stroke-width="4.5" fill="none" stroke-linecap="round"/>'''


def eyes(kind="open"):
    lx, rx, cy = 163, 207, 116
    if kind == "smile":  # ^ ^
        return f'''
  <path d="M153,119 Q163,108 173,119" stroke="{LINE_C}" stroke-width="4" fill="none" stroke-linecap="round"/>
  <path d="M197,119 Q207,108 217,119" stroke="{LINE_C}" stroke-width="4" fill="none" stroke-linecap="round"/>'''
    if kind == "closed":  # sleepy ‿
        return f'''
  <path d="M153,116 Q163,124 173,116" stroke="{LINE_C}" stroke-width="4" fill="none" stroke-linecap="round"/>
  <path d="M197,116 Q207,124 217,116" stroke="{LINE_C}" stroke-width="4" fill="none" stroke-linecap="round"/>'''
    if kind == "wink":  # left ^ , right dot
        return f'''
  <path d="M153,119 Q163,109 173,119" stroke="{LINE_C}" stroke-width="4" fill="none" stroke-linecap="round"/>
  <circle cx="{rx}" cy="{cy}" r="5.5" fill="{LINE_C}"/>'''
    if kind == "worried":
        return f'''
  <circle cx="{lx}" cy="{cy+1}" r="5" fill="{LINE_C}"/>
  <circle cx="{rx}" cy="{cy+1}" r="5" fill="{LINE_C}"/>'''
    # open
    return f'''
  <circle cx="{lx}" cy="{cy}" r="6" fill="{LINE_C}"/>
  <circle cx="{rx}" cy="{cy}" r="6" fill="{LINE_C}"/>
  <circle cx="{lx+2}" cy="{cy-2}" r="1.8" fill="#ffffff"/>
  <circle cx="{rx+2}" cy="{cy-2}" r="1.8" fill="#ffffff"/>'''


def nose():
    return f'<path d="M183,124 Q179,134 187,135" stroke="{LINE_C}" stroke-width="2.6" fill="none" stroke-linecap="round"/>'


def mouth(kind="smile"):
    if kind == "open_smile":
        return f'''
  <path d="M168,146 Q185,166 202,146 Q185,158 168,146 Z" fill="#7a3b3b"/>
  <path d="M172,150 Q185,158 198,150" fill="#e78a86"/>'''
    if kind == "grin":
        return f'''
  <path d="M166,145 Q185,164 204,145" stroke="{LINE_C}" stroke-width="3.4" fill="#fff" stroke-linecap="round"/>
  <path d="M170,148 Q185,160 200,148 Z" fill="#7a3b3b"/>'''
    if kind == "flat":
        return f'<path d="M170,149 Q185,153 200,149" stroke="{LINE_C}" stroke-width="3.4" fill="none" stroke-linecap="round"/>'
    if kind == "sad":
        return f'<path d="M170,153 Q185,144 200,153" stroke="{LINE_C}" stroke-width="3.4" fill="none" stroke-linecap="round"/>'
    if kind == "o":
        return f'<ellipse cx="185" cy="150" rx="9" ry="12" fill="#7a3b3b"/>'
    if kind == "small":
        return f'<path d="M176,148 Q185,156 194,148" stroke="{LINE_C}" stroke-width="3.2" fill="none" stroke-linecap="round"/>'
    # smile
    return f'<path d="M168,146 Q185,160 202,146" stroke="{LINE_C}" stroke-width="3.4" fill="none" stroke-linecap="round"/>'


def blush():
    return f'''
  <ellipse cx="147" cy="134" rx="11" ry="6.5" fill="{BLUSH}" fill-opacity="0.55"/>
  <ellipse cx="223" cy="134" rx="11" ry="6.5" fill="{BLUSH}" fill-opacity="0.55"/>'''


def body():
    # 肩・ポロシャツ（襟つき）
    return f'''
  <path d="M120,196 Q185,178 250,196 L262,214 Q185,196 108,214 Z" fill="{SHIRT}"/>
  <path d="M112,210 Q185,192 258,210 L268,240 L102,240 Z" fill="{SHIRT}"/>
  <path d="M108,214 Q185,196 262,214 L268,240 L263,240 Q185,206 107,240 L102,240 Z" fill="{SHIRT_SH}" fill-opacity="0.35"/>
  <path d="M168,190 L185,208 L202,190 L196,186 L185,198 L174,186 Z" fill="{COLLAR}" stroke="{SHIRT_SH}" stroke-width="1.5"/>'''


# --- 小物 -------------------------------------------------------------
def zzz():
    return f'''
  <text x="250" y="86" font-family="{FONT}" font-size="20" fill="#8aa0b8" font-weight="bold">z</text>
  <text x="266" y="72" font-family="{FONT}" font-size="26" fill="#7f97b2" font-weight="bold">Z</text>
  <text x="288" y="56" font-family="{FONT}" font-size="32" fill="#728cab" font-weight="bold">Z</text>'''


def sparkle():
    def s(x, y, r, c):
        return f'<path d="M{x},{y-r} L{x+r*0.28},{y-r*0.28} L{x+r},{y} L{x+r*0.28},{y+r*0.28} L{x},{y+r} L{x-r*0.28},{y+r*0.28} L{x-r},{y} L{x-r*0.28},{y-r*0.28} Z" fill="{c}"/>'
    return s(118, 78, 16, "#ffd45e") + s(258, 92, 12, "#ffd45e") + s(96, 150, 9, "#ffd45e")


def heart(x=262, y=110, s=1.0):
    return f'<path transform="translate({x},{y}) scale({s})" d="M0,6 C-6,-4 -20,2 0,18 C20,2 6,-4 0,6 Z" fill="{ACCENT}"/>'


def hand_wave():
    # 右手を上げてバイバイ
    return f'''
  <g stroke="{LINE_C}" stroke-width="2.6" stroke-linejoin="round">
    <path d="M250,150 q22,-6 30,-30" fill="none"/>
    <circle cx="282" cy="112" r="17" fill="{SKIN}"/>
    <path d="M276,104 v-16 M282,102 v-20 M288,104 v-16" stroke="{LINE_C}" stroke-width="4" stroke-linecap="round"/>
  </g>'''


def hand_thumb():
    # グッ！サムズアップ
    return f'''
  <g stroke="{LINE_C}" stroke-width="2.6" stroke-linejoin="round">
    <rect x="258" y="150" width="15" height="30" rx="7.5" fill="{SKIN}"/>
    <rect x="252" y="168" width="40" height="32" rx="14" fill="{SKIN}"/>
    <path d="M260,178 h24 M260,187 h24 M260,195 h21" stroke="{SKIN_SH}" stroke-width="2" fill="none" stroke-linecap="round"/>
  </g>'''


def hand_phone():
    # 電話を耳に
    return f'''
  <g>
    <rect x="236" y="120" width="20" height="40" rx="7" fill="#3a3f47" transform="rotate(18 246 140)"/>
    <circle cx="248" cy="128" r="3" fill="#8ad0ff"/>
  </g>'''


def hand_cheek():
    # ほおに手（おなかすいた等）
    return f'''
  <g stroke="{LINE_C}" stroke-width="2.6" stroke-linejoin="round">
    <path d="M226,140 q24,-2 24,20 q0,17 -17,17 q-13,0 -15,-13 q11,5 15,-2 q4,-9 -7,-22 Z" fill="{SKIN}"/>
    <path d="M232,150 q11,0 13,11 M230,160 q11,1 13,10" stroke="{SKIN_SH}" stroke-width="2" fill="none"/>
  </g>'''


# --- テキスト ---------------------------------------------------------
def text_block(line, size, y, dy2=None, line2=None, size2=None):
    halo = '9'
    out = f'''
  <text x="185" y="{y}" font-family="{FONT}" font-size="{size}" font-weight="bold"
        text-anchor="middle" fill="{TEXT_C}" stroke="{TEXT_HALO}" stroke-width="{halo}"
        paint-order="stroke" stroke-linejoin="round" letter-spacing="1">{line}</text>'''
    if line2:
        out += f'''
  <text x="185" y="{dy2}" font-family="{FONT}" font-size="{size2}" font-weight="bold"
        text-anchor="middle" fill="{TEXT_C}" stroke="{TEXT_HALO}" stroke-width="{halo}"
        paint-order="stroke" stroke-linejoin="round" letter-spacing="1">{line2}</text>'''
    return out


# --- スタンプ定義 -----------------------------------------------------
STAMPS = [
    dict(id="01_ohayou",     eyes="smile",  mouth="open_smile", brow="raised",  blush=True,  text="おはよう", size=52, ty=290, extra=["hand_wave","sun"]),
    dict(id="02_ittekimasu", eyes="wink",   mouth="grin",       brow="raised",  blush=False, text="いってきます", size=40, ty=290, extra=[]),
    dict(id="03_tadaima",    eyes="smile",  mouth="open_smile", brow="normal",  blush=True,  text="ただいま", size=50, ty=290, extra=[]),
    dict(id="04_otsukare",   eyes="closed", mouth="smile",      brow="worried", blush=True,  text="おつかれさま", size=38, ty=290, extra=[]),
    dict(id="05_arigatou",   eyes="smile",  mouth="smile",      brow="raised",  blush=True,  text="ありがとう", size=44, ty=290, extra=["heart"]),
    dict(id="06_gomen",      eyes="worried",mouth="sad",        brow="worried", blush=False, text="ごめんね", size=48, ty=290, extra=["sweat"]),
    dict(id="07_ryoukai",    eyes="open",   mouth="grin",       brow="raised",  blush=False, text="了解！", size=56, ty=290, extra=["hand_thumb"]),
    dict(id="08_daijoubu",   eyes="worried",mouth="small",      brow="worried", blush=False, text="だいじょうぶ？", size=34, ty=292, extra=[]),
    dict(id="09_onaka",      eyes="closed", mouth="flat",       brow="worried", blush=True,  text="おなかすいた", size=38, ty=290, extra=["hand_cheek"]),
    dict(id="10_kaeru",      eyes="smile",  mouth="smile",      brow="normal",  blush=False, text="いま帰るよ", size=44, ty=290, extra=["hand_phone"]),
    dict(id="11_genki",      eyes="open",   mouth="open_smile", brow="raised",  blush=True,  text="げんき？", size=50, ty=290, extra=["heart"]),
    dict(id="12_sugoi",      eyes="open",   mouth="o",          brow="raised",  blush=True,  text="すごい！", size=54, ty=290, extra=["sparkle"]),
    dict(id="13_tasukatta",  eyes="smile",  mouth="smile",      brow="raised",  blush=True,  text="たすかったよ", size=38, ty=290, extra=[]),
    dict(id="14_murishinai", eyes="worried",mouth="smile",      brow="worried", blush=True,  text="むりしないで", size=38, ty=290, extra=["heart"]),
    dict(id="15_oyasumi",    eyes="closed", mouth="small",      brow="normal",  blush=True,  text="おやすみ", size=50, ty=290, extra=["zzz"]),
    dict(id="16_matane",     eyes="smile",  mouth="grin",       brow="raised",  blush=True,  text="またね", size=52, ty=290, extra=["hand_wave"]),
]


def sun():
    return f'''
  <g stroke="#ffb23e" stroke-width="4" stroke-linecap="round">
    <circle cx="86" cy="72" r="18" fill="#ffd45e" stroke="none"/>
    <line x1="86" y1="42" x2="86" y2="34"/><line x1="86" y1="110" x2="86" y2="102"/>
    <line x1="56" y1="72" x2="48" y2="72"/><line x1="124" y1="72" x2="116" y2="72"/>
    <line x1="65" y1="51" x2="59" y2="45"/><line x1="113" y1="99" x2="107" y2="93"/>
    <line x1="65" y1="93" x2="59" y2="99"/><line x1="113" y1="45" x2="107" y2="51"/>
  </g>'''


def sweat_drop():
    return f'<path d="M240,92 q-8,12 0,20 q8,-8 0,-20 Z" fill="#6fc3e8" stroke="#4aa8d4" stroke-width="1.6"/>'


EXTRA_FN = {
    "hand_wave": hand_wave,
    "hand_thumb": hand_thumb,
    "hand_phone": hand_phone,
    "hand_cheek": hand_cheek,
    "sweat": sweat_drop,
    "zzz": zzz,
    "sparkle": sparkle,
    "heart": lambda: heart(258, 104, 1.3) + heart(292, 128, 0.9),
    "sun": sun,
}


def build_svg(s):
    parts = ['<?xml version="1.0" encoding="UTF-8"?>',
             f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">']
    # 背景の装飾extra（キャラの後ろ）
    for e in s["extra"]:
        if e in ("sun", "sparkle", "zzz", "heart"):
            parts.append(EXTRA_FN[e]())
    # 体
    parts.append(body())
    # 後ろ手（電話・ほお手はキャラ手前）
    parts.append(head())
    parts.append(ears())
    parts.append(hair())
    parts.append(glasses())
    parts.append(brows(s["brow"]))
    parts.append(eyes(s["eyes"]))
    parts.append(nose())
    parts.append(mouth(s["mouth"]))
    if s["blush"]:
        parts.append(blush())
    # 手前のextra
    for e in s["extra"]:
        if e in ("hand_wave", "hand_thumb", "hand_phone", "hand_cheek", "sweat"):
            parts.append(EXTRA_FN[e]())
    # テキスト
    parts.append(text_block(s["text"], s["size"], s["ty"]))
    parts.append('</svg>')
    return "\n".join(parts)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    outdir = os.path.join(here, "svg")
    os.makedirs(outdir, exist_ok=True)
    for s in STAMPS:
        svg = build_svg(s)
        with open(os.path.join(outdir, s["id"] + ".svg"), "w", encoding="utf-8") as f:
            f.write(svg)
        print("wrote", s["id"] + ".svg")


if __name__ == "__main__":
    main()
