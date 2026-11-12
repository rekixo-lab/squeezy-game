# Bina alpha wali button PNGs (screenshot se kaati gayi) ka bahari background transparent karta hai.
# Tarika: image ke kinaaron se "flood fill" jo rang ke tez badlaav (button ka outline) par ruk jaata hai,
# phir kinare par 1-2 px ka soft alpha aur rang ki safai (background ka rang edge se hatana).
#   python3 -I tools/alpha_fix.py <project_root> name1.png name2.png:c ...   (:c = sirf kono se seed, :r = + gol mask; X_p.png ko X.png wala mask milta hai)
# Original pehle ui/_orig/ mein copy hota hai (agar wahan pehle se nahi hai).
import os
import shutil
import sys
from collections import deque

from PIL import Image, ImageFilter

STEP_TOL = 26.0      # do padosi pixels mein itna farq = abhi bhi background
SEED_TOL = 150.0     # seed (border) rang se itna door tak hi jaana


def dist(a, b):
    return ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2) ** 0.5


def make_mask(path, corners_only=False, round_mask=False):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    px = im.load()
    bg = bytearray(w * h)          # 1 = background
    seed_col = {}
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            q.append((x, y))
    if corners_only:
        # Gol icon jo kinaare chhoota hai: sirf woh border pixels seed jo kisi kone ke rang jaise hon
        cc = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
        q = deque(p for p in q if min(dist(px[p], k) for k in cc) <= 45.0)
    for (x, y) in q:
        bg[y * w + x] = 1
        seed_col[(x, y)] = px[x, y]
    origin = {}
    for p in q:
        origin[p] = px[p]
    while q:
        x, y = q.popleft()
        c = px[x, y]
        o = origin[(x, y)]
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not bg[ny * w + nx]:
                n = px[nx, ny]
                if dist(n, c) <= STEP_TOL and dist(n, o) <= SEED_TOL:
                    bg[ny * w + nx] = 1
                    origin[(nx, ny)] = o
                    q.append((nx, ny))

    # Mask: 255 = button. Thoda smooth karke soft edge.
    mask = Image.new("L", (w, h))
    mp = mask.load()
    for y in range(h):
        for x in range(w):
            mp[x, y] = 0 if bg[y * w + x] else 255
    if round_mask:
        # Gol button: beech ke gole ke bahar sab hatao
        from PIL import ImageDraw
        r = min(w, h) / 2.0 - 1.0
        circ = Image.new("L", (w, h), 0)
        ImageDraw.Draw(circ).ellipse((w / 2 - r, h / 2 - r, w / 2 + r, h / 2 + r), fill=255)
        from PIL import ImageChops
        mask = ImageChops.multiply(mask, circ)
    # bahar ke chhote dhabbe hatao
    mask = mask.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
    return mask


def apply(path, out_path, mask):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    px = im.load()
    mp = mask.load()
    bg = bytearray(w * h)
    for y in range(h):
        for x in range(w):
            bg[y * w + x] = 1 if mp[x, y] < 128 else 0
    soft = mask.filter(ImageFilter.GaussianBlur(1.0))
    sp = soft.load()

    # Edge pixels se background ka rang hatao (decontaminate)
    out = Image.new("RGBA", (w, h))
    op = out.load()
    # har pixel ke liye paas ka background rang: bg pixels ka blur
    bgimg = Image.new("RGB", (w, h))
    bp = bgimg.load()
    for y in range(h):
        for x in range(w):
            bp[x, y] = px[x, y] if bg[y * w + x] else (0, 0, 0)
    bgw = Image.new("L", (w, h))
    bwp = bgw.load()
    for y in range(h):
        for x in range(w):
            bwp[x, y] = 255 if bg[y * w + x] else 0
    bgimg = bgimg.filter(ImageFilter.BoxBlur(3))
    bgw = bgw.filter(ImageFilter.BoxBlur(3))
    bbp = bgimg.load()
    bwp = bgw.load()
    for y in range(h):
        for x in range(w):
            a = sp[x, y] / 255.0
            c = px[x, y]
            if 0.0 < a < 1.0 and bwp[x, y] > 0:
                k = 255.0 / bwp[x, y]
                b = tuple(min(255.0, bbp[x, y][i] * k) for i in range(3))
                c = tuple(int(max(0, min(255, (c[i] - (1 - a) * b[i]) / max(a, 0.05)))) for i in range(3))
            op[x, y] = (c[0], c[1], c[2], int(round(a * 255)))
    out.save(out_path)


def main():
    root = sys.argv[1]
    ui = os.path.join(root, "ui")
    orig = os.path.join(ui, "_orig")
    os.makedirs(orig, exist_ok=True)
    open(os.path.join(orig, ".gdignore"), "a").close()
    masks = {}
    for arg in sys.argv[2:]:
        name, _, mode = arg.partition(":")     # ":c" = sirf kono se seed, ":r" = + gol mask
        src = os.path.join(ui, name)
        bak = os.path.join(orig, name)
        if not os.path.exists(bak):
            shutil.copy2(src, bak)
        base = name.replace("_p.png", ".png")
        if name.endswith("_p.png") and base in masks:
            mask = masks[base]                  # dabaya hua version = normal wala hi shape
        else:
            mask = make_mask(bak, "c" in mode or "r" in mode, "r" in mode)   # hamesha original se
        masks[name] = mask
        apply(bak, src, mask)
        print("fixed", name)


main()
