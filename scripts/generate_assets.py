#!/usr/bin/env python3
"""Generate game assets (background + sprites) using OpenAI Images API.

Outputs:
- SearchGame/Resources/Generated/bg_farm_day.png
- SearchGame/Resources/Generated/duck.png (transparent if supported)

Usage:
  python3 -m venv .venv
  source .venv/bin/activate
  pip install -r requirements.txt
  cp .env.example .env
  # edit .env with OPENAI_API_KEY
  python scripts/generate_assets.py

Notes:
- The script tries to request transparent background for sprites.
- If the model doesn't support transparency, it will post-process by removing near-white background.
"""

from __future__ import annotations

import base64
import argparse
import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Optional

import requests
from dotenv import load_dotenv
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "SearchGame" / "Resources" / "Generated"
OUT_DIR.mkdir(parents=True, exist_ok=True)


@dataclass
class ImageSpec:
    name: str
    filename: str
    prompt: str
    size: str
    transparent: bool = False


def _env(name: str, default: Optional[str] = None) -> str:
    v = os.getenv(name)
    if v is None or v.strip() == "":
        if default is None:
            raise SystemExit(f"Missing required env var: {name}")
        return default
    return v


def openai_images_generate(prompt: str, size: str, transparent: bool) -> bytes:
    """Call OpenAI Images API (REST) and return PNG bytes.

This is intentionally REST-based to avoid SDK churn.
"""

    api_key = _env("OPENAI_API_KEY")
    model = os.getenv("OPENAI_IMAGE_MODEL", "dall-e-3")

    url = "https://api.openai.com/v1/images/generations"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }

    payload: dict[str, Any] = {
        "model": model,
        "prompt": prompt,
        "size": size,
        "n": 1,
    }

    # DALL-E 3 doesn't support transparent backgrounds natively
    # We'll post-process with remove_near_white_background instead

    r = requests.post(url, headers=headers, data=json.dumps(payload), timeout=120)
    if r.status_code >= 400:
        raise RuntimeError(f"OpenAI Images API error {r.status_code}: {r.text}")

    data = r.json()
    item = (data.get("data") or [None])[0]
    if not item:
        raise RuntimeError(f"Unexpected response: {data}")

    if "b64_json" in item and item["b64_json"]:
        return base64.b64decode(item["b64_json"])

    if "url" in item and item["url"]:
        img = requests.get(item["url"], timeout=120)
        img.raise_for_status()
        return img.content

    raise RuntimeError(f"Unexpected response item: {item}")


def _corner_patch_rgb(im: Image.Image, patch: int = 12) -> list[tuple[int, int, int]]:
    """Collect RGB samples from 4 corner patches."""
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    coords = [
        (0, 0),
        (w - patch, 0),
        (0, h - patch),
        (w - patch, h - patch),
    ]
    out: list[tuple[int, int, int]] = []
    for x0, y0 in coords:
        for y in range(max(0, y0), min(h, y0 + patch)):
            for x in range(max(0, x0), min(w, x0 + patch)):
                r, g, b, a = px[x, y]
                # treat fully transparent as white-ish for sampling purposes
                if a == 0:
                    out.append((255, 255, 255))
                else:
                    out.append((r, g, b))
    return out


def _median_rgb(samples: list[tuple[int, int, int]]) -> tuple[int, int, int]:
    if not samples:
        return (255, 255, 255)
    rs = sorted(s[0] for s in samples)
    gs = sorted(s[1] for s in samples)
    bs = sorted(s[2] for s in samples)
    mid = len(samples) // 2
    return (rs[mid], gs[mid], bs[mid])


