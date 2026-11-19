"""The field manual page of the 3D view (addons/workbench/ui/manual_co.paa): how to play the minigames, drawn like an old
army maintenance comic - yellowed paper, black ink with halftone dots, red as the one spot colour, hand-lettered red
headline, condensed caption boxes, sound words in bursts. All of it drawn here from the game's own renders
(tools/test/MHWM_Render.VR -> renders/*.png, the parts' screen places in renders/spots.txt): no art of anyone else.

    python tools/manual/make_manual.py            -> tools/manual/out/manual.png (2048 x 1024)
    python tools/manual/make_manual.py --paa      -> also addons/workbench/ui/manual_co.paa (Arma 3 Tools' ImageToPAA)
"""
import math
import random
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
RENDERS = HERE / "renders"
OUT = HERE / "out"
PAA = REPO / "addons" / "workbench" / "ui" / "manual_co.paa"
IMAGE_TO_PAA = Path(r"D:\Steam\steamapps\common\Arma 3 Tools\ImageToPAA\ImageToPAA.exe")
FONTS = Path(r"C:\Windows\Fonts")

W, H = 2048, 1024
PAPER = (240, 230, 203)
PAPER_DARK = (222, 208, 172)
INK = (28, 24, 22)
RED = (214, 52, 38)
TINT = (226, 212, 178)

# The renders' frame: UI units -> pixels of the cropped 1170 x 774 picture (render mission: VIEW line, 1920 x 1080 window).
SAFE = (-0.712121, -0.409091, 2.42424, 1.81818)
CROP = (132, 178)

random.seed(7)


def font(name, size, variation=None):
    f = ImageFont.truetype(str(FONTS / name), size)
    if variation:
        f.set_variation_by_name(variation)
    return f


def spots():
    out = {}
    for line in (RENDERS / "spots.txt").read_text().splitlines():
        name, data = line.split(" ", 1)
        items = eval(data.replace("[", "(").replace("]", ")").replace("(", "[").replace(")", "]"))
        out[name] = {k: ((x - SAFE[0]) / SAFE[2] * 1920 - CROP[0], (y - SAFE[1]) / SAFE[3] * 1080 - CROP[1]) for k, (x, y) in items}
    return out


# ----- Ink: a render as a two-colour print -----
def ink(path, size):
    img = Image.open(path).convert("RGB")
    a = np.asarray(img).astype(np.float32) / 255
    bg = a[0:6, 0:6].reshape(-1, 3).mean(axis=0)
    diff = np.abs(a - bg).max(axis=2)
    mask = Image.fromarray(((diff > 0.035) * 255).astype(np.uint8))
    mask = mask.filter(ImageFilter.MedianFilter(5)).filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
    m = np.asarray(mask) > 127

    lum = (0.3 * a[..., 0] + 0.59 * a[..., 1] + 0.11 * a[..., 2])
    lum = np.clip((lum - 0.08) / 0.75, 0, 1)
    # Brass: warm and saturated - printed in the spot red.
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    # The MX's tan is warm too (r - b ~ 0.25): only strongly saturated brass counts.
    brass = m & (r > 0.45) & (r - b > 0.34) & (g - b > 0.12)

    h, w = lum.shape
    yy, xx = np.mgrid[0:h, 0:w]
    cell = 7
    cx = (xx % cell) - cell / 2 + 0.5
    cy = (yy % cell) - cell / 2 + 0.5
    dist = np.sqrt(cx * cx + cy * cy)
    dark = 1 - lum
    dots = dist < (dark * cell * 0.62)

    out = np.empty((h, w, 3), np.float32)
    out[:] = np.array(PAPER) / 255
    tint = np.array(TINT) / 255
    out[m] = tint
    mid = m & (lum < 0.62)
    out[mid & dots] = np.array(INK) / 255
    out[m & (lum < 0.2)] = np.array(INK) / 255
    out[brass] = np.array(RED) / 255
    out[brass & (lum < 0.45) & dots] = np.array(INK) / 255

    pic = Image.fromarray((out * 255).astype(np.uint8))

    # Ink lines: the outline of the weapon and its inner edges.
    edges = Image.fromarray((lum * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2)).filter(ImageFilter.FIND_EDGES)
    e = np.asarray(edges) > 28
    outline = np.asarray(mask.filter(ImageFilter.MaxFilter(5))) > 127
    outline &= ~(np.asarray(mask.filter(ImageFilter.MinFilter(3))) > 127)
    lines = Image.fromarray((((e & m) | outline) * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3))
    pic.paste(INK, mask=lines)
    return pic.resize(size, Image.LANCZOS), (size[0] / img.width, size[1] / img.height)


