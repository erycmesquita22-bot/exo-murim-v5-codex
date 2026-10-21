#!/usr/bin/env python3
"""EXO: deterministic independent prototype for regional voxel test scenes.
Produces procedural logically-grounded previews, material atlases and GLB scenes.
No Minecraft/third-party copyrighted textures are included; uses EXO Collection 02.
"""
import os, json, math, random, hashlib, pathlib
from functools import lru_cache
import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageFilter
import scipy.ndimage as ndi
import trimesh
from scipy.interpolate import interp1d
import vtk
from vtk.util import numpy_support as ns

BASE=pathlib.Path(__file__).resolve().parent/'source_assets'
OUT=pathlib.Path(__file__).resolve().parent
OUT.mkdir(exist_ok=True)
(OUT/'previews').mkdir(exist_ok=True)
(OUT/'maps').mkdir(exist_ok=True)
(OUT/'scenes').mkdir(exist_ok=True)
(OUT/'textures').mkdir(exist_ok=True)
W=D=56; TILE=32; STEP=0.44
# All materials are original from EXO Collection 02.
MATS=['grama_prado','grama_viva','grama_montanha','terra_castanha','trilha_batida','solo_florestal','terra_pedregosa','pedra_xisto','rocha_cinza','musgo_ruina','lajes_ruina_cinza','relva_bambu']
MAT_IDS={s:i for i,s in enumerate(MATS)}

@lru_cache(None)
def tex(name):
 path=BASE/'01_SOLOS'/f'{name}.png'
 if not path.exists():
  path=BASE/'03_PISOS'/f'{name}.png'
 if not path.exists():
  path=BASE/'01_SOLOS'/f'grama_viva.png'
 return Image.open(path).convert('RGB').resize((32,32),Image.Resampling.NEAREST)

NEW_ASSETS=OUT/'new_assets'
NEW_ASSETS.mkdir(exist_ok=True)

def create_roof_voxel(style='jade'):
    # Novel voxel modular roof, not based on a proprietary model or texture.
    import itertools
    meshes=[]
    pal=([(57,110,112),(60,125,124),(45,90,102),(81,140,135)] if style=='jade' else
         [(148,65,53),(172,70,56),(124,52,51),(187,93,63)])
    def cube(center,extents,col):
        m=trimesh.creation.box(extents=extents)
        m.apply_translation(center)
        m.visual.vertex_colors=np.tile(np.array([*col,255],dtype=np.uint8), (len(m.vertices),1))
        meshes.append(m)
    # Blocks form an old-style curved east Asian roof; peak ridge along X.
    for i in range(-6,7):
        for j in range(-6,7):
            # roof overhang, stepped rise to central ridge (not a smooth polygon).
            y=.06+.11*(6-abs(j))+.08*max(0,abs(i)-4)*(abs(j)/6)
            col=pal[(i*37+j*19)%len(pal)]
            cube((i*.44,y,j*.44),(.43,.16,.43),col)
            if j in (-6,6):
                cube((i*.44,y-.10,j*.44),(.44,.09,.14),(54,48,44))
    for i in range(-6,7):
        cube((i*.44,.90,0),(.44,.22,.31),(58,49,45))
    for i in (-6,6):
        for j in (-6,6):
            cube((i*.44,.40,j*.44),(.20,.30,.20),(197,144,78))
    combined=trimesh.util.concatenate(meshes)
    # concatenate() retains face color / vertex colors after joining
    (NEW_ASSETS/f'telhado_voxel_{style}.glb').write_bytes(trimesh.Scene(combined).export(file_type='glb'))

def create_lantern_voxel():
    meshes=[]
    for center,ext,col in [((0,1.1,0),(.14,2.2,.14),(57,51,47)),((0,2.24,0),(.6,.12,.6),(53,52,49)),
                           ((0,1.75,0),(.42,.60,.42),(224,173,103)),((0,1.42,0),(.54,.10,.54),(60,49,40))]:
        m=trimesh.creation.box(extents=ext);m.apply_translation(center)
        m.visual.vertex_colors=np.tile(np.array([*col,255],dtype=np.uint8),(len(m.vertices),1));meshes.append(m)
    combined=trimesh.util.concatenate(meshes)
    (NEW_ASSETS/'lanterna_voxel.glb').write_bytes(trimesh.Scene(combined).export(file_type='glb'))

def create_groundcover_voxel():
    parts=[]
    greens=[(77,106,66),(92,123,71),(113,136,78),(82,118,82)]
    for i,(x,z,height) in enumerate([(-.17,-.08,.48),(.03,.07,.36),(.21,-.02,.52),(-.05,.20,.30)]):
        m=trimesh.creation.box(extents=[.07,height,.07])
        m.apply_translation([x,height/2,z])
        m.visual.vertex_colors=np.tile(np.array([*greens[i],255],dtype=np.uint8),(len(m.vertices),1))
        parts.append(m)
    (NEW_ASSETS/'tufo_grama_voxel.glb').write_bytes(trimesh.Scene(trimesh.util.concatenate(parts)).export(file_type='glb'))