def _background_looks_solid_white(im: Image.Image) -> bool:
    """Heuristic: corners must be near pure-white and consistent (reject grid/preview)."""
    samples = _corner_patch_rgb(im, patch=14)
    bg = _median_rgb(samples)
    # near-white threshold
    if min(bg) < 248:
        return False
    # consistency: corner patches close-ish to bg (reject noisy corners)
    close = 0
    for r, g, b in samples:
        if abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) <= 18:
            close += 1
    if close / max(1, len(samples)) < 0.92:
        return False

    # additionally sample border pixels around the whole image (reject grids/checkerboards)
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    step = max(8, min(w, h) // 80)  # ~80 samples per side
    total = 0
    ok = 0

    def is_near_white(r: int, g: int, b: int) -> bool:
        return r >= 250 and g >= 250 and b >= 250

    for x in range(0, w, step):
        for y in (0, h - 1):
            r, g, b, a = px[x, y]
            total += 1
            if a == 0 or is_near_white(r, g, b):
                ok += 1
    for y in range(0, h, step):
        for x in (0, w - 1):
            r, g, b, a = px[x, y]
            total += 1
            if a == 0 or is_near_white(r, g, b):
                ok += 1

    return ok / max(1, total) >= 0.98


def _remove_background_from_edges(png_bytes: bytes) -> bytes:
    """Remove solid background by flood-fill from image edges.

This preserves internal white details (e.g. mushroom spots), unlike naive "remove all white".
"""
    from collections import deque
    from io import BytesIO

    im = Image.open(BytesIO(png_bytes)).convert("RGBA")
    w, h = im.size
    px = im.load()

    # Estimate background color from corners (median).
    bg = _median_rgb(_corner_patch_rgb(im, patch=16))

    # Mark as background if it's close to bg color OR looks like neutral background.
    # This is intentionally forgiving to handle "grid"/"checkerboard" artifacts.
    dist_thr = 28

    def is_bg(x: int, y: int) -> bool:
        r, g, b, a = px[x, y]
        if a == 0:
            return True

        # Close to inferred corner background.
        if (abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2])) <= dist_thr:
            return True

        # Neutral/bright heuristic (helps remove gray grid lines).
        mx = max(r, g, b)
        mn = min(r, g, b)
        sat = mx - mn
        lum = (299 * r + 587 * g + 114 * b) // 1000

        if lum >= 235:
            return True
        if sat <= 18 and lum >= 110:
            return True
        return False

    visited = bytearray(w * h)

    def idx(x: int, y: int) -> int:
        return y * w + x

    q: deque[tuple[int, int]] = deque()

    # Seed with border pixels matching background.
    for x in range(w):
        if is_bg(x, 0):
            q.append((x, 0))
        if is_bg(x, h - 1):
            q.append((x, h - 1))
    for y in range(h):
        if is_bg(0, y):
            q.append((0, y))
        if is_bg(w - 1, y):
            q.append((w - 1, y))

    while q:
        x, y = q.popleft()
        i = idx(x, y)
        if visited[i]:
            continue
        if not is_bg(x, y):
            continue
        visited[i] = 1

        r, g, b, a = px[x, y]
        px[x, y] = (r, g, b, 0)

        if x > 0:
            q.append((x - 1, y))
        if x + 1 < w:
            q.append((x + 1, y))
        if y > 0:
            q.append((x, y - 1))
        if y + 1 < h:
            q.append((x, y + 1))

    def keep_largest_alpha_component(image: Image.Image) -> Image.Image:
        """Remove small disconnected blobs (e.g. dropped shadow / grass) keeping the main object."""
        image = image.convert("RGBA")
        w2, h2 = image.size
        px2 = image.load()

        def alpha_at(x: int, y: int) -> int:
            return px2[x, y][3]

        from collections import deque

        visited2 = bytearray(w2 * h2)

        def idx2(x: int, y: int) -> int:
            return y * w2 + x

        comps: list[tuple[int, tuple[int, int]]] = []

        for yy in range(h2):
            for xx in range(w2):
                if alpha_at(xx, yy) == 0:
                    continue
                ii = idx2(xx, yy)
                if visited2[ii]:
                    continue
                # BFS to count component size
                q2: deque[tuple[int, int]] = deque([(xx, yy)])
                visited2[ii] = 1
                size = 0
                while q2:
                    x, y = q2.popleft()
                    if alpha_at(x, y) == 0:
                        continue
                    size += 1
                    if x > 0:
                        ni = idx2(x - 1, y)
                        if not visited2[ni]:
                            visited2[ni] = 1
                            q2.append((x - 1, y))
                    if x + 1 < w2:
                        ni = idx2(x + 1, y)
                        if not visited2[ni]:
                            visited2[ni] = 1
                            q2.append((x + 1, y))
                    if y > 0:
                        ni = idx2(x, y - 1)
                        if not visited2[ni]:
                            visited2[ni] = 1
                            q2.append((x, y - 1))
                    if y + 1 < h2:
                        ni = idx2(x, y + 1)
                        if not visited2[ni]:
                            visited2[ni] = 1
                            q2.append((x, y + 1))
                comps.append((size, (xx, yy)))

        if not comps:
            return image

        comps.sort(key=lambda t: t[0], reverse=True)
        _, seed = comps[0]

        # Mark pixels to keep (largest component)
        keep = bytearray(w2 * h2)
        qk: deque[tuple[int, int]] = deque([seed])

        while qk:
            x, y = qk.popleft()
            if alpha_at(x, y) == 0:
                continue
            ii = idx2(x, y)
            if keep[ii]:
                continue
            keep[ii] = 1
            if x > 0:
                qk.append((x - 1, y))
            if x + 1 < w2:
                qk.append((x + 1, y))
            if y > 0:
                qk.append((x, y - 1))
            if y + 1 < h2:
                qk.append((x, y + 1))

        # Remove everything not in largest component.
        for yy in range(h2):
            row_off = yy * w2
            for xx in range(w2):
                if alpha_at(xx, yy) == 0:
                    continue
                if not keep[row_off + xx]:
                    r, g, b, a = px2[xx, yy]
                    px2[xx, yy] = (r, g, b, 0)

        return image

    im = keep_largest_alpha_component(im)

    def has_large_base(image: Image.Image) -> bool:
        """Reject sprites that include a wide 'ground/shadow' base."""
        image = image.convert("RGBA")
        alpha = image.split()[-1]
        w3, h3 = image.size
        px3 = alpha.load()
        # Look at bottom 8% rows
        start_y = int(h3 * 0.92)
        thresh_row = int(w3 * 0.38)
        for y in range(start_y, h3):
            count = 0
            for x in range(w3):
                if px3[x, y] > 0:
                    count += 1
            if count >= thresh_row:
                return True
        return False

    # If model still draws a ground/shadow base, reject so caller can retry.
    if has_large_base(im):
        raise RuntimeError("Sprite contains a wide ground/shadow base; retrying generation.")

    # Trim transparent borders to keep sprites tight.
    alpha = im.split()[-1]
    bbox = alpha.getbbox()
    if bbox:
        margin = 3
        x0, y0, x1, y1 = bbox
        x0 = max(0, x0 - margin)
        y0 = max(0, y0 - margin)
        x1 = min(w, x1 + margin)
        y1 = min(h, y1 + margin)
        im = im.crop((x0, y0, x1, y1))

    out = BytesIO()
    im.save(out, format="PNG")
    return out.getvalue()