# ----- Comic pieces -----
def arrow(d, start, end, width=16, head=40, color=RED):
    sx, sy = start
    ex, ey = end
    ang = math.atan2(ey - sy, ex - sx)
    bx, by = ex - head * math.cos(ang), ey - head * math.sin(ang)
    nx, ny = -math.sin(ang), math.cos(ang)
    body = [(sx + nx * width / 2, sy + ny * width / 2), (bx + nx * width / 2, by + ny * width / 2),
            (bx + nx * head * 0.62, by + ny * head * 0.62), (ex, ey),
            (bx - nx * head * 0.62, by - ny * head * 0.62), (bx - nx * width / 2, by - ny * width / 2),
            (sx - nx * width / 2, sy - ny * width / 2)]
    d.polygon(body, fill=color, outline=INK, width=4)


def curved_arrow(d, points, width=14, head=36):
    for a, b in zip(points[:-2], points[1:-1]):
        d.line([a, b], fill=INK, width=width + 8)
    for a, b in zip(points[:-2], points[1:-1]):
        d.line([a, b], fill=RED, width=width)
    arrow(d, points[-2], points[-1], width, head)


def burst(d, centre, text, size, fnt, rot=0):
    cx, cy = centre
    pts = []
    n = 14
    for i in range(n * 2):
        r = size * (1.0 if i % 2 == 0 else 0.62) * (0.9 + random.random() * 0.2)
        a = math.pi * i / n + rot
        pts.append((cx + r * 1.35 * math.cos(a), cy + r * math.sin(a)))
    d.polygon([(x + 6, y + 6) for x, y in pts], fill=INK)
    d.polygon(pts, fill=(250, 214, 64), outline=INK, width=4)
    tw = d.textlength(text, font=fnt)
    d.text((cx - tw / 2, cy - fnt.size * 0.62), text, font=fnt, fill=RED, stroke_width=3, stroke_fill=INK)


def mouse(d, x, y, button, s=1.0):
    """A mouse seen from above, the button to use in red: left, right, middle (wheel) or None."""
    w, h = 44 * s, 66 * s
    d.rounded_rectangle([x, y, x + w, y + h], radius=20 * s, fill=PAPER, outline=INK, width=4)
    d.line([x + w / 2, y, x + w / 2, y + h * 0.42], fill=INK, width=3)
    d.line([x, y + h * 0.42, x + w, y + h * 0.42], fill=INK, width=3)
    if button == "left":
        d.rounded_rectangle([x + 4, y + 4, x + w / 2 - 2, y + h * 0.42 - 2], radius=14 * s, fill=RED)
    elif button == "right":
        d.rounded_rectangle([x + w / 2 + 2, y + 4, x + w - 4, y + h * 0.42 - 2], radius=14 * s, fill=RED)
    elif button == "middle":
        d.rounded_rectangle([x + w / 2 - 6 * s, y + 8 * s, x + w / 2 + 6 * s, y + h * 0.36], radius=5, fill=RED, outline=INK, width=2)


def wrap(d, text, fnt, width):
    lines, line = [], ""
    for word in text.split():
        test = (line + " " + word).strip()
        if d.textlength(test, font=fnt) <= width:
            line = test
        else:
            lines.append(line)
            line = word
    lines.append(line)
    return lines