@lru_cache(None)
def meshasset(name):
 f=NEW_ASSETS/(name+'.glb')
 if f.exists():
  s=trimesh.load(str(f),force='scene');return [g.copy() for g in s.dump() if isinstance(g,trimesh.Trimesh)]
 for section in ['09_TOPOGRAFIA_GLB','10_ARQUITETURA_GLB','11_RUINAS_GLB','12_NATUREZA_GLB','06_OBJETOS_GLB/objetos','06_OBJETOS_GLB/vegetacao','06_OBJETOS_GLB/rochas','06_OBJETOS_GLB/construcoes']:
  f=BASE/section/(name+'.glb')
  if f.exists():
   s=trimesh.load(str(f),force='scene')
   return [g.copy() for g in s.dump() if isinstance(g,trimesh.Trimesh)]
 raise FileNotFoundError(name)

def newheight(seed,variant):
    """Composed height fields: large coherent landforms, mid hill noise and restrained micro-detail.
    No cellular stairs/quantized plateaus on traversable ground. Angled rock modules supply hard cliffs.
    """
    rng=np.random.default_rng(seed)
    zz,xx=np.mgrid[:D,:W]
    def layer(sigma,amplitude):
        n=ndi.gaussian_filter(rng.normal(size=(D,W)),sigma,mode='reflect')
        return n / max(0.0001,float(n.std())) * amplitude
    macro=layer(12,.45); middle=layer(5,.47); micro=layer(1.6,.12)
    if variant=='aldeia':
        # Sheltered basin with two distinct rocky uplands; central village stays gently rolling.
        left=7.4*np.exp(-((xx-2)/7.8)**2)*(0.84+0.16*np.cos(zz/8))
        north=5.9*np.exp(-((zz-3)/8.5)**2)*(0.80+.20*np.sin(xx/9+1))
        far=3.8*np.exp(-((xx-53)/8.0)**2)
        h=2.15+macro+middle+micro+left+north+far
    elif variant=='bambu':
        riverline=14+3.8*np.sin(zz/10+seed*.03)
        river=1.7*np.exp(-((xx-riverline)/4.2)**2)
        bank=5.6*np.exp(-((zz-3)/9.0)**2)
        eastern=5.0*np.exp(-((xx-53)/9.0)**2)
        h=2.6+macro*.8+middle*.85+micro+bank+eastern-river
    else:
        # Actual tall massif behind rocky ruins, not a meadow with tiny spikes.
        main=10.2*np.exp(-((xx-(48+0.15*(zz-24)))/8.0)**2)
        crags=7.6*np.exp(-((zz-3)/10.5)**2)
        spur=5*np.exp(-((xx-10)**2+(zz-12)**2)/230)
        h=2.1+macro*.8+middle+micro+main+crags+spur
    return np.clip(h,.65,16.0)

def linetrack(p,q,rng):
 # Smooth wandering curve with 3 controls, still 4-connected after rasterization
 p=np.array(p,float); q=np.array(q,float)
 perp=np.array([-(q-p)[1],(q-p)[0]])
 perp/=max(.0001,np.linalg.norm(perp))
 off=rng.uniform(-2.0,2.0)
 pts=[]
 for t in np.linspace(0,1,140):
  bend=math.sin(math.pi*t)*off*perp
  loc=(1-t)*p+t*q+bend
  pts.append(tuple(np.round(loc).astype(int)))
 line=[]
 for u,v in pts:
  if not line:line.append((u,v));continue
  xx,yy=line[-1]
  while xx!=u or yy!=v:
   if abs(xx-u)>abs(yy-v):xx+=int(np.sign(u-xx))
   else:yy+=int(np.sign(v-yy))
   line.append((xx,yy))
 return line

