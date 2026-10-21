#!/usr/bin/env python3
"""Derive repeat-safe, detail-preserving EXO terrain tiles from approved originals.

Source textures are NEVER overwritten. Requires Pillow and NumPy at build time only;
Godot needs no Python dependencies at runtime. Run from any working directory.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "textures" / "tiles"
DEST = ROOT / "textures" / "terrain_approved"
# Eight biome substrates and an approved trail. All originate from the owner-approved atlas.
TILES = {
    "grama_prado": "grama_prado",
    "solo_floresta": "solo_floresta",
    "solo_bambuzal": "solo_bambuzal",
    "grama_seca": "grama_seca",
    "grama_umida": "grama_umida",
    "rocha_cinza": "rocha_cinza",
    "grama_montanha": "grama_montanha",
    "grama_folhas_largas": "grama_folhas_largas",
    "trilha_terra": "trilha_terra",
}

def periodic_edges(arr: np.ndarray, axis: int, blend_fraction: float = .18) -> np.ndarray:
    """Match opposite borders while leaving the central 64% of image unmodified.

    A paired smooth correction spreads each edge discrepancy over the outer band,
    instead of flipping/mirroring the art or pasting obvious repeated strips.
    """
    a = np.swapaxes(arr, 0, axis).copy()
    n = a.shape[0]
    band = max(12, round(n * blend_fraction))
    diff = .5 * (a[-1].copy() - a[0].copy())
    for i in range(band):
        u = i / float(band - 1)
        s = 1.0 - (u * u * (3.0 - 2.0 * u))
        a[i] += s * diff
        a[-1 - i] -= s * diff
    return np.swapaxes(a, 0, axis)

def main():
    DEST.mkdir(parents=True, exist_ok=True)
    records=[]
    for name, basename in TILES.items():
        source = SOURCE / f"{basename}.png"
        assert source.is_file(), source
        img=Image.open(source).convert('RGB')
        pixels=np.asarray(img, dtype=np.float32)
        safe=periodic_edges(periodic_edges(pixels, axis=1), axis=0)
        safe=np.clip(np.round(safe),0,255).astype(np.uint8)
        target=DEST / f"{name}.png"
        Image.fromarray(safe,'RGB').save(target,optimize=True)
        out=np.asarray(Image.open(target).convert('RGB'),dtype=np.int16)
        assert np.array_equal(out[:,0],out[:,-1]), f"X border seam: {name}"
        assert np.array_equal(out[0],out[-1]), f"Y border seam: {name}"
        center=img.crop((round(img.width*.2),round(img.height*.2),round(img.width*.8),round(img.height*.8)))
        new_center=Image.open(target).crop((round(img.width*.2),round(img.height*.2),round(img.width*.8),round(img.height*.8)))
        assert center.tobytes()==new_center.tobytes(), f"Central artwork altered: {name}"
        records.append({
            'source':str(source.relative_to(ROOT)),'target':str(target.relative_to(ROOT)),
            'dimensions':list(img.size),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
            'target_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
            'average_absolute_change':round(float(np.abs(safe.astype(np.float32)-pixels).mean()),3),
            'edge_pixels_identical':True,'center_preserved':True,
        })
    (DEST/'MANIFEST.json').write_text(json.dumps({'method':'paired smooth opposite-edge correction',
        'source_unchanged':True,'tiles':records},indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print(f"PASS: {len(records)} approved detailed textures made repeat-safe (center preserved).")
    for rec in records:print(rec['target'],rec['dimensions'],'avg delta',rec['average_absolute_change'])

if __name__ == '__main__':main()
