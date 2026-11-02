# Setzt die Haare aus koerper_aussen auf die Innen-Ebenen (Organe, Knochen, Adern, Muskeln, Umriss),
# damit die Zöpfe nicht als hautfarbene Flächen erscheinen. Aufruf: python3 tools/koerper_haare.py <Original-Ordner> <Ziel-Ordner>
# Braucht numpy, pillow und scipy. Nur auf Hermes-Originale anwenden (nicht zweimal).
import sys, numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as nd
src, outdir = sys.argv[1], sys.argv[2]
a = Image.open(src + "/koerper_aussen.png").convert("RGBA")
A = np.array(a).astype(float)
hsv = np.array(a.convert("RGB").convert("HSV")).astype(float) / 255
h, s, v = hsv[..., 0] * 360, hsv[..., 1], hsv[..., 2]
H, W = h.shape
yy = np.repeat((np.arange(H) / H)[:, None], W, 1)
m = (h > 5) & (h < 42) & (s > 0.38) & (v < 0.85) & (A[..., 3] > 128) & (yy < 0.27)
m = nd.binary_closing(m, iterations=2)
lab, n = nd.label(m)
sizes = nd.sum(m, lab, range(1, n + 1))
hair = np.isin(lab, [i + 1 for i, sz in enumerate(sizes) if sz > 6000])
hair |= (A[..., 3] > 20) & (yy < 0.095)          # Scheitel ganz oben ist immer Haar
hair = nd.binary_fill_holes(nd.binary_closing(hair, iterations=8))
hair &= A[..., 3] > 20
xx = np.repeat((np.arange(W) / W)[None, :], H, 0)
for name in ["organe", "knochen", "adern", "muskeln", "umriss"]:
    Li = Image.open(f"{src}/koerper_{name}.png").convert("RGBA")
    L = np.array(Li).astype(float)
    # Grundfarbe der leeren Silhouette (Mitte des linken Zopfs)
    base = L[int(0.15 * H), int(0.31 * W), :3]
    plain = (np.abs(L[..., :3] - base).sum(-1) < 45) & (L[..., 3] > 20)
    plain = nd.binary_opening(plain, iterations=2)
    plain = nd.binary_dilation(plain, iterations=14) & (L[..., 3] > 0)   # heller Rand der Silhouette gehört dazu
    content = (~(np.abs(L[..., :3] - base).sum(-1) < 45)) & (L[..., 3] > 200)
    content = nd.binary_opening(content, iterations=3)
    if name == 'knochen': content &= yy > 0.12
    plain &= ~nd.binary_dilation(content & (yy > 0.02) & ~nd.binary_dilation((L[..., 3] < 200), iterations=18), iterations=2)
    if name == 'knochen': plain |= yy < 0.12
    m2 = hair & plain
    mask = Image.fromarray((m2 * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(1.5))
    M = np.array(mask).astype(float)[..., None] / 255
    out = L * (1 - M) + A * M
    Image.fromarray(out.clip(0, 255).astype("uint8"), "RGBA").save(f"{outdir}/koerper_{name}.png")
    print(name, base.astype(int))