def make(seed,variant):
 rng=random.Random(seed)
 h=newheight(seed,variant)
 center=(rng.randint(22,33),rng.randint(23,33))
 entrances=[(0,rng.randint(18,37)),(W-1,rng.randint(17,37)),(rng.randint(16,38),0)]
 if variant=='ruinas':center=(rng.randint(20,26),rng.randint(27,33))
 if variant=='bambu':center=(rng.randint(22,31),rng.randint(24,30))
 pts=[center]+entrances
 pathpts=[]
 for pt in entrances:pathpts.extend(linetrack(center,pt,rng))
 road=np.zeros((D,W),bool)
 for x,z in pathpts:
  if 0<=x<W and 0<=z<D:road[z,x]=True
 road=ndi.binary_dilation(road,iterations=1)
 # Place explicit flat, connected village lots and ruins before environment spawn
 buildings=[]; occupied=np.zeros((D,W),bool)
 if variant=='aldeia':proposals=[(center[0]-7,center[1]+1,'jade'),(center[0]+6,center[1]+6,'vermelho'),(center[0]+4,center[1]-7,'jade')]
 elif variant=='bambu':proposals=[(center[0]-7,center[1]+3,'jade'),(center[0]+7,center[1]-3,'jade')]
 else:proposals=[(center[0]+6,center[1]+4,'vermelho')]
 for x0,z0,style in proposals:
  # Choose a nearby road-accessible site without paving THROUGH the building.
  candidates=[(x0+dx,z0+dz) for dx,dz in [(0,0),(3,0),(-3,0),(0,3),(0,-3),(-4,-3),(-4,3),(4,-3),(4,3),(-6,0),(6,0),(0,-6),(0,6),(7,5),(-7,-5),(-7,5),(7,-5)]]
  for x,z in candidates:
   x=int(np.clip(x,7,W-8));z=int(np.clip(z,7,D-8))
   if occupied[z-5:z+6,x-5:x+6].any():continue
   if road[z-3:z+4,x-3:x+4].any():continue
   if np.min(ndi.distance_transform_edt(~road)[z-4:z+5,x-4:x+5])>9:continue
   buildings.append({'x':x,'z':z,'style':style,'kind':'building'})
   occupied[z-4:z+5,x-4:x+5]=True
   break
 ruinpoints=[]
 if variant=='ruinas':ruinpoints=[(center[0]-8,center[1]-6),(center[0]+11,center[1]-5),(center[0]+2,center[1]+11)]
 if variant=='aldeia':ruinpoints=[(center[0]+11,center[1]-12)]
 if variant=='bambu':ruinpoints=[(center[0]+12,center[1]+11)]
 for x,z in ruinpoints:
  if 5<x<W-6 and 5<z<D-6 and not occupied[z-4:z+5,x-4:x+5].any() and not road[z-3:z+4,x-3:x+4].any():
   buildings.append({'x':x,'z':z,'style':'antiga','kind':'ruin'}); occupied[z-4:z+5,x-4:x+5]=True
 # Sculpt roads before placing foundations; no globally quantized staircase relief.
 target=ndi.gaussian_filter(h,2.2)
 h[road] = (.74*target+.26*h)[road]
 # Natural rounded building pads with blended outer shoulders, not floating squares.
 for b in buildings:
  x,z=b['x'],b['z']
  level=float(np.median(h[z-4:z+5,x-4:x+5]))
  for dz in range(-7,8):
   for dx in range(-7,8):
    dist=max(abs(dx),abs(dz))
    if dist>7:continue
    weight=1.0 if dist<=3 else (.5+.5*math.cos(math.pi*(dist-3)/4))
    h[z+dz,x+dx]=h[z+dz,x+dx]*(1-weight)+level*weight
  b['elevation']=level
 # Keep exact flat foundations within 7x7 and smooth pathways around them.
 for b in buildings:
  x,z=b['x'],b['z'];h[z-3:z+4,x-3:x+4]=b['elevation']
 # Grade-limit each consecutive road cell to a single traversable voxel step.
 # Lower offending high cells only; this never raises a road above its terrain.
 for sweep in range(20):
  changed=False
  for z in range(D):
   for x in range(W):
    if not road[z,x]:continue
    ns=[h[zz,xx] for xx,zz in [(x+1,z),(x-1,z),(x,z+1),(x,z-1)] if 0<=xx<W and 0<=zz<D and road[zz,xx]]
    if ns and float(h[z,x])>min(ns)+STEP+.00001:
     h[z,x]=float(min(ns))+STEP;changed=True
  if not changed:break
 # Terrain materials as logical data
 mats=np.full((D,W),MAT_IDS['grama_viva'],dtype=np.uint8)
 yy,xx=np.mgrid[:D,:W]
 rough=ndi.gaussian_filter(np.random.default_rng(seed+1543).random((D,W)),1.8)
 if variant=='aldeia':
  mats[:]=MAT_IDS['grama_prado'];mats[(h>4.0)&(rough>.42)]=MAT_IDS['grama_montanha']
 elif variant=='bambu':
  mats[:]=MAT_IDS['relva_bambu'];mats[(rough>.53)]=MAT_IDS['solo_florestal']
 else:
  mats[:]=MAT_IDS['grama_montanha'];mats[(h>5.6)|(rough>.59)]=MAT_IDS['pedra_xisto']
 mats[h>7.4]=MAT_IDS['rocha_cinza']
 # Preserve the natural subsoil to correctly blend dirt paths with grass/rock.
 underlying=mats.copy()
 mats[road]=MAT_IDS['trilha_batida']
 for b in buildings:
  x,z=b['x'],b['z'];mats[z-3:z+4,x-3:x+4]=MAT_IDS['lajes_ruina_cinza'] if b['kind']=='ruin' else MAT_IDS['terra_castanha']
 # Thick protective border; passages recorded and opened as traversal zones
 walls=np.zeros((D,W),bool)
 walls[:2,:]=True;walls[-2:,:]=True;walls[:,:2]=True;walls[:,-2:]=True
 for x,z in entrances:
  walls[max(0,z-3):min(D,z+4),max(0,x-3):min(W,x+4)]=False
 # no objects on paths, footprints, or boundary gates
 forbidden=ndi.binary_dilation(road,iterations=2) | occupied | walls
 return dict(seed=seed,variant=variant,heights=h,materials=mats,underlying_materials=underlying,roads=road,buildings=buildings,entrances=entrances,center=center,walls=walls,forbidden=forbidden)

