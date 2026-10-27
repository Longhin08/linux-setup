#!/usr/bin/env python3
"""Copia um tema GTK/Cinnamon trocando o azul de destaque pelo amarelo do Batman.

Uso: recolor-theme.py ORIGEM DESTINO NOME
O gtk.gresource do GTK 3/4 é desempacotado em arquivos soltos (o CSS usa caminhos relativos),
toda cor azul vira amarela com o mesmo brilho, e onde o fundo fica amarelo o texto branco vira preto.
"""
import colorsys, os, re, shutil, subprocess, sys
from PIL import Image

HUE = 45 / 360           # amarelo do Batman
DARK_TEXT = "#121212"    # texto em cima do amarelo


def is_blue(r, g, b):
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return 190 / 360 <= h <= 250 / 360 and s > 0.35 and v > 0.25, s, v


def shift(r, g, b):
    blue, s, v = is_blue(r, g, b)
    if not blue:
        return r, g, b
    return tuple(round(c * 255) for c in colorsys.hsv_to_rgb(HUE, s, v))


def hex_sub(m):
    h = m.group(1)
    full = "".join(c * 2 for c in h) if len(h) in (3, 4) else h
    r, g, b = (int(full[i:i + 2], 16) for i in (0, 2, 4))
    nr, ng, nb = shift(r, g, b)
    if (nr, ng, nb) == (r, g, b):
        return m.group(0)
    return "#%02x%02x%02x%s" % (nr, ng, nb, full[6:])


def rgb_sub(m):
    r, g, b = (int(float(x)) for x in m.group(2, 3, 4))
    nr, ng, nb = shift(r, g, b)
    return "%s(%d, %d, %d%s)" % (m.group(1), nr, ng, nb, m.group(5) or "")


HEX = re.compile(r"#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3,4})\b")
RGB = re.compile(r"(rgba?)\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(,\s*[\d.]+\s*)?\)")
WHITE_TEXT = re.compile(r"((?<![-\w])color:\s*)(#fff(?:fff)?|white|rgba\(255, 255, 255, (?:0\.[6-9]\d*|1)\))(\s*;)", re.I)
BG_DECL = re.compile(r"background(?:-color|-image)?:([^;]*)", re.I)


def colors(s):
    for m in HEX.finditer(s):
        h = m.group(1)
        full = "".join(c * 2 for c in h) if len(h) in (3, 4) else h
        yield tuple(int(full[i:i + 2], 16) for i in (0, 2, 4))
    for m in RGB.finditer(s):
        yield tuple(int(float(x)) for x in m.group(2, 3, 4))


def yellow_bg(block):
    for decl in BG_DECL.findall(block):
        for r, g, b in colors(decl):
            h, sat, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if abs(h - HUE) < 6 / 360 and sat > 0.35 and v > 0.5:
                return True
    return False


def recolor_text(s, css):
    s = RGB.sub(rgb_sub, HEX.sub(hex_sub, s))
    if css:
        s = re.sub(r"\{[^{}]*\}",
                   lambda m: WHITE_TEXT.sub(r"\g<1>%s\3" % DARK_TEXT, m.group(0)) if yellow_bg(m.group(0)) else m.group(0),
                   s)
        s = re.sub(r"(@define-color \w*selected_fg_color )#ffffff", r"\g<1>" + DARK_TEXT, s)
    return s


def recolor_png(path):
    im = Image.open(path).convert("RGBA")
    px = im.load()
    changed = False
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and is_blue(r, g, b)[0]:
                px[x, y] = (*shift(r, g, b), a)
                changed = True
    if changed:
        im.save(path)


def unpack_gresource(d):
    res = os.path.join(d, "gtk.gresource")
    if not os.path.exists(res):
        return
    names = subprocess.run(["gresource", "list", res], capture_output=True, text=True, check=True).stdout.split()
    prefix = os.path.commonpath(names)
    for n in names:
        out = os.path.join(d, os.path.relpath(n, prefix))
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with open(out, "wb") as f:
            f.write(subprocess.run(["gresource", "extract", res, n], capture_output=True, check=True).stdout)
    os.remove(res)


def main(src, dst, name):
    old = os.path.basename(os.path.normpath(src))
    shutil.rmtree(dst, ignore_errors=True)
    shutil.copytree(src, dst, symlinks=True)
    for v in ("gtk-3.0", "gtk-4.0"):
        unpack_gresource(os.path.join(dst, v))
    for root, _, files in os.walk(dst):
        for fn in files:
            p = os.path.join(root, fn)
            if os.path.islink(p):
                continue
            ext = os.path.splitext(fn)[1]
            if ext == ".png":
                recolor_png(p)
            elif ext in (".css", ".svg", ".rc", ".xml", ".theme") or fn == "gtkrc":
                with open(p, encoding="utf-8", errors="surrogateescape") as f:
                    s = f.read()
                t = recolor_text(s, ext == ".css")
                if fn == "index.theme":
                    t = re.sub(r"^((?:Name|GtkTheme|MetacityTheme)=)%s$" % re.escape(old), r"\g<1>" + name, t, flags=re.M)
                if t != s:
                    with open(p, "w", encoding="utf-8", errors="surrogateescape") as f:
                        f.write(t)


if __name__ == "__main__":
    main(*sys.argv[1:4])
