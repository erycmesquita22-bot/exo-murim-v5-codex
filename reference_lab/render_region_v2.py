#!/usr/bin/env python3
"""Offscreen render of the *actual RegionSynth heightfield and placements*.
This is an external preview, NOT a Godot gameplay screenshot.
"""
import os,sys,json,math,hashlib
from functools import lru_cache
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFont
import vtk
from vtk.util.numpy_support import numpy_to_vtk
from world_genesis_v2 import plan
from region_synth_v2 import generate,validate

HERE=Path(__file__).resolve().parent
SOURCE=HERE/'assets'
MESH_ROOT=SOURCE/'GLB'
TEX_PATHS={0:SOURCE/'01_SOLOS'/'grama_viva.png',1:SOURCE/'01_SOLOS'/'trilha_batida.png',2:SOURCE/'01_SOLOS'/'rocha_cinza.png',3:SOURCE/'01_SOLOS'/'solo_florestal.png'}
TEX={k:np.asarray(Image.open(p).convert('RGB').resize((96,96),Image.Resampling.NEAREST)) for k,p in TEX_PATHS.items()}
BIOMES_TREES={'alpine':0.35,'rocky_highlands':.65,'grassland':.75,'dry_valley':.30,'wetland':1.3,'bamboo_forest':1.65,'mixed_woodland':1.2,'temperate_forest':1.45}

def make_surface(reg):
 n=reg.height.shape[0];scale=reg.extent/(n-1)
 pts=np.zeros((n*n,3),dtype=np.float32)
 z,x=np.mgrid[:n,:n];pts[:,0]=(x*scale).ravel();pts[:,1]=reg.height.ravel();pts[:,2]=(z*scale).ravel()
 tris=np.empty(((n-1)*(n-1)*2,4),dtype=np.int64);idx=0
 for yy in range(n-1):
  for xx in range(n-1):
   a=yy*n+xx;b=a+1;c=a+n;d=c+1
   tris[idx]=[3,a,c,b];tris[idx+1]=[3,b,c,d];idx+=2
 data=vtk.vtkPolyData();vpoints=vtk.vtkPoints();vpoints.SetData(numpy_to_vtk(pts,deep=True));data.SetPoints(vpoints)
 ca=vtk.vtkCellArray();ca.SetCells(len(tris),numpy_to_vtk(tris.ravel(),deep=True,array_type=vtk.VTK_ID_TYPE));data.SetPolys(ca)
 colors=np.zeros((n,n,3),dtype=np.float32)
 for mat in range(4):
  yy,xx=np.where(reg.materials==mat)
  colors[yy,xx]=TEX[mat][(yy*11+xx*5)%96,(xx*7+yy*13)%96]
 # Continuous painted earth/grass blending: center road texture plus soft verge.
 grass=TEX[0][(z*11+x*5)%96,(x*7+z*13)%96].astype(float)
 dirt=TEX[1][(z*17+x*7)%96,(x*9+z*5)%96].astype(float)
 bw=np.clip(reg.blend,0,1)
 colors=colors*(1-bw[:,:,None])+(dirt*.93)*(bw[:,:,None]);
 # Stone exposures become visible in high slopes.
 gy,gx=np.gradient(reg.height);normal=np.hypot(gy,gx)
 stone=TEX[2][(z*7+x*3)%96,(x*11+z*13)%96].astype(float)
 rock=np.clip((normal-1.8)/3,0,.7)
 colors=colors*(1-rock[:,:,None])+stone*(rock[:,:,None]);colors=np.clip(colors,0,255).astype('uint8')
 vcolors=numpy_to_vtk(colors.reshape(-1,3),deep=True,array_type=vtk.VTK_UNSIGNED_CHAR)
 vcolors.SetNumberOfComponents(3);vcolors.SetName('Albedo pixelado EXO')
 data.GetPointData().SetScalars(vcolors)
 meshmapper=vtk.vtkPolyDataMapper();meshmapper.SetInputData(data);meshmapper.SetColorModeToDirectScalars();meshmapper.SetScalarModeToUsePointData()
 actor=vtk.vtkActor();actor.SetMapper(meshmapper);actor.GetProperty().SetInterpolationToFlat();actor.GetProperty().SetAmbient(.32)
 return actor


def cube(center,scale,rgb):
 src=vtk.vtkCubeSource();src.SetXLength(scale[0]);src.SetYLength(scale[1]);src.SetZLength(scale[2]);src.Update()
 mp=vtk.vtkPolyDataMapper();mp.SetInputConnection(src.GetOutputPort())
 act=vtk.vtkActor();act.SetMapper(mp);act.SetPosition(*center)
 act.GetProperty().SetColor(*[v/255 for v in rgb]);act.GetProperty().SetDiffuse(.74);act.GetProperty().SetAmbient(.26)
 act.GetProperty().SetInterpolationToFlat()
 return act


