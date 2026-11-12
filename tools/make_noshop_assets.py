# Mail icon (home_bg) aur "+" (coin bars) hata kar NAYI files banata hai. Originals ko nahi chhoota.
import sys
from PIL import Image
root = sys.argv[1]
y0, y1, x0 = int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])

# ---- home_bg_nomail.jpg
bg = Image.open(f"{root}/ui/home_bg.jpg").convert("RGB")
W, H = bg.size
px = bg.load()
ref = x0 - 6
top = [tuple(a - b for a, b in zip(px[x, y0], px[ref, y0])) for x in range(W)]
bot = [tuple(a - b for a, b in zip(px[x, y1], px[ref, y1])) for x in range(W)]
for y in range(y0 + 1, y1):
    t = (y - y0) / (y1 - y0)
    left = px[ref, y]
    for x in range(x0, W):
        px[x, y] = left
bg.save(f"{root}/ui/home_bg_nomail.jpg", quality=92)

# ---- coin bars without plus
def noplus(name, out):
    im = Image.open(f"{root}/ui/{name}").convert("RGBA")
    w, h = im.size
    src = im.load()
    S = 4
    big = Image.new("RGBA", (w * S, h * S))
    bp = big.load()
    strip_x, keep_x = 299, 300
    top_b, bot_b, ring = 21, 163, 5
    r = (bot_b - top_b) / 2.0
    cy = (top_b + bot_b) / 2.0
    end_x = 545
    cx = end_x - r
    bgcol = src[300, 3]
    white = (249, 248, 254, 255)
    for Y in range(h * S):
        y = (Y + 0.5) / S
        for X in range(keep_x * S, w * S):
            x = (X + 0.5) / S
            strip = src[strip_x, min(h - 1, int(y))]
            if x <= cx:
                col = strip
            else:
                d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                col = strip if d <= r - ring else (white if d <= r else bgcol)
            bp[X, Y] = col
    small = big.resize((w, h), Image.LANCZOS)
    for x in range(keep_x, int(cx)):
        for y in range(h):
            src[x, y] = src[strip_x, y]
    im.paste(small.crop((int(cx), 0, w, h)), (int(cx), 0))
    im.save(f"{root}/ui/{out}")

noplus("coinbar_home.png", "coinbar_home_noplus.png")
noplus("coinbar.png", "coinbar_noplus.png")
