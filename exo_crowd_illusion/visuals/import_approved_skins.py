#!/usr/bin/env python3
"""Pack up to 64 cleared 64x64 PNG classic skins into one atlas.
Use ONLY the EXO project's approved, commercially owned assets.
The program never downloads any asset or edits the source files.
"""
import argparse
from PIL import Image
from pathlib import Path

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--approved-dir',type=Path,required=True,help='Folder with 64x64 cleared PNGs')
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--commercial-clearance-confirmed',action='store_true',required=True)
    args=p.parse_args()
    items=sorted(args.approved_dir.glob('*.png'))[:64]
    if not items:
        p.error('No approved PNGs found')
    canvas=Image.new('RGBA',(512,512),(0,0,0,0))
    for i in range(64):
        file=items[i % len(items)]
        with Image.open(file) as skin:
            if skin.size!=(64,64):
                p.error(f'{file.name}: expected 64x64')
            canvas.paste(skin.convert('RGBA'),((i%8)*64,(i//8)*64))
    args.output.parent.mkdir(parents=True,exist_ok=True)
    canvas.save(args.output)
    print(f'Packed {len(items)} commercially cleared skin images: {args.output}')

if __name__=='__main__':
    main()