@lru_cache(None)
def source_mesh(key):
    """Read actual EXO environmental GLB, preserving exported vertex colors."""
    import trimesh
    file=MESH_ROOT/(key+'.glb')
    meshes=[g for g in trimesh.load(file,force='scene').dump() if isinstance(g,trimesh.Trimesh)]
    combined=trimesh.util.concatenate(meshes)
    vertices=np.asarray(combined.vertices,dtype=float)
    faces=np.asarray(combined.faces,dtype=np.int64)
    colors=np.asarray(combined.visual.vertex_colors[:,:3],dtype=np.uint8)
    return vertices,faces,colors


def colored_mesh_actor(vertices,faces,colors):
    data=vtk.vtkPolyData(); points=vtk.vtkPoints()
    points.SetData(numpy_to_vtk(np.asarray(vertices,dtype=np.float32),deep=True));data.SetPoints(points)
    packed=np.column_stack((np.full(len(faces),3,dtype=np.int64),faces.astype(np.int64)))
    carr=vtk.vtkCellArray();carr.SetCells(len(faces),numpy_to_vtk(packed.ravel(),deep=True,array_type=vtk.VTK_ID_TYPE));data.SetPolys(carr)
    vcolors=numpy_to_vtk(np.asarray(colors,dtype=np.uint8),deep=True,array_type=vtk.VTK_UNSIGNED_CHAR)
    vcolors.SetNumberOfComponents(3);data.GetPointData().SetScalars(vcolors)
    mapper=vtk.vtkPolyDataMapper();mapper.SetInputData(data);mapper.SetScalarModeToUsePointData();mapper.SetColorModeToDirectScalars()
    actor=vtk.vtkActor();actor.SetMapper(mapper);actor.GetProperty().SetInterpolationToFlat();actor.GetProperty().SetAmbient(.45)
    return actor


def glb_actor(key,base=(0,0,0),size=(1,1,1)):
    vertices,faces,colors=source_mesh(key)
    v=vertices*np.asarray(size)[None,:]+np.asarray(base)[None,:]
    return colored_mesh_actor(v,faces,colors)


def grouped_glb_actor(instances):
    verts=[];faces=[];colors=[];offset=0
    for key,pos,scale in instances:
        v,f,c=source_mesh(key)
        vi=v*np.asarray(scale)[None,:]+np.asarray(pos)[None,:]
        verts.append(vi);faces.append(f+offset);colors.append(c)
        offset+=len(v)
    return colored_mesh_actor(np.vstack(verts),np.vstack(faces),np.vstack(colors))


def draw_house(render,reg,b,rng):
 n=reg.height.shape[0];scale=reg.extent/(n-1);cy,cx=b['center'];x=cx*scale;z=cy*scale;y=float(reg.height[cy,cx]);
 length=(b['halfsize']*2+.2)*scale*.80;depth=length*.77;bh=max(6, .32*length)
 stone=(106,107,96); wood=(104,75,56)
 render.AddActor(cube((x,y+.6,z),(length+2,1.2,depth+2),stone))
 render.AddActor(cube((x,y+bh/2,z),(length,bh,depth),(173,149,124)))
 for dx in [-length*.44,length*.44]:
  for dz in [-depth*.45,depth*.45]:
   render.AddActor(cube((x+dx,y+bh*.50,z+dz),(1.4,bh,1.4),wood))
 # Front door and small square windows, fully voxel-shaped.
 render.AddActor(cube((x,y+bh*.23,z+depth*.501),(length*.17,bh*.46,.24),(76,57,44)))
 for dx in (-length*.28,length*.28):
  render.AddActor(cube((x+dx,y+bh*.66,z+depth*.502),(length*.14,bh*.19,.26),(65,90,90)))
 # Roof comes from actual existing modular Murim 4 m GLBs (scaled to lot).
 roof='telhado_teal_4m' if rng.random()<.60 else 'telhado_vermelho_4m'
 sx=length*1.20/4.8;sz=depth*1.24/4.8;sy=bh*.30/1.20
 render.AddActor(glb_actor(roof,(x,y+bh-.8*sy,z),(sx,sy,sz)))
 render.AddActor(cube((x,y+bh+sy*1.45,z),(length*.93,.80,1.20),(73,54,49)))


def draw_ruin(render,reg,b):
 n=reg.height.shape[0];scale=reg.extent/(n-1);cy,cx=b['center'];x=cx*scale;z=cy*scale;y=float(reg.height[cy,cx]);s=b['halfsize']*scale*1.5
 render.AddActor(cube((x,y+.7,z),(s*1.8,1.4,s*1.3),(119,121,109)))
 for dx in (-s*.72, s*.72):
  for dz in (-s*.50, s*.50):
   height=5+(abs(dx+dz)*.17)%3
   render.AddActor(cube((x+dx,y+height/2,z+dz),(2.8,height,2.8),(104,108,101)))
 # Original broken-wall and pillar GLBs placed on the terrace.
 render.AddActor(glb_actor('parede_ruina_destruido',(x-s*.38,y+1,z+s*.5),(max(.8,s/5),1.55,1.25)))
 render.AddActor(glb_actor('pilar_ruina_quebrado',(x+s*.43,y+1,z-s*.3),(1.5,2.2,1.5)))


