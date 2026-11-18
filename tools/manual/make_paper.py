"""The paper of the bench's side panel (addons/workbench/ui/paper_co.paa): the same yellowed print paper as the field manual
(make_manual.py) - grain, darker worn edges, a faint fold - so Observation, Last action and Procedure read like a page of
it. Text and boxes are drawn on it in the game.

    python tools/manual/make_paper.py   -> tools/manual/out/paper.png and addons/workbench/ui/paper_co.paa
"""
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from make_manual import IMAGE_TO_PAA, OUT, PAPER, PAPER_DARK, REPO

W, H = 512, 1024
PAA = REPO / "addons" / "workbench" / "ui" / "paper_co.paa"


def main():
    rng = np.random.default_rng(5)
    page = Image.new("RGB", (W, H), PAPER)

    # Worn edges: darker towards the rim.
    vign = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vign)
    for i in range(40):
        vd.rectangle([i, i, W - 1 - i, H - 1 - i], outline=int(170 * (1 - i / 40)))
    page.paste(PAPER_DARK, mask=vign.filter(ImageFilter.GaussianBlur(14)))

    # A fold across the middle, light on one side, shade on the other.
    fold = Image.new("L", (W, H), 0)
    fd = ImageDraw.Draw(fold)
    fd.line([0, H * 0.52, W, H * 0.5], fill=90, width=3)
    page.paste((205, 190, 155), mask=fold.filter(ImageFilter.GaussianBlur(2)))

    # Grain and a few spots.
    a = np.asarray(page).astype(np.int16)
    a += rng.normal(0, 6, a.shape[:2]).astype(np.int16)[..., None]
    for _ in range(18):
        x, y, r = rng.integers(0, W), rng.integers(0, H), rng.integers(2, 7)
        yy, xx = np.ogrid[:H, :W]
        a[(xx - x) ** 2 + (yy - y) ** 2 <= r * r] -= 14
    page = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))

    OUT.mkdir(exist_ok=True)
    png = OUT / "paper.png"
    page.save(png)
    subprocess.run([str(IMAGE_TO_PAA), str(png), str(PAA)], check=True)
    print(PAA)


if __name__ == "__main__":
    main()
