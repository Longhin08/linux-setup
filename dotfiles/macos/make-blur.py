#!/usr/bin/env python3
# Renders the current wallpaper at screen size (zoom/cover), blurred and tinted,
# for the widget-blur Cinnamon extension to use as widget backgrounds.
import sys, gi
gi.require_version('GdkPixbuf', '2.0'); gi.require_version('Gdk', '3.0')
from gi.repository import GdkPixbuf, Gdk, Gio
from urllib.parse import unquote, urlparse

out = sys.argv[1]
uri = Gio.Settings.new('org.cinnamon.desktop.background').get_string('picture-uri')
scr = Gdk.Screen.get_default()
g = scr.get_display().get_primary_monitor().get_geometry(); W, H = g.width, g.height

src = GdkPixbuf.Pixbuf.new_from_file(unquote(urlparse(uri).path))
s = max(W / src.get_width(), H / src.get_height())
sw, sh = round(src.get_width() * s), round(src.get_height() * s)
full = src.scale_simple(sw, sh, GdkPixbuf.InterpType.BILINEAR)
img = full.new_subpixbuf((sw - W) // 2, (sh - H) // 2, W, H).copy()

# blur: shrink hard, then scale back up smoothly (two passes)
for f in (12, 6):
    small = img.scale_simple(max(1, W // f), max(1, H // f), GdkPixbuf.InterpType.HYPER)
    img = small.scale_simple(W, H, GdkPixbuf.InterpType.BILINEAR)

# dark-mode tint, like macOS widget material
tint = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, W, H)
tint.fill(0x1e1e24ff)
img = img.add_alpha(False, 0, 0, 0)
tint.composite(img, 0, 0, W, H, 0, 0, 1, 1, GdkPixbuf.InterpType.NEAREST, 115)
img.savev(out, 'png', [], [])