def make_atlas(world):
    """Pixelated but organic transitions between coherent biome ground and baked dirt roads.
    Uses continuous road occupancy from adjacent grid cells: no independent square road tiles.
    """
    seed=world['seed'];N=TILE; underlying=world['underlying_materials'];road=world['roads']
    atlas=np.zeros((D*N,W*N,3),dtype=np.uint8)
    rng=np.random.default_rng(seed+910)
    textures={name:np.asarray(tex(name).resize((N,N),Image.Resampling.NEAREST),dtype=np.uint8) for name in MATS}
    # Soft occupancy is a coverage field, not a blurred RGB texture. The final choice
    # remains pixel-hard (nearest-neighbor), retaining original voxel texture detail.
    occ=ndi.gaussian_filter(road.astype(np.float32),.75)
    road_field=ndi.zoom(occ,N,order=1,grid_mode=True,mode='nearest')
    edge_random=ndi.gaussian_filter(rng.standard_normal((D*N,W*N)).astype(np.float32),2.0)
    edge_random/=max(.001,float(edge_random.std()))
    detail_noise=rng.standard_normal((D*N,W*N)).astype(np.float32)
    for z in range(D):
        for x in range(W):
            y0=z*N;x0=x*N
            matid=int(underlying[z,x]);base=textures[MATS[matid]].copy()
            base=np.rot90(base,int(rng.integers(0,4)))
            # Blend biome materials with dithered pixel borders; keep core texture unmodified.
            yy,xx=np.mgrid[:N,:N]
            for dx,dz,dist in [(0,-1,yy),(0,1,N-1-yy),(-1,0,xx),(1,0,N-1-xx)]:
                nx,nz=x+dx,z+dz
                if 0<=nx<W and 0<=nz<D:
                    other=int(underlying[nz,nx])
                    if other!=matid:
                        fuzzy=edge_random[y0:y0+N,x0:x0+N]
                        border=(dist < np.maximum(0,5.0+2.2*fuzzy))
                        base[border]=textures[MATS[other]][border]
            # Blend in the roadway using a continuous coverage field. No half-transparent
            # filter, so the texture is pixel-perfect while edge shape is non-rectangular.
            coverage=road_field[y0:y0+N,x0:x0+N]
            cutoff=.35+.085*edge_random[y0:y0+N,x0:x0+N]+.035*detail_noise[y0:y0+N,x0:x0+N]
            dirt=coverage>cutoff
            if dirt.any():
                rd=textures['trilha_batida']
                base[dirt]=rd[dirt]
            atlas[y0:y0+N,x0:x0+N,:]=base
    im=Image.fromarray(atlas)
    im.save(OUT/'textures'/f'terreno_seed_{seed}.png')
    return im

