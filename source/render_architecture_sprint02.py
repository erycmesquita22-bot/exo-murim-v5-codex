"""VTK offscreen captures of the actual exported architecture GLB files."""
import os
os.environ.setdefault('VTK_DEFAULT_RENDER_WINDOW_OFFSCREEN','1')
from pathlib import Path
import numpy as np,trimesh,vtk
from vtk.util.numpy_support import numpy_to_vtk,numpy_to_vtkIdTypeArray
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];P=ROOT/'architecture_sprint02';pv=P/'previews';pv.mkdir(exist_ok=True)
texpath=P/'textures'/'EXO_Murim_Architecture_InkAtlas_1536.png'
def draw(path,eye,focus,scale=7.8,size=(900,850)):
 scene=trimesh.load(path,force='scene',process=False)
 renderer=vtk.vtkRenderer();renderer.SetBackground(.78,.85,.83);renderer.SetBackground2(.93,.94,.89);renderer.GradientBackgroundOn()
 win=vtk.vtkRenderWindow();win.SetOffScreenRendering(1);win.SetSize(*size);win.SetMultiSamples(0);win.AddRenderer(renderer)
 r=vtk.vtkPNGReader();r.SetFileName(str(texpath));r.Update();t=vtk.vtkTexture();t.SetInputConnection(r.GetOutputPort());t.InterpolateOn();t.RepeatOff()
 for name,g in scene.geometry.items():
  pts=vtk.vtkPoints();pts.SetData(numpy_to_vtk(g.vertices.astype('float32'),deep=True))
  f=np.empty((len(g.faces),4),dtype='int64');f[:,0]=3;f[:,1:]=g.faces
  ca=vtk.vtkCellArray();ca.SetCells(len(f),numpy_to_vtkIdTypeArray(f.ravel(),deep=True))
  poly=vtk.vtkPolyData();poly.SetPoints(pts);poly.SetPolys(ca)
  tc=numpy_to_vtk(g.visual.uv.astype('float32'),deep=True);tc.SetNumberOfComponents(2);tc.SetName('uv');poly.GetPointData().SetTCoords(tc)
  mapper=vtk.vtkPolyDataMapper();mapper.SetInputData(poly)
  ac=vtk.vtkActor();ac.SetMapper(mapper);ac.SetTexture(t);ac.GetProperty().SetAmbient(.84);ac.GetProperty().SetDiffuse(.28);ac.GetProperty().SetInterpolationToFlat();ac.GetProperty().BackfaceCullingOff();renderer.AddActor(ac)
 light=vtk.vtkLight();light.SetLightTypeToSceneLight();light.SetPosition(30,65,65);light.SetFocalPoint(*focus);light.SetIntensity(.48);renderer.AddLight(light)
 cam=renderer.GetActiveCamera();cam.SetPosition(*eye);cam.SetFocalPoint(*focus);cam.SetViewUp(0,1,0);cam.SetParallelProjection(True);cam.SetParallelScale(scale)
 renderer.ResetCameraClippingRange();win.Render()
 v=vtk.vtkWindowToImageFilter();v.SetInput(win);v.ReadFrontBufferOff();v.Update()
 op=pv/(path.stem+'.png');w=vtk.vtkPNGWriter();w.SetFileName(str(op));w.SetInputConnection(v.GetOutputPort());w.Write();print(op)
 return op
sh=[]
for key,eye,scale in [('HOUSE_RURAL',(11,10,19),7.3),('TEAHOUSE',(16,12,23),8.3),('MANOR_HALL',(23,17,31),11.0),('SHRINE',(9,9,14),6.2),('COURTYARD_GATE',(8,8,13),6.4)]:
 sh.append(draw(P/'kit'/(key+'.glb'),eye,(0,2.2,0),scale))
sh.append(draw(P/'HWA02_Architecture_Sprint02.glb',(-8,45,36),(-48,2,-42),35,size=(900,850)))
cols=3;tileW=600;tileH=640;board=Image.new('RGB',(1800,1280),'#e3e8e2');d=ImageDraw.Draw(board)
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',18)
for i,pp in enumerate(sh):
 im=Image.open(pp).convert('RGB');im.thumbnail((590,565));x=i%3*tileW;y=i//3*tileH
 board.paste(im,(x+(tileW-im.width)//2,y+35));d.text((x+20,y+8),pp.stem.replace('_',' '),fill='#273934',font=font)
board.save(pv/'00_KIT_REAL_GLBS.png')
print('done')
