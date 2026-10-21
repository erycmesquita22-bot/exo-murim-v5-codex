"""Small comparison reel made from the very same source recordings used in the game."""
from pathlib import Path
import subprocess,array,math,json
p=Path(__file__).resolve().parents[1]
rate=44100;duration=14;mix=[0.0]*(rate*duration)
tracks=[(.3,'foley/knifeSlice',.33),(1.4,'foley/knifeSlice2',.33),(1.49,'foley/impactSoft_medium_000',.39),(2.8,'foley/cloth1',.33),(2.89,'foley/impactPunch_heavy_000',.39),(3.8,'foley/cloth2',.33),(3.89,'foley/impactPunch_heavy_001',.39),(5.0,'foley/impactMetal_light_000',.25),(5.65,'foley/bow_release_1',.3),(6.1,'foley/footstep00',.12),(6.6,'foley/footstep01',.12),(7.1,'foley/footstep02',.12),(8.2,'exo_audio/spell_charge',.29),(9.3,'exo_audio/eco_eco_fogo',.39),(11.1,'exo_audio/eco_eco_gelo',.39)]
for start,name,gain in tracks:
 data=subprocess.check_output(['ffmpeg','-v','error','-i',str(p/'assets'/(name+'.ogg')),'-f','f32le','-ar',str(rate),'-ac','1','-'])
 values=array.array('f');values.frombytes(data)
 offset=int(start*rate)
 for i,value in enumerate(values):
  if offset+i<len(mix):mix[offset+i]+=value*gain
peak=max(abs(v) for v in mix);factor=min(1.0,.89/max(peak,1e-6))
raw=array.array('f',(v*factor for v in mix)).tobytes()
output=p/'previas/audio-combate.ogg'
subprocess.run(['ffmpeg','-v','error','-y','-f','f32le','-ar',str(rate),'-ac','1','-i','-','-c:a','libvorbis','-q:a','6',str(output)],input=raw,check=True)
(p/'previas/audio-combate.txt').write_text('Amostra dos arquivos usados no jogo, combinada para comparação; não é uma captura de gameplay.\n0,3 s: lâmina no ar\n1,4 s: lâmina e contato no corpo\n2,8 / 3,8 s: tecido e socos\n5 s: contato metálico\n5,65 s: disparo de arco\n6,1–7,1 s: passos\n8,2–12 s: carga e técnicas do EXO\nSem narração.\n')
print(output,'peak',round(peak*factor,3))