def triangulate_ground(world,atlas):
    """Watertight continuous visual ground with textured facets and solid outer escarpment.
    No internal 1-tile dark walls: those were the repeating black stripes in revision 01.
    """
    h=world['heights']
    pad=np.pad(h,1,mode='edge')
    # Each shared corner has identical height across neighboring cells.
    vh=(pad[:-1,:-1]+pad[1:,:-1]+pad[:-1,1:]+pad[1:,1:])*.25
    verts=[];faces=[];uv=[]
    for z in range(D):
        for x in range(W):
            x0=x-W/2;z0=z-D/2; i=len(verts)
            verts.extend([[x0,vh[z,x],z0],[x0+1,vh[z,x+1],z0],
                          [x0+1,vh[z+1,x+1],z0+1],[x0,vh[z+1,x],z0+1]])
            uv.extend([[x/W,1-z/D],[(x+1)/W,1-z/D],[(x+1)/W,1-(z+1)/D],[x/W,1-(z+1)/D]])
            faces.extend([[i,i+2,i+1],[i,i+3,i+2]])
    ground=trimesh.Trimesh(vertices=np.asarray(verts),faces=np.asarray(faces),process=False)
    ground.visual=trimesh.visual.TextureVisuals(uv=np.asarray(uv),material=trimesh.visual.material.PBRMaterial(
        baseColorTexture=atlas,metallicFactor=0,roughnessFactor=1,doubleSided=True))
    base=.05; sv=[];sf=[];sc=[]
    def facequad(coords,color):
        j=len(sv);sv.extend(coords);sf.extend([[j,j+1,j+2],[j,j+2,j+3]]);sc.extend([(*color,255)]*4)
    for x in range(W):
        for z,sign in [(0,-1),(D,1)]:
            topa=vh[z,x];topb=vh[z,x+1]
            a=[x-W/2,topa,z-D/2]; b=[x-W/2+1,topb,z-D/2]
            c=[x-W/2+1,base,z-D/2]; d=[x-W/2,base,z-D/2]
            facequad([a,b,c,d] if sign==-1 else [b,a,d,c],(90,88,81))
    for z in range(D):
        for x,sign in [(0,-1),(W,1)]:
            topa=vh[z,x];topb=vh[z+1,x]
            a=[x-W/2,topa,z-D/2];b=[x-W/2,topb,z-D/2+1]
            c=[x-W/2,base,z-D/2+1];d=[x-W/2,base,z-D/2]
            facequad([b,a,d,c] if sign==-1 else [a,b,c,d],(77,81,76))
    sides=trimesh.Trimesh(vertices=np.asarray(sv),faces=np.asarray(sf),process=False)
    sides.visual.vertex_colors=np.asarray(sc,dtype=np.uint8)
    return ground,sides

def transform_geo(geometries,pos,scale=1,angle=0):
 out=[]
 T=trimesh.transformations.translation_matrix(pos) @ trimesh.transformations.rotation_matrix(angle,[0,1,0]) @ trimesh.transformations.scale_matrix(scale)
 for g in geometries:
  t=g.copy();t.apply_transform(T);out.append(t)
 return out

def scale_asset_to(name,targetheight):
 meshes=meshasset(name)
 bounds=np.array([g.bounds for g in meshes]);overall=np.array([bounds[:,:,i] for i in range(3)])
 bbox=np.vstack([bounds[:,0,:].min(axis=0),bounds[:,1,:].max(axis=0)])
 return targetheight/(bbox[1,1]-bbox[0,1])