def caption(d, box, number, text, fnt, numfnt):
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=(250, 246, 232), outline=INK, width=4)
    d.ellipse([x0 + 10, y0 + 10, x0 + 52, y0 + 52], fill=INK)
    tw = d.textlength(str(number), font=numfnt)
    d.text((x0 + 31 - tw / 2, y0 + 12), str(number), font=numfnt, fill=PAPER)
    ty = y0 + 12
    for line in wrap(d, text, fnt, x1 - x0 - 84):
        d.text((x0 + 66, ty), line, font=fnt, fill=INK)
        ty += fnt.size * 1.08


def roughen(img, amount=0.06):
    """Ink that did not take everywhere: a speckle of paper in the solid colours, and the paper's grain."""
    a = np.asarray(img).astype(np.int16)
    noise = np.random.default_rng(3).normal(0, 7, a.shape[:2])
    a = a + noise[..., None]
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


# ----- The page -----
STEPS = {}


def build():
    sp = spots()
    page = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(page)

    # Yellowed edges.
    vign = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vign)
    for i in range(60):
        vd.rectangle([i, i, W - i, H - i], outline=int(150 * (1 - i / 60)))
    page.paste(PAPER_DARK, mask=vign.filter(ImageFilter.GaussianBlur(25)))

    head = font("impact.ttf", 150)
    kicker = font("comicbd.ttf", 34)
    body = font("cour.ttf", 24)
    bodyb = font("courbd.ttf", 24)
    cap = font("bahnschrift.ttf", 29, "SemiBold Condensed")
    num = font("impact.ttf", 34)
    sfx = font("impact.ttf", 46)
    small = font("bahnschrift.ttf", 26, "Bold Condensed")

    # ----- Left column: headline, the talk, the mouse, the tip -----
    lx = 70
    d.text((lx, 62), "STAY COOL - BUT MOVE IT!", font=kicker, fill=INK)

    title = Image.new("RGBA", (560, 340), (0, 0, 0, 0))
    td = ImageDraw.Draw(title)
    for i, word in enumerate(["CLEAR", "THAT JAM!"]):
        f = head if i == 0 else font("impact.ttf", 118)
        td.text((14, 6 + i * 150), word, font=f, fill=INK)
        td.text((4, -4 + i * 150), word, font=f, fill=RED, stroke_width=5, stroke_fill=INK)
    # Hand-lettered: a little ragged and tilted.
    alpha = np.asarray(title.split()[3]).astype(np.int16)
    speck = np.random.default_rng(11).random(alpha.shape) < 0.015
    alpha[speck] = 0
    title.putalpha(Image.fromarray(alpha.clip(0, 255).astype(np.uint8)))
    title = title.rotate(4, resample=Image.BICUBIC, expand=True)
    page.paste(title, (lx - 10, 110), title)

    ty = 452
    talk = ("Your piece quits on you in the middle of it? Don't sweat it, soldier. "
            "Every stoppage has a cure, and your hands know it. Work the parts right on the weapon "
            "- the red rings show you where.")
    for line in wrap(d, talk, body, 500):
        d.text((lx, ty), line, font=body, fill=INK)
        ty += 30

    ty += 14
    d.text((lx, ty), "YOUR MOUSE:", font=bodyb, fill=INK)
    ty += 38
    for button, label in [("left", "work a part"), ("right", "turn the weapon"), ("middle", "hold: move it")]:
        mouse(d, lx, ty, button, 0.62)
        d.text((lx + 46, ty + 6), label, font=body, fill=INK)
        ty += 46
    mouse(d, lx, ty, None, 0.62)
    d.text((lx + 46, ty + 6), "wheel: zoom", font=body, fill=INK)
    ty += 58

    # The tip, in a box.
    d.rectangle([lx - 6, ty, lx + 506, ty + 132], fill=RED, outline=INK, width=4)
    d.rectangle([lx - 6, ty, lx + 506, ty + 132], outline=INK, width=4)
    d.text((lx + 12, ty + 10), "UNDER FIRE? NO TIME TO LOOK?", font=small, fill=(255, 245, 220))
    tip = "Tap Shift + R: Tap-Rack, blind. Hold Shift + R: this bench."
    yy = ty + 46
    for line in wrap(d, tip, cap, 480):
        d.text((lx + 12, yy), line, font=cap, fill=(255, 245, 220))
        yy += 32

    # ----- Right: six panels -----
    panels = [
        ("r_tap", "TAP!", "Magazine loose? Click it once to tap it home. Then rack."),
        ("r_rack", "KA-CHUNK!", "Grab the charging handle, drag it ALL the way back and let go. Halfway is a short stroke - nothing happens."),
        ("r_locked", "CLICK!", "Need the action open? Drag the handle back and HOLD it till the bar is full: the bolt locks. Click it to send it home."),
        ("r_magout", "SNAP!", "Drag the magazine down to drop it. Push it up STRAIGHT - off the line it goes in but won't click."),
        ("r_chamber", "RATTLE!", "Bolt locked, mag out: hold on the chamber and wiggle left, right, left till it's clear. A stuck case takes more."),
        ("r_sweep", "PING!", "Case caught in the port? Swipe it out and away - or just rack it."),
    ]

    gx, gy = 640, 40
    pw, ph = 446, 300
    capH = 138
    gapX, gapY = 22, 18

    for i, (name, word, text) in enumerate(panels):
        col, row = i % 3, i // 3
        x = gx + col * (pw + gapX)
        y = gy + row * (ph + capH + gapY)

        pic, (kx, ky) = ink(RENDERS / f"{name}.png", (pw, ph))
        pd = ImageDraw.Draw(pic)
        s = sp[name]

        def P(key, dx=0, dy=0):
            px, py = s[key]
            return (px * kx + dx, py * ky + dy)

        if name == "r_tap":
            mx, my = P("mag")
            arrow(pd, (mx + 40, my + 210), (mx + 40, my + 95))
            mouse(pd, pw - 70, ph - 92, "left", 1.0)
        elif name == "r_rack":
            hx, hy = P("handle")
            arrow(pd, (hx - 10, hy - 34), (hx - 190, hy - 34))
            mouse(pd, pw - 70, ph - 92, "left", 1.0)
        elif name == "r_locked":
            hx, hy = P("handle")
            arrow(pd, (hx + 20, hy - 36), (hx - 140, hy - 36))
            mouse(pd, pw - 70, ph - 92, "left", 1.0)
        elif name == "r_magout":
            mx, my = P("mag")
            arrow(pd, (mx + 74, my - 120), (mx + 74, my - 10))
            arrow(pd, (mx - 66, my - 10), (mx - 66, my - 120))
            mouse(pd, pw - 70, ph - 92, "left", 1.0)
        elif name == "r_chamber":
            cx, cy = P("chamber")
            zig = [(cx - 110 + j * 44, cy - 60 + (j % 2) * 34) for j in range(6)]
            curved_arrow(pd, zig, 12, 30)
            mouse(pd, pw - 70, ph - 92, "left", 1.0)
        elif name == "r_sweep":
            px_, py_ = P("port")
            pts = [(px_ + 10 + 120 * math.sin(t / 8 * math.pi / 2), py_ - 40 - 90 * (1 - math.cos(t / 8 * math.pi / 2))) for t in range(9)]
            curved_arrow(pd, pts, 12, 32)
            # The small case is easy to miss in the print: ringed in red, as the bench rings its parts.
            pd.ellipse([px_ - 30, py_ - 52, px_ + 30, py_ + 8], outline=INK, width=8)
            pd.ellipse([px_ - 30, py_ - 52, px_ + 30, py_ + 8], outline=RED, width=4)
            mouse(pd, pw - 70, ph - 92, "left", 1.0)

        burst(pd, (96, 62), word, 52, sfx if len(word) < 7 else font("impact.ttf", 36), rot=random.random())

        # Each panel alone as well: the bench's side panel shows the step to do now with its picture (fnc_open).
        framed = pic.copy()
        ImageDraw.Draw(framed).rectangle([0, 0, pw - 1, ph - 1], outline=INK, width=6)
        STEPS[name] = framed

        page.paste(pic, (x, y))
        d.rectangle([x, y, x + pw, y + ph], outline=INK, width=6)
        caption(d, (x, y + ph - 2, x + pw, y + ph + capH), i + 1, text, cap, num)

    # Two more for the side panel only: a dud waited out at the muzzle, and a double feed's round pulled out.
    pic, (kx, ky) = ink(RENDERS / "r_tap.png", (pw, ph))
    pd = ImageDraw.Draw(pic)
    cx, cy = pw - 95, 105
    pd.ellipse([cx - 60, cy - 60, cx + 60, cy + 60], fill=(250, 244, 226), outline=INK, width=8)
    pd.line([(cx, cy), (cx, cy - 42)], fill=INK, width=8)
    pd.line([(cx, cy), (cx + 30, cy + 14)], fill=RED, width=8)
    pd.rectangle([cx - 12, cy - 78, cx + 12, cy - 62], fill=INK)
    mouse(pd, pw - 70, ph - 92, "left", 1.0)
    burst(pd, (110, 62), "HANG ON!", 40, font("impact.ttf", 34), rot=0.2)
    ImageDraw.Draw(pic).rectangle([0, 0, pw - 1, ph - 1], outline=INK, width=6)
    STEPS["r_wait"] = pic

    pic, (kx, ky) = ink(RENDERS / "r_chamber.png", (pw, ph))
    pd = ImageDraw.Draw(pic)
    ccx, ccy = sp["r_chamber"]["chamber"]
    ccx, ccy = ccx * kx, ccy * ky
    for j, (dx, dy) in enumerate([(-18, 0), (22, 10)]):
        rx, ry = ccx + dx, ccy + dy - 30
        pd.rounded_rectangle([rx - 9, ry - 34, rx + 9, ry + 14], radius=8, fill=(214, 168, 70), outline=INK, width=4)
    arrow(pd, (ccx + 30, ccy - 75), (ccx + 120, ccy - 160))
    mouse(pd, pw - 70, ph - 92, "left", 1.0)
    burst(pd, (100, 62), "PLINK!", 46, sfx, rot=0.6)
    ImageDraw.Draw(pic).rectangle([0, 0, pw - 1, ph - 1], outline=INK, width=6)
    STEPS["r_pull"] = pic

    # The weapon cleared, for the side panel's last card: the rack's render with a green tick and "READY!".
    pic, _ = ink(RENDERS / "r_rack.png", (pw, ph))
    pd = ImageDraw.Draw(pic)
    green = (40, 130, 60)
    pd.line([(pw - 170, ph - 120), (pw - 120, ph - 60), (pw - 40, ph - 190)], fill=INK, width=30, joint="curve")
    pd.line([(pw - 170, ph - 120), (pw - 120, ph - 60), (pw - 40, ph - 190)], fill=green, width=18, joint="curve")
    burst(pd, (110, 62), "READY!", 46, sfx, rot=0.3)
    ImageDraw.Draw(pic).rectangle([0, 0, pw - 1, ph - 1], outline=INK, width=6)
    STEPS["r_cleared"] = pic

    # The strip at the bottom.
    d.line([640, H - 54, W - 40, H - 54], fill=INK, width=3)
    d.text((640, H - 46), "MH WEAPON MALFUNCTIONS  //  FIELD NOTES", font=small, fill=INK)

    page = roughen(page)
    return page


def main():
    OUT.mkdir(exist_ok=True)
    page = build()
    png = OUT / "manual.png"
    page.save(png)
    print(png)
    if "--paa" in sys.argv:
        PAA.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run([str(IMAGE_TO_PAA), str(png), str(PAA)], check=True)
        print(PAA)
        # The panels for the side panel, 512 x 512 (the game shows them at their own shape again).
        for name, pic in STEPS.items():
            step_png = OUT / f"step_{name[2:]}.png"
            roughen(pic.convert("RGB")).resize((512, 512), Image.LANCZOS).save(step_png)
            step_paa = PAA.parent / f"step_{name[2:]}_co.paa"
            subprocess.run([str(IMAGE_TO_PAA), str(step_png), str(step_paa)], check=True)
            print(step_paa)


if __name__ == "__main__":
    main()
