# home_bg.jpg mein chhape UI (coin bar, gear, mail, level up, Play) mita kar
# ui/home_bg_clean.jpg banata hai. Original ko nahi chhoota.
#   python3 -I tools/make_home_clean.py <project_root>
import sys
from PIL import Image

root = sys.argv[1]
im = Image.open(f"{root}/ui/home_bg.jpg").convert("RGB")
W, H = im.size
px = im.load()


def fill_between(x0, x1, y0, y1, left_x, right_x):
    """Har row mein left_x aur right_x ke rang ke beech seedha blend (aasmaan/badal ke liye)."""
    for y in range(y0, y1):
        a = px[left_x, y]
        b = px[right_x, y]
        for x in range(x0, x1):
            t = (x - left_x) / max(1, right_x - left_x)
            px[x, y] = tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


# Coin bar (upar daayein)
fill_between(612, 1080, 8, 160, 606, W - 1)
# Gear + Mail + Level Up (daayein patti)
fill_between(888, 1080, 790, 1372, 882, W - 1)

# Play button: uske upar wali row ko neeche tak khinch do (pedestal + badal seedhe neeche jaate hain)
src_y = 1548
for y in range(src_y + 1, H):
    for x in range(168, 900):
        px[x, y] = px[x, src_y]

im.save(f"{root}/ui/home_bg_clean.jpg", quality=92)
print("saved ui/home_bg_clean.jpg", im.size)