def generate_objects(world):
 seed=world['seed'];rng=random.Random(seed*13+3)
 h=world['heights'];variant=world['variant'];forbidden=world['forbidden'];W2=W/2;D2=D/2
 instances=[]; footprints=[]
 def add(asset,x,z,scale=1,rot=0,dy=0,solid=True):
  x=int(x);z=int(z)
  if not (0<=x<W and 0<=z<D):return
  # y below: world tile high at its center
  y=float(h[z,x])+dy
  instances.append({'asset':asset,'position':[x-W/2+0.5,y,z-D/2+0.5],'rotation_y':rot,'scale':scale,'solid':solid,'cell':[x,z]})
  if solid:footprints.append((x,z))
 # modular buildings from actual pieces (not baked house mesh)
 for b in world['buildings']:
  x,z=b['x'],b['z'];y=float(b['elevation'])
  if b['kind']=='building':
   # MeshLibrary-sized real modular architectural pieces: foundation, open door,
   # lattice windows, timber posts, stepped tiled roof and ornamental entry.
   roof='telhado_voxel_jade' if b['style']=='jade' else 'telhado_voxel_vermelho'
   facade='painel_janela_lattice' if b['style']=='jade' else 'parede_reboco_ocre'
   foundation='fundacao_pedra' if b['style']=='jade' else 'base_madeira_templo'
   def module(name,dx,dz,dy=0,angle=0,scale=1,solid=True):
    instances.append(dict(asset=name,position=[x-W/2+.5+dx,y+dy,z-D/2+.5+dz],rotation_y=angle,scale=scale,solid=solid,cell=[x,z]))
   module(foundation,0,0,-.08,0,1.25)
   module('painel_porta_livre',0,-2.55,.50)
   module('parede_reboco_claro',0,2.55,.50)
   module(facade,-2.55,0,.50,math.pi/2)
   module('painel_janela_lattice',2.55,0,.50,math.pi/2)
   for dx,dz in [(-2.30,-2.30),(-2.30,2.30),(2.30,-2.30),(2.30,2.30)]:
    module('coluna_madeira_escura',dx,dz,.52,0,.76)
   module(roof,0,0,3.78)
   module('degrau_pedra_cidade',0,-3.38,-.28,0,.70)
   module('porta_laca_jade' if b['style']=='jade' else 'porta_madeira_dupla',0,-2.91,.54,0,.65,False)
   # Two lanterns, two entrance posts. Detail is structural rather than random cubes.
   for dx in [-2.00,2.00]:
    module('lanterna_voxel',dx,-3.00,.25,0,.70)
   # Simple stone yard supports a path which can connect to the road system.
   for dx in [-1.0,0,1.0]:
    module('degrau_pedra_cidade',dx*1.35,-4.30,-.22,0,.30)
  else:
   for dx,dz,name,a in [(-2,0,'parede_ruina_destruido',math.pi/2),(2,1,'parede_ruina_canto',0),(-1,3,'coluna_ruina_musgo',0),(2,-3,'pilar_ruina_quebrado',0),(0,-1,'altar_ruina_antigo',0)]:
    xx=x+dx;zz=z+dz
    if 0<=xx<W and 0<=zz<D:
     instances.append(dict(asset=name,position=[xx-W/2+.5,float(h[zz,xx]),zz-D/2+.5],rotation_y=a,scale=.85,solid=True,cell=[xx,zz]))
 # forest and terrain formations, non-overlapping with roads and building lots
 if variant=='aldeia':plants=['arvore_baixa_prado','arvore_grande','pinheiro_escarpado','arvore_alta_sombria']
 elif variant=='bambu': plants=['bambu_grupo_rio','bambu_alto_folhas','arvore_alta_sombria','bambu_alto_folhas']
 else:plants=['pinheiro_escarpado','arvore_alta_sombria','rocha_monolito_musgo','arvore_baixa_prado']
 selected=[]
 target=145 if variant=='bambu' else (91 if variant=='aldeia' else 70)
 for i in range(2400):
  if len(selected)>=target:break
  x=rng.randint(3,W-4);z=rng.randint(3,D-4)
  if forbidden[z,x] or any((x-x0)**2+(z-z0)**2 < (6 if variant=='bambu' else 12) for x0,z0 in selected):continue
  if variant=='ruinas' and h[z,x]>6 and rng.random()<.55:
   plant='rocha_monolito_musgo' if rng.random()<.4 else 'rocha_pilha_grande'
  else:plant=rng.choice(plants)
  selected.append((x,z))
  add(plant,x,z,scale=rng.uniform(.75,1.32),rot=rng.choice([0,math.pi/2,math.pi,1.5*math.pi]))
 # Mountain silhouettes: group proper stacked voxel formations on steeper outer slopes.
 if variant=='ruinas':
  potential=[(x,z) for z in range(4,D-4,3) for x in range(4,W-4,3)
             if (h[z,x]>8.5 or (x>39 and h[z,x]>6.0)) and not forbidden[z,x]]
  rng.shuffle(potential)
  for x,z in potential[:14]:
   add(rng.choice(['rocha_pilha_grande','rocha_monolito_musgo','pedra_xisto_grupo']),
       x,z,scale=rng.uniform(.8,1.8),rot=rng.random()*6.283)
 # Low groundcover occupies clusters away from roads; it is never collidable.
 for i in range(190 if variant=='bambu' else 135):
  x=rng.randrange(2,W-2);z=rng.randrange(2,D-2)
  if forbidden[z,x]:continue
  if h[z,x]>8.8:continue
  add('tufo_grama_voxel',x,z,scale=rng.uniform(.65,1.7),rot=rng.random()*6.283,solid=False)
 # detail stones, ruins in grass and side-facing cliff
 for i in range(28):
  x=rng.randint(2,W-3);z=rng.randint(2,D-3)
  if forbidden[z,x]:continue
  add('rocha_pilha_baixa' if rng.random()<.55 else 'pedra_xisto_grupo',x,z,scale=rng.uniform(.5,.85),rot=rng.random()*6.28)
 return instances

def vk_mesh(tri,texture=None):
 verts=np.asarray(tri.vertices,dtype=np.float32)
 faces=np.asarray(tri.faces,dtype=np.int64)
 points=vtk.vtkPoints();points.SetData(ns.numpy_to_vtk(verts,deep=1))
 cells=vtk.vtkCellArray();data=np.concatenate([np.full((faces.shape[0],1),3,dtype=np.int64),faces],axis=1).ravel()
 cells.SetCells(len(faces),ns.numpy_to_vtkIdTypeArray(data,deep=1))
 pd=vtk.vtkPolyData();pd.SetPoints(points);pd.SetPolys(cells)
 if texture is not None:
  UV=np.ascontiguousarray(tri.visual.uv,dtype=np.float32)
  pd.GetPointData().SetTCoords(ns.numpy_to_vtk(UV,deep=1))
 else:
  if hasattr(tri.visual,'vertex_colors') and tri.visual.vertex_colors is not None:
   col=np.ascontiguousarray(tri.visual.vertex_colors,dtype=np.uint8)
   v=ns.numpy_to_vtk(col,deep=1,array_type=vtk.VTK_UNSIGNED_CHAR);v.SetNumberOfComponents(4);pd.GetPointData().SetScalars(v)
 return pd

