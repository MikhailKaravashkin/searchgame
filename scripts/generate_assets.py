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
    model = os.getenv("OPENAI_IMAGE_MODEL", "gpt-image-1")

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

    # Many image models support this; if unsupported, API will ignore or error.
    if transparent:
        payload["background"] = "transparent"

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
                "Cute kawaii farm scene, panoramic wide illustration, pastel colors, "
                "cats and pandas playing together, windmill in background, red barn, "
                "pond with lily pads, flower gardens, detailed but not cluttered, "
                "game background art style, soft warm lighting, "
                "no text, no watermark"
            ),
        ),
        ImageSpec(
            name="duck",
            filename="duck.png",
            size="1024x1024",
            transparent=True,
            prompt=(
                "Single cute rubber duck, game asset sprite, side view profile, "
                "classic yellow color with orange beak, soft studio lighting, "
                "kawaii style, clean simple design, "
                "no text, no watermark"
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