def write_png(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    print(f"Wrote {path.relative_to(ROOT)} ({len(data)/1024:.1f} KB)")


def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Generate SearchGame assets via OpenAI Images API.")
    p.add_argument(
        "--only",
        default="",
        help="Comma-separated asset names to generate (e.g. duck,mushroom). Empty = all.",
    )
    p.add_argument("--max-retries", type=int, default=3, help="Max retries per asset.")
    p.add_argument(
        "--skip-existing",
        action="store_true",
        help="Skip assets that already exist in output directory.",
    )
    return p.parse_args()


def main() -> None:
    load_dotenv(ROOT / ".env")
    args = _parse_args()
    only = {s.strip() for s in args.only.split(",") if s.strip()}

    default_bg_size = os.getenv("OPENAI_IMAGE_SIZE", "1792x1024")

    specs = [
        ImageSpec(
            name="bg_farm_day",
            filename="bg_farm_day.png",
            size=default_bg_size,
            transparent=False,
            prompt=(
                "Cute kawaii village scene panoramic illustration in simple cartoon style, "
                "pastel colors (soft pink, mint green, baby blue, pale yellow), "
                "many small details filling entire frame: tiny houses, cats in profile, "
                "pandas, puppies, flowers, trees, all drawn with thick black outlines, "
                "flat colors without gradients or shading, 2D schematic style, "
                "densely packed with cute characters and tiny scenes everywhere, "
                "simple shapes, children's book illustration style, "
                "no text, no watermark"
            ),
        ),
        ImageSpec(
            name="bg_forest_evening",
            filename="bg_forest_evening.png",
            size=default_bg_size,
            transparent=False,
            prompt=(
                "Cute kawaii forest evening scene panoramic illustration in simple cartoon style, "
                "soft pastel colors (lavender, peach, mint, pale pink), "
                "many small details: tiny mushrooms, cats, pandas, trees, flowers, houses, "
                "all drawn with thick black outlines, flat colors no gradients, "
                "2D schematic style, densely packed scene, warm sunset lighting, "
                "children's book style, no text, no watermark"
            ),
        ),
        # === SEARCHABLE ITEMS (match bg_farm_day kawaii style) ===
        ImageSpec(
            name="cat_white",
            filename="cat_white.png",
            size="1024x1024",
            transparent=True,
            prompt=(
                "Single tiny cute white cat, simple kawaii style like children's book, "
                "thick black outline, flat white body, pink cheeks, dot eyes, no gradients, "
                "2D side profile, sitting, centered, FLOATING, "
                "SOLID PURE WHITE BACKGROUND ONLY, NO shadow, NO ground, clean vector style"
            ),
        ),
        ImageSpec(
            name="basket",
            filename="basket.png",
            size="1024x1024",
            transparent=True,
            prompt=(
                "Single tiny cute woven basket with apples, simple kawaii style, "
                "thick black outline, flat brown basket, pastel red apples, no gradients, "
                "2D front view, centered, FLOATING, "
                "SOLID PURE WHITE BACKGROUND ONLY, NO shadow, NO ground, clean vector style"
            ),
        ),
        ImageSpec(
            name="flower_pink",
            filename="flower_pink.png",
            size="1024x1024",
            transparent=True,
            prompt=(
                "Single tiny cute pink flower with short green stem, simple kawaii style, "
                "thick black outline, flat pastel pink petals, yellow center, no gradients, "
                "2D front view, centered, FLOATING, "
                "SOLID PURE WHITE BACKGROUND ONLY, NO shadow, NO ground, clean vector style"
            ),
        ),
        ImageSpec(
            name="panda",
            filename="panda.png",
            size="1024x1024",
            transparent=True,
            prompt=(
                "Single tiny cute panda, simple kawaii style like children's book, "
                "thick black outline, flat white and black, pink cheeks, dot eyes, no gradients, "
                "2D front view, sitting, centered, FLOATING, "
                "SOLID PURE WHITE BACKGROUND ONLY, NO shadow, NO ground, clean vector style"
            ),
        ),
        # === ANIMATED DECORATIONS ===
        ImageSpec(
            name="cloud",
            filename="cloud.png",
            size="1024x1024",
            transparent=True,
            prompt=(
                "Single simple white fluffy cloud, kawaii style, "
                "thick black outline, flat white color, no gradients, "
                "2D view, centered, FLOATING, "
                "SOLID PURE WHITE BACKGROUND ONLY, NO shadow, clean vector style"
            ),
        ),
        ImageSpec(
            name="bird",
            filename="bird.png",
            size="1024x1024",
            transparent=True,
            prompt=(
                "Single tiny cute bird flying, simple kawaii style, "
                "thick black outline, flat pastel blue body, orange beak, no gradients, "
                "2D side view, wings spread, centered, FLOATING, "
                "SOLID PURE WHITE BACKGROUND ONLY, NO shadow, clean vector style"
            ),
        ),
    ]

    for spec in specs:
        if only and spec.name not in only:
            continue
        out_path = OUT_DIR / spec.filename
        if args.skip_existing and out_path.exists():
            print(f"Skipping {spec.name} (already exists)")
            continue

        print(f"Generating {spec.name} ({spec.size})...")
        last_err: Optional[Exception] = None
        for attempt in range(1, max(1, args.max_retries) + 1):
            try:
                png = openai_images_generate(spec.prompt, spec.size, transparent=spec.transparent)

                # For sprites: validate background and convert it to transparency.
                if spec.transparent:
                    from io import BytesIO

                    # Convert background to transparency by edge flood-fill. This preserves internal whites.
                    # We *try* to request solid white in prompts, but still post-process robustly.
                    png = _remove_background_from_edges(png)

                write_png(out_path, png)
                last_err = None
                break
            except Exception as e:
                last_err = e
                if attempt < args.max_retries:
                    print(f"  Attempt {attempt}/{args.max_retries} failed: {e}")
                    continue
                break

        if last_err is not None:
            raise SystemExit(f"Failed to generate {spec.name}: {last_err}")


if __name__ == "__main__":
    main()
