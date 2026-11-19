"""The bench's side panel as a field notebook lying open beside the weapon (Mia: "als ob man da wirklich ein notebook
nebenbei offen hat"), drawn after the real top-bound all-weather pads: the cover folded away behind, the top page with
the pages under it peeking out at the right and bottom, small square punched holes and a black twin-wire (Wire-O)
binding whose loops only just clear the top edge, round bottom corners. The ruled lines, the margin and every word are
drawn in the game (fnc_open), so they sit on the text rows.

    python tools/manual/make_notebook.py   -> tools/manual/out/notebook.png, flip.png, box.png, tick.png
                                              and addons/workbench/ui/notebook_ca.paa, flip_co.paa, box_ca.paa, tick_ca.paa

The top page's place on the texture (fractions, used in fnc_open): left 0.012, top 0.03, right 0.975, bottom 0.975.
The holes end at 0.06.
"""
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from make_manual import IMAGE_TO_PAA, OUT, REPO

UI = REPO / "addons" / "workbench" / "ui"
W, H = 512, 1024
PAGE = (240, 236, 220)
PAGE_BOX = (6, 31, 499, 998)  # left 0.012, top 0.03, right 0.975, bottom 0.975
WIRE = (24, 24, 26)
WIRE_LIGHT = (118, 120, 126)


def grain(img, sigma, seed):
    rng = np.random.default_rng(seed)
    a = np.asarray(img).astype(np.int16)
    a[..., :3] += rng.normal(0, sigma, a.shape[:2]).astype(np.int16)[..., None]
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), img.mode)


def sheet(box, colour, top_r=7, bottom_r=18):
    """A sheet's outline: slightly round at the top, rounder at the bottom where it is thumbed."""
    x0, y0, x1, y1 = box
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle(box, radius=bottom_r, fill=255)
    d.rectangle([x0, y0, x1, y0 + bottom_r], fill=0)
    d.rounded_rectangle([x0, y0, x1, y0 + 3 * bottom_r], radius=top_r, fill=255)
    layer = Image.new("RGBA", (W, H), colour + (255,))
    layer.putalpha(m)
    return layer


def notebook():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    x0, y0, x1, y1 = PAGE_BOX

    # The back cover's card and the pages under the top one: their edges at the right and bottom, each a shade darker.
    for i, shade in ((4, (120, 116, 100)), (3, (204, 198, 178)), (2, (214, 208, 190)), (1, (224, 219, 202))):
        img.alpha_composite(sheet((x0 + i, y0 + i, x1 + 2 * i + 2, y1 + 2 * i + 2), shade))

    # The top page, its rim a touch darker where hands have held it.
    page = grain(sheet(PAGE_BOX, PAGE), 4, 9)
    rim = Image.new("L", (W, H), 0)
    rd = ImageDraw.Draw(rim)
    for i in range(14):
        rd.rounded_rectangle([x0 + i, y0 + i, x1 - i, y1 - i], radius=14, outline=int(45 * (1 - i / 14)))
    alpha = page.getchannel("A")
    page = Image.composite(Image.new("RGBA", (W, H), (196, 188, 160, 255)), page, rim.filter(ImageFilter.GaussianBlur(5)))
    page.putalpha(alpha)
    img.alpha_composite(page)
    d = ImageDraw.Draw(img)

    # The binding: a twin-wire loop per punched hole, evenly along the top. Each loop comes out of its square hole in
    # front of the page, bends over the top edge and goes down behind it - so only the front leg and the bend show.
    holes = 17
    pitch = (x1 - x0 - 36) / (holes - 1)
    hole_top, hole_bottom = y0 + 13, y0 + 23
    bend_top = y0 - 15
    for k in range(holes):
        cx = x0 + 18 + k * pitch
        d.rounded_rectangle([cx - 6, hole_top, cx + 6, hole_bottom], radius=2, fill=(44, 40, 34))
    for k in range(holes):
        cx = x0 + 18 + k * pitch
        for dx in (-3, 3):
            wx = cx + dx
            # Shadow on the page under the front leg.
            d.line([(wx + 2, y0 + 2), (wx + 2, hole_top + 6)], fill=(150, 144, 124), width=3)
            for width, colour in ((5, WIRE), (2, WIRE_LIGHT)):
                d.arc([wx - 6, bend_top, wx + 6, bend_top + 14], start=180, end=360, fill=colour, width=width - 1)
                d.line([(wx - 6, bend_top + 7), (wx - 5, hole_top + 6)], fill=colour, width=width)
                d.line([(wx + 6, bend_top + 7), (wx + 6, y0 + 1)], fill=colour, width=width)
    return img


def flip():
    """The page that turns up and over the binding when the notebook is paged (fnc_refresh)."""
    img = Image.new("RGB", (256, 512), PAGE)
    d = ImageDraw.Draw(img)
    for y in range(40, 512, 22):
        d.line([0, y, 255, y], fill=(170, 190, 210), width=1)
    d.line([26, 0, 26, 511], fill=(214, 120, 110), width=1)
    # Shade along the lower edge: the page lifts there.
    shade = Image.new("L", (256, 512), 0)
    ImageDraw.Draw(shade).rectangle([0, 440, 255, 511], fill=110)
    img.paste((150, 144, 124), mask=shade.filter(ImageFilter.GaussianBlur(30)))
    return grain(img, 4, 11)


def boxes():
    """A ballpoint check box, and the same with a tick - white, tinted in the game."""
    box = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(box)
    d.line([(10, 12), (54, 10), (55, 54), (9, 55), (10, 12)], fill=(255, 255, 255, 255), width=5, joint="curve")
    tick = box.copy()
    t = ImageDraw.Draw(tick)
    t.line([(14, 32), (27, 47), (60, 2)], fill=(255, 255, 255, 255), width=8, joint="curve")
    return box, tick


def export(img, name):
    png = OUT / f"{name}.png"
    img.save(png)
    suffix = "ca" if img.mode == "RGBA" else "co"
    paa = UI / f"{name}_{suffix}.paa"
    subprocess.run([str(IMAGE_TO_PAA), str(png), str(paa)], check=True)
    print(paa)


def main():
    OUT.mkdir(exist_ok=True)
    export(notebook(), "notebook")
    export(flip(), "flip")
    box, tick = boxes()
    export(box, "box")
    export(tick, "tick")


if __name__ == "__main__":
    main()
