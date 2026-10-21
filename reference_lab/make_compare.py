from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
B=Path('/mnt/data/exo_forge/baseline');P=Path(__file__).parent
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',34)
sub=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',19)
for title,left,right,filename in [
('EXO · MUNDO REGIONAL / SEED 816204',B/'ANTES_seed_816204_atlas.png',P/'DEPOIS_atlas_seed_816204.png','COMPARATIVO_ATLAS.png'),
('EXO · MAPA LOCAL / SEED 101',B/'ANTES_seed_101_regiao.png',P/'DEPOIS_regiao_seed_101.png','COMPARATIVO_REGIAO.png')]:
 W,H=1760,900;out=Image.new('RGB',(W,H),(12,22,26));d=ImageDraw.Draw(out)
 d.text((42,24),title,font=font,fill=(237,222,193));
 for k,f in enumerate([left,right]):
  im=Image.open(f).convert('RGB'); im.thumbnail((845,740))
  x=25+k*885+(845-im.width)//2;y=118+(740-im.height)//2
  out.paste(im,(x,y))
  d.text((40+k*885,84),'ANTES · Versão anterior' if k==0 else 'DEPOIS · Forjamento V2',font=sub,fill=(232,216,180) if k==0 else (159,235,208))
 d.text((40,862),'Imagens originadas dos respectivos geradores; mapas locais não usam exatamente a mesma escala nem o mesmo renderizador.',font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',14),fill=(172,193,190))
 outfile=P/filename;out.save(outfile,optimize=True);print(outfile)