def actor_mesh(m,scale=1,angle=0,pos=(0,0,0),texture=None):
 pd=vk_mesh(m,texture)
 mapper=vtk.vtkPolyDataMapper();mapper.SetInputData(pd);mapper.SetScalarVisibility(True)
 actor=vtk.vtkActor();actor.SetMapper(mapper)
 if texture is not None:
  vtktex=vtk.vtkTexture();vtktex.SetInterpolate(False); vtktex.RepeatOff()
  arr=np.array(texture.convert('RGB'))[::-1].copy();
  img=vtk.vtkImageData();img.SetDimensions(texture.width,texture.height,1)
  array=ns.numpy_to_vtk(arr.reshape(-1,3),deep=True,array_type=vtk.VTK_UNSIGNED_CHAR)
  array.SetNumberOfComponents(3);img.GetPointData().SetScalars(array)
  vtktex.SetInputData(img);actor.SetTexture(vtktex)
  actor.GetProperty().SetColor(1,1,1)
 else:actor.GetProperty().SetAmbient(.36);actor.GetProperty().SetDiffuse(.73)
 actor.SetScale(scale);actor.SetOrientation(0,math.degrees(angle),0);actor.SetPosition(*pos)
 return actor

def scene_preview(world,ground,sides,instances,atlas,name,zoom=37.0):
 ren=vtk.vtkRenderer();ren.SetBackground(.10,.14,.16);ren.GradientBackgroundOn();ren.SetBackground2(.29,.35,.35)
 rw=vtk.vtkRenderWindow();rw.SetOffScreenRendering(1);rw.AddRenderer(ren);rw.SetSize(1440,1020); rw.SetMultiSamples(4)
 ren.AddActor(actor_mesh(ground,texture=atlas));ren.AddActor(actor_mesh(sides))
 cache={}
 for inst in instances:
  name2=inst['asset']
  if name2 not in cache:
   try:
    parts=meshasset(name2)
    cache[name2]=[vk_mesh(g) for g in parts]
   except Exception as e:
    print('asset error',name2,e);continue
  for pd in cache[name2]:
   mapper=vtk.vtkPolyDataMapper();mapper.SetInputData(pd)
   actor=vtk.vtkActor();actor.SetMapper(mapper)
   actor.GetProperty().SetAmbient(.72 if ('arvore' in name2 or 'bambu' in name2 or 'pinheiro' in name2) else .50);actor.GetProperty().SetDiffuse(.45 if ('arvore' in name2 or 'bambu' in name2 or 'pinheiro' in name2) else .62)
   actor.SetScale(inst['scale']);actor.SetOrientation(0,math.degrees(inst['rotation_y']),0)
   actor.SetPosition(*inst['position']);ren.AddActor(actor)
 # lighting
 ren.RemoveAllLights()
 light=vtk.vtkLight();light.SetPosition(-50,85,45);light.SetFocalPoint(0,0,0);light.SetIntensity(1.15); ren.AddLight(light)
 light2=vtk.vtkLight();light2.SetPosition(40,55,-40);light2.SetFocalPoint(0,0,0);light2.SetIntensity(.4);ren.AddLight(light2)
 cam=ren.GetActiveCamera();cam.SetPosition(82,91,112);cam.SetFocalPoint(0,2,0);cam.SetViewUp(0,1,0);cam.ParallelProjectionOn();cam.SetParallelScale(zoom)
 ren.ResetCameraClippingRange()
 rw.Render();f=vtk.vtkWindowToImageFilter();f.SetInput(rw);f.ReadFrontBufferOff();f.Update()
 writer=vtk.vtkPNGWriter();writer.SetInputConnection(f.GetOutputPort());writer.SetFileName(str(OUT/'previews'/name));writer.Write()
 return OUT/'previews'/name

def export_glb(world,ground,sides,instances,name):
 # Source models in Coleção 02; the same placed meshes as preview, fully inspectable.
 scene=trimesh.Scene()
 scene.add_geometry(ground,node_name='solo_texturizado',geom_name='solo_texturizado')
 scene.add_geometry(sides,node_name='rocha_encostas',geom_name='rocha_encostas')
 for i,ins in enumerate(instances):
  asset=meshasset(ins['asset'])
  trans=trimesh.transformations.translation_matrix(ins['position']) @ trimesh.transformations.rotation_matrix(ins['rotation_y'],[0,1,0]) @ trimesh.transformations.scale_matrix(ins['scale'])
  for k,geo in enumerate(asset):
   scene.add_geometry(geo,transform=trans,node_name=f"{i:03d}_{ins['asset']}_{k}")
 data=scene.export(file_type='glb')
 (OUT/'scenes'/name).write_bytes(data)
 return len(data)

