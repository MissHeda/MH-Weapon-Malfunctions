"""The bench's side panel as a field notebook lying open beside the weapon (Mia: "als ob man da wirklich ein notebook
nebenbei offen hat"): an olive cover, a stack of pages, a wire spiral across the top, round corners. The ruled lines,
the margin and every word are drawn in the game (fnc_open), so they sit on the text rows.

    python tools/manual/make_notebook.py   -> tools/manual/out/notebook.png, flip.png, box.png, tick.png
                                              and addons/workbench/ui/notebook_ca.paa, flip_co.paa, box_ca.paa, tick_ca.paa

The page's place on the texture (fractions, used in fnc_open): left 0.035, top 0.075, right 0.945, bottom 0.965.
"""
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from make_manual import IMAGE_TO_PAA, OUT, REPO

UI = REPO / "addons" / "workbench" / "ui"
W, H = 512, 1024
COVER = (72, 78, 50)
COVER_DARK = (48, 52, 33)
PAGE = (238, 234, 216)
EDGE = (214, 208, 186)
PAGE_BOX = (18, 77, 484, 988)  # left 0.035, top 0.075, right 0.945, bottom 0.965


def grain(img, sigma, seed):
    rng = np.random.default_rng(seed)
    a = np.asarray(img).astype(np.int16)
    a[..., :3] += rng.normal(0, sigma, a.shape[:2]).astype(np.int16)[..., None]
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), img.mode)


def notebook():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # The cover behind the pages, a little larger, worn lighter at its rim.
    d.rounded_rectangle([0, 30, W - 1, H - 1], radius=30, fill=COVER_DARK)
    d.rounded_rectangle([3, 33, W - 4, H - 4], radius=28, fill=COVER)
    img = grain(img, 7, 3)
    d = ImageDraw.Draw(img)

    # The stack of pages under the top one: edges peeking out right and below.
    x0, y0, x1, y1 = PAGE_BOX
    for i, shade in ((3, (196, 190, 168)), (2, (206, 200, 178)), (1, EDGE)):
        d.rounded_rectangle([x0 + 2 * i, y0 + 2 * i, x1 + 4 * i, y1 + 4 * i], radius=12, fill=shade, outline=(150, 144, 124), width=1)

    # The top page.
    page = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pd = ImageDraw.Draw(page)
    pd.rounded_rectangle(PAGE_BOX, radius=12, fill=PAGE + (255,))
    page = grain(page, 4, 9)
    # Thumbed corners: a touch darker towards the rim.
    rim = Image.new("L", (W, H), 0)
    rd = ImageDraw.Draw(rim)
    for i in range(18):
        rd.rounded_rectangle([x0 + i, y0 + i, x1 - i, y1 - i], radius=12, outline=int(60 * (1 - i / 18)))
    tint = Image.new("RGBA", (W, H), (190, 180, 150, 255))
    alpha = page.getchannel("A")
    page = Image.composite(tint, page, rim.filter(ImageFilter.GaussianBlur(6)))
    page.putalpha(alpha)
    img.alpha_composite(page)
    d = ImageDraw.Draw(img)

    # The wire binding: pairs of loops, each one piece - out of its punched hole on the page, up over the top edge and
    # down behind the pages (Mia: the old spiral read as two rows of hooks).
    n = 14
    step = (x1 - x0 - 44) / (n - 1)
    hole_y = y0 + 20
    top = 12
    dark, metal, shine = (26, 26, 26), (128, 130, 134), (215, 217, 220)

    def loop(cx):
        r = 6
        # Back leg, behind the pages: only seen above the page's top edge.
        for width, colour in ((6, dark), (3, metal)):
            d.line([(cx + r, top + r), (cx + r, y0 + 1)], fill=colour, width=width)
        # Front leg into the hole, and the bend over the top.
        for width, colour in ((6, dark), (3, metal)):
            d.line([(cx - r, top + r), (cx - r, hole_y)], fill=colour, width=width)
            d.arc([cx - r, top, cx + r, top + 2 * r], start=180, end=360, fill=colour, width=width // 2 + 1)
        d.line([(cx - r - 1, top + r + 2), (cx - r - 1, hole_y - 6)], fill=shine, width=1)

    for k in range(n):
        cx = x0 + 22 + k * step
        for dx in (-4, 5):
            d.ellipse([cx + dx - 6 - 5, hole_y - 5, cx + dx - 6 + 5, hole_y + 5], fill=(36, 34, 30))
    for k in range(n):
        cx = x0 + 22 + k * step
        for dx in (-4, 5):
            loop(cx + dx)
    return img


def flip():
    """The page that turns up and over the spiral when the notebook is paged (fnc_refresh)."""
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
