"""Draws the Couch TV app icon (TV app and phone remote) at every size they need.

    .venv/bin/python scripts/make-icons.py

A dusk gradient like the TV home's scenes, a soft TV glow, and a white couch. Full-bleed squares:
iOS, Android (maskable) and LG round the corners themselves; the couch stays inside the middle 70%.
Needs Pillow (pip install pillow).
"""
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S = 1024  # drawn large, then scaled down smoothly


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient():
    # diagonal: deep violet (top left) -> rose -> warm orange (bottom right)
    stops = [(0.0, (58, 28, 120)), (0.45, (190, 70, 150)), (1.0, (255, 150, 90))]
    img = Image.new("RGB", (S, S))
    px = img.load()
    for y in range(S):
        for x in range(S):
            t = (x * 0.45 + y * 0.55) / S
            for (t0, c0), (t1, c1) in zip(stops, stops[1:]):
                if t <= t1:
                    px[x, y] = lerp(c0, c1, (t - t0) / (t1 - t0))
                    break
            else:
                px[x, y] = stops[-1][1]
    return img.convert("RGBA")


def rr(d, box, r, fill):
    d.rounded_rectangle(box, radius=r, fill=fill)


def icon():
    img = gradient()

    # the TV's glow behind the couch: a soft bright screen
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    rr(g, (262, 210, 762, 520), 46, (255, 236, 210, 150))
    glow = glow.filter(ImageFilter.GaussianBlur(60))
    img = Image.alpha_composite(img, glow)

    # the screen itself: a thin rounded frame, with a stand
    d = ImageDraw.Draw(img)
    rr(d, (300, 236, 724, 492), 34, (255, 255, 255, 60))
    rr(d, (318, 254, 706, 474), 24, (40, 14, 70, 90))
    # a crescent moon in the screen's night sky (drawn on its own layer, the bite cut out)
    moon = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    md = ImageDraw.Draw(moon)
    md.ellipse((560, 290, 630, 360), fill=(255, 244, 220, 240))
    md.ellipse((585, 278, 652, 345), fill=(0, 0, 0, 0))
    img = Image.alpha_composite(img, moon)

    # the couch: shadow first, then back, seat, arms and legs in white
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse((210, 770, 814, 840), fill=(30, 0, 40, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    img = Image.alpha_composite(img, shadow)

    d = ImageDraw.Draw(img)
    white = (255, 255, 255, 255)
    soft = (255, 240, 236, 255)
    rr(d, (300, 520, 724, 680), 56, soft)           # back rest
    rr(d, (236, 600, 356, 780), 50, white)          # left arm
    rr(d, (668, 600, 788, 780), 50, white)          # right arm
    rr(d, (322, 650, 702, 760), 36, white)          # seat
    d.line((512, 662, 512, 748), fill=(230, 200, 210, 255), width=8)   # cushion seam
    rr(d, (276, 770, 312, 812), 10, white)          # legs
    rr(d, (712, 770, 748, 812), 10, white)
    return img


def save(img, path, size):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.resize((size, size), Image.LANCZOS).convert("RGB").save(path, optimize=True)
    print(f"wrote {os.path.relpath(path, ROOT)} ({size}x{size})")


if __name__ == "__main__":
    art = icon()
    save(art, os.path.join(ROOT, "lg", "app", "icon.png"), 80)
    save(art, os.path.join(ROOT, "lg", "app", "largeIcon.png"), 130)
    save(art, os.path.join(ROOT, "remote", "public", "icons", "icon-192.png"), 192)
    save(art, os.path.join(ROOT, "remote", "public", "icons", "icon-512.png"), 512)
    save(art, os.path.join(ROOT, "remote", "public", "icons", "apple-touch-icon.png"), 180)
    save(art, os.path.join(ROOT, "build", "icon-preview.png"), 512)