def save_map(world):
 seed=world['seed'];h=world['heights'];mat=world['materials'];road=world['roads'];N=W
 png=Image.new('RGB',(N*8,N*8));p=png.load()
 for z in range(N):
  for x in range(N):
   c=np.array(tex(MATS[mat[z,x]]))[16,16].astype(int)
   c=(c*np.clip(.87+(h[z,x]-2)*.023,.65,1.12)).clip(0,255).astype('uint8')
   for yy in range(8):
    for xx in range(8):p[x*8+xx,z*8+yy]=tuple(map(int,c))
 d=ImageDraw.Draw(png)
 for b in world['buildings']:
  x,z=b['x'],b['z'];d.rectangle([x*8-11,z*8-11,x*8+11,z*8+11],fill='#D1A86A' if b['kind']=='building' else '#ADB6B0',outline='#171f22',width=2)
 for x,z in world['entrances']:
  d.ellipse([x*8-7,z*8-7,x*8+7,z*8+7],fill='#75D8B7',outline='#112f32',width=2)
 png.save(OUT/'maps'/f'mapa_seed_{seed}.png')

def verify(world):
 import collections
 h=world['heights'];road=world['roads'];buildings=world['buildings']
 # Roads are contiguous around starting settlement; buildings have flat foundations
 st=tuple(map(int,world['center']))
 # road center need ensure from center; search nearest 2 steps
 if not road[st[1],st[0]]:
  zz,xx=np.where(road);st=min(zip(xx,zz),key=lambda p:(p[0]-st[0])**2+(p[1]-st[1])**2)
 seen={st};q=collections.deque([st]);
 while q:
  x,z=q.popleft()
  for nx,nz in [(x+1,z),(x-1,z),(x,z-1),(x,z+1)]:
   if 0<=nx<W and 0<=nz<D and road[nz,nx] and (nx,nz) not in seen:
    seen.add((nx,nz));q.append((nx,nz))
 exits=[]
 for x,z in world['entrances']:
  reachable=any((tx,tz) in seen for tx in range(max(0,x-3),min(W,x+4)) for tz in range(max(0,z-3),min(D,z+4)))
  exits.append(reachable)
 foundations=[]
 for b in buildings:
  x,z=b['x'],b['z'];hh=h[z-3:z+4,x-3:x+4]
  foundations.append(round(float(np.max(hh)-np.min(hh)),3))
 grades=[]
 for dz,dx in [(0,1),(1,0)]:
  both=road[:D-dz,:W-dx]&road[dz:,dx:]
  grades.extend(np.abs(h[:D-dz,:W-dx]-h[dz:,dx:])[both])
 max_grade=round(float(max(grades)),4)
 return {'seed':world['seed'],'variant':world['variant'],'max_adjacent_road_step':max_grade,'road_connected_entrances':exits,'building_footprint_height_variation':foundations,'material_kinds':len(np.unique(world['materials'])),'road_cells':int(road.sum()),'buildings':len(buildings),'all_checks_passed':all(exits) and max_grade<=STEP+.00001 and max(foundations or [0])<.001}

if __name__=='__main__':
 create_roof_voxel('jade');create_roof_voxel('vermelho');create_lantern_voxel();create_groundcover_voxel()
 cfg=[(101,'aldeia','01_VALE_E_ALDEIA.png'),(202,'bambu','02_FLORESTA_DE_BAMBU.png'),(707,'ruinas','03_RUINAS_E_MONTANHA.png'),(404,'aldeia','04_VALE_VARIANTE.png')]
 reports=[]
 for seed,variant,preview in cfg:
  print('Generating',seed,variant,flush=True)
  w=make(seed,variant)
  r=verify(w);reports.append(r)
  atlas=make_atlas(w)
  top,sides=triangulate_ground(w,atlas)
  obj=generate_objects(w)
  save_map(w)
  scene_preview(w,top,sides,obj,atlas,preview)
  b=export_glb(w,top,sides,obj,f'mundo_seed_{seed}.glb')
  print('report',r,'assets',len(obj),'scene_bytes',b,flush=True)
  info={'seed':seed,'variant':variant,'size_cells':[W,D],'cell_size_world_units':1,'heights_voxel_step':STEP,
        'entrances':w['entrances'],'center':w['center'],'buildings':w['buildings'],'object_instances':obj,
        'material_id_to_name':MATS,'heights':w['heights'].round(3).tolist(),'materials':w['materials'].tolist(),
        'road_cells':np.argwhere(w['roads']).tolist(),'blocked_bounds':[list(p) for p in zip(*np.where(w['walls']))],
        'test_report':r}
  (OUT/'maps'/f'dados_seed_{seed}.json').write_text(json.dumps(info,ensure_ascii=False,indent=1,default=lambda x: x.item() if isinstance(x,np.generic) else x.tolist()))
 (OUT/'RELATORIO_TESTES.json').write_text(json.dumps(reports,ensure_ascii=False,indent=2))
 print('ALL DONE',flush=True)
