"""Evidence: evaluates actual glTF skinning and named animation, rasterizes skinned vertices."""
from pathlib import Path
import sys,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from scipy.spatial.transform import Rotation
from build_harmonizacao import parse_glb,raw_accessor,OUT
from render_glb import render

def mtransform(t,r,s):
 out=np.eye(4);out[:3,:3]=Rotation.from_quat(r).as_matrix()*np.asarray(s)[None,:];out[:3,3]=t;return out

def eval_pose(doc,bb,name,seconds):
 nodes=doc['nodes'];animation=next(x for x in doc['animations'] if x['name']==name)
 trans=[list(n.get('translation',[0,0,0])) for n in nodes];rots=[list(n.get('rotation',[0,0,0,1])) for n in nodes];scales=[list(n.get('scale',[1,1,1])) for n in nodes]
 for ch in animation['channels']:
  s=animation['samplers'][ch['sampler']];ts=raw_accessor(doc,bb,s['input'])[:,0];vals=raw_accessor(doc,bb,s['output']);t=float(seconds);index=np.searchsorted(ts,t,side='right')-1;index=max(0,min(len(ts)-2,index));alpha=(t-ts[index])/max(1.e-6,ts[index+1]-ts[index]);value=vals[index]*(1-alpha)+vals[index+1]*alpha
  idx=ch['target']['node'];path=ch['target']['path']
  if path=='rotation':rots[idx]=(value/np.linalg.norm(value)).tolist()
  if path=='translation':trans[idx]=value.tolist()
  if path=='scale':scales[idx]=value.tolist()
 local=[mtransform(t,r,s) for t,r,s in zip(trans,rots,scales)];parents={}
 for i,node in enumerate(nodes):
  for child in node.get('children',[]):parents[child]=i
 cache={}
 def globalmat(i):
  if i in cache:return cache[i]
  m=local[i]
  if i in parents:m=globalmat(parents[i])@m
  cache[i]=m;return m
 skin=doc['skins'][0];inv=raw_accessor(doc,bb,skin['inverseBindMatrices']).astype(np.float64).reshape(-1,4,4).transpose(0,2,1)
 mats=np.stack([globalmat(j)@inv[k] for k,j in enumerate(skin['joints'])])
 prim=doc['meshes'][0]['primitives'][0];attrs=prim['attributes'];pos=raw_accessor(doc,bb,attrs['POSITION']).astype(float);jts=raw_accessor(doc,bb,attrs['JOINTS_0']).astype(int);weights=raw_accessor(doc,bb,attrs['WEIGHTS_0']).astype(float);v=np.column_stack([pos,np.ones(len(pos))])
 posed=np.zeros((len(pos),4))
 for k in range(4):posed+=np.einsum('nij,nj->ni',mats[jts[:,k]],v)*weights[:,k,None]
 return posed[:,:3]

preview=OUT/'evidencias';preview.mkdir(exist_ok=True)
for id,source,clip in [('wolf','art02','walk'),('boar','art02','walk'),('tiger','art02','attack'),('snake','forge','walk')]:
 f=OUT/'models'/id/(source+'.glb');doc,bb=parse_glb(f.read_bytes());dur=float(raw_accessor(doc,bb,next(a for a in doc['animations'] if a['name']==clip)['samplers'][0]['input'])[-1,0]);frames=[]
 for i in range(12):
  seconds=i/12*dur
  verts=eval_pose(doc,bb,clip,seconds)
  im=render(f,width=380,height=300,vertices_override=verts)
  dr=ImageDraw.Draw(im);dr.rectangle((0,0,380,28),fill=(18,23,34));dr.text((10,7),f'{id.upper()}  |  {clip.upper()}  |  GLB rig real',fill=(236,231,214));frames.append(im)
 outfile=preview/(id+'-'+clip+'-ANIMACAO-GLB.gif')
 frames[0].save(outfile,save_all=True,append_images=frames[1:],duration=100,loop=0,optimize=True)
 print('GIF',outfile.name,outfile.stat().st_size)