def render(seed=101,output=None,cells=112,region_id=None):
 world=plan(seed);rid=world['start_region'] if region_id is None else int(region_id);reg=generate(world,rid,cells=cells)
 report=validate(reg)
 assert report['ok'],report
 rr=vtk.vtkRenderer();rr.SetBackground(.066,.105,.13)
 rr.AddActor(make_surface(reg))
 rng=np.random.default_rng(seed)
 scale=reg.extent/(cells-1)
 for b in reg.buildings:
  if b['module_style']=='murim_voxel':draw_house(rr,reg,b,rng)
  else:draw_ruin(rr,reg,b)
 biome=world['regions'][rid]['biome'];keep=BIOMES_TREES.get(biome,1)
 types={'bamboo_forest':['bambu_grupo_rio','bambu_alto_folhas'],
        'temperate_forest':['arvore_alta_sombria','arvore_baixa_prado','arvore_grande'],
        'mixed_woodland':['arvore_alta_sombria','arvore_baixa_prado','pinheiro_escarpado'],
        'rocky_highlands':['pinheiro_escarpado','arvore_baixa_prado'],
        'alpine':['pinheiro_escarpado'],
        'grassland':['arvore_baixa_prado','arvore_grande'],
        'wetland':['bambu_grupo_rio','arvore_alta_sombria'],
        'dry_valley':['arvore_baixa_prado']}[biome]
 instances=[]
 for y,x in reg.plants:
  if rng.random()>keep/1.65:continue
  worldx=x*scale;worldz=y*scale;ground=float(reg.height[y,x]);
  ty=types[int(rng.integers(0,len(types)))]
  size=float(rng.uniform(2.4,4.5))
  instances.append((ty,(worldx,ground,worldz),(size,size,size)))
 if instances:rr.AddActor(grouped_glb_actor(instances))
 # Boundary gates: stone pylons located at the actual shared passage coordinates.
 for gate in reg.portals:
  y,x=gate['cell'];ground=float(reg.height[y,x]);px=x*scale;pz=y*scale
  rr.AddActor(cube((px,ground+5,pz),(4,10,4),(172,145,111)))
 # Framing
 rw=vtk.vtkRenderWindow();rw.SetOffScreenRendering(True);rw.AddRenderer(rr);rw.SetSize(1400,1080)
 cam=rr.GetActiveCamera();cam.SetFocalPoint(256,20,256);cam.SetPosition(700,690,800);cam.SetViewUp(0,1,0);cam.SetClippingRange(2,2500)
 rr.SetActiveCamera(cam)
 rr.ResetCameraClippingRange()
 light=vtk.vtkLight();light.SetLightTypeToSceneLight();light.SetPosition(1000,1300,600);light.SetFocalPoint(256,0,256);light.SetIntensity(1.1);rr.AddLight(light)
 rr.AmbientOn() if hasattr(rr,'AmbientOn') else None
 rw.Render()
 grab=vtk.vtkWindowToImageFilter();grab.SetInput(rw);grab.Update()
 writer=vtk.vtkPNGWriter();out=Path(output or HERE/f'DEPOIS_regiao_seed_{seed}.png');writer.SetFileName(str(out));writer.SetInputConnection(grab.GetOutputPort());writer.Write()
 im=Image.open(out).convert('RGB')
 d=ImageDraw.Draw(im,'RGBA');d.rectangle((24,22,855,145),fill=(9,24,28,225));
 font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',22)
 small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',16)
 d.text((47,35),f'EXO WORLD GENESIS  •  REGIÃO {rid:02d}',fill=(245,228,194),font=font)
 d.text((47,77),f'DEPOIS  ·  SEED {seed}  ·  {biome.upper()}  ·  {len(reg.portals)} SAÍDAS',fill=(207,225,207),font=small)
 d.text((47,108),'Prévia geométrica externa • não é captura da Godot',fill=(174,195,192),font=small)
 im.save(out)
 # Mesh-only heightfield GLB for independent inspection. Surfaces real, assets
 # in this preview generated by modular actor assembler and may be extended.
 import trimesh
 yy,xx=np.mgrid[:cells,:cells]
 vertices=np.column_stack((xx.ravel()*scale,reg.height.ravel(),yy.ravel()*scale))
 f=[]
 for y in range(cells-1):
  for x in range(cells-1):
   a=y*cells+x;f.extend(((a,a+cells,a+1),(a+1,a+cells,a+cells+1)))
 mesh=trimesh.Trimesh(vertices=vertices,faces=f,process=False)
 mesh.export(str(out.with_suffix('.glb')))
 return out,report

if __name__=='__main__':
 seed=int(sys.argv[1]) if len(sys.argv)>1 else 101
 rid=int(sys.argv[2]) if len(sys.argv)>2 else None
 out,rep=render(seed,region_id=rid,output=HERE/f'DEPOIS_regiao_seed_{seed}_r{rid}.png' if rid is not None else None)
 print(out,json.dumps(rep))
