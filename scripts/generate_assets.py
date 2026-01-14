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


def remove_near_white_background(png_bytes: bytes, threshold: int = 245) -> bytes:
    """Fallback: make near-white pixels transparent."""
    from io import BytesIO

    im = Image.open(BytesIO(png_bytes)).convert("RGBA")
    pixels = im.load()
    w, h = im.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if r >= threshold and g >= threshold and b >= threshold:
                pixels[x, y] = (r, g, b, 0)

    out = BytesIO()
    im.save(out, format="PNG")
    return out.getvalue()


def write_png(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    print(f"Wrote {path.relative_to(ROOT)} ({len(data)/1024:.1f} KB)")


def main() -> None:
    load_dotenv(ROOT / ".env")

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
            name="duck",
            filename="duck.png",
            size="1024x1024",
            transparent=True,
            prompt=(
                "Single cute tiny duck in simple schematic cartoon style, "
                "very soft pastel colors (pale yellow, soft peach), "
                "delicate thin black outline, flat colors without gradients, "
                "2D side view profile, minimal simple shapes, subtle and gentle, "
                "blends with pastel background, children's book style, on white background"
            ),
        ),
    ]

    for spec in specs:
        print(f"Generating {spec.name} ({spec.size})...")
        png = openai_images_generate(spec.prompt, spec.size, transparent=spec.transparent)

        # If transparency isn't present (or unsupported), try to post-process for sprites.
        if spec.transparent:
            try:
                from io import BytesIO

                _ = Image.open(BytesIO(png)).convert("RGBA")
                # Strip near-white background unconditionally; cheap and safe.
                png = remove_near_white_background(png)
            except Exception:
                # If Pillow can't read it, still write raw bytes
                pass

        write_png(OUT_DIR / spec.filename, png)


if __name__ == "__main__":
    main()
