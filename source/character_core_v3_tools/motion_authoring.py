# V3 authored motion for the ORIGINAL V4 geometry. Executed inside prepare.py.
from mathutils import Euler
held=None
reach_clamps=[]
def clamp(x,a=0,b=1):return max(a,min(b,x))
def ease(x):x=clamp(x);return x*x*(3-2*x)
def mix(a,b,u):return a+(b-a)*u
def path(u,keys):
 for i in range(len(keys)-1):
  ta,a=keys[i];tb,b=keys[i+1]
  if u<=tb:return Vector(a).lerp(Vector(b),ease((u-ta)/(tb-ta)))
 return Vector(keys[-1][1])
def offset(n,v):P[n].location=ad.bones[n].matrix_local.to_3x3().inverted()@Vector(v)
def bone_aim(name,head,direction):
 y=direction.normalized()
 ref=transport_frames.get(name,ad.bones[name].matrix_local.to_3x3()).col[0].copy()
 x=(ref-y*ref.dot(y)).normalized()
 z=x.cross(y).normalized();x=y.cross(z).normalized()
 mat=Matrix((x,y,z)).transposed().to_4x4();mat.translation=head;P[name].matrix=mat
 bpy.context.view_layer.update()
def ik(a,b,target,pole):
 bpy.context.view_layer.update();A=P[a].matrix.translation.copy();T=Vector(target)
 l1=ad.bones[a].length;l2=ad.bones[b].length;v=T-A;raw=v.length;dist=clamp(raw,abs(l1-l2)+.0001,l1+l2-.0001)
 if raw>l1+l2+.015:reach_clamps.append((a,raw-l1-l2))
 axis=v.normalized();p=Vector(pole);p=(p-axis*p.dot(axis)).normalized()
 along=(l1*l1-l2*l2+dist*dist)/(2*dist);h=math.sqrt(max(0,l1*l1-along*along));B=A+axis*along+p*h
 end=A+axis*dist;bone_aim(a,A,B-A);bone_aim(b,B,end-B);return end

def leg(side,target,pitch=0):
 end=ik('thigh_'+side,'shin_'+side,target,(0,-1,0))
 m=(Euler((math.radians(pitch),0,0)).to_matrix()@ad.bones['foot_'+side].matrix_local.to_3x3()).to_4x4();m.translation=end;P['foot_'+side].matrix=m

def arm(side,wrist,attitude=(0,0,0)):
 sg=-1 if side=='L' else 1
 end=ik('upper_arm_'+side,'forearm_'+side,wrist,(sg*.7,.2,-.35))
 q=Euler(tuple(math.radians(v) for v in attitude)).to_matrix()
 m=(q@ad.bones['hand_'+side].matrix_local.to_3x3()).to_4x4();m.translation=end;P['hand_'+side].matrix=m;bpy.context.view_layer.update()
def grip(side,center,attitude=(0,0,0)):
 q=Euler(tuple(math.radians(v) for v in attitude)).to_matrix()
 arm(side,Vector(center)-q@Vector((0,-.076,-.055)),attitude)
def hold(side='R'):
 global held
 held=side

def idle(t,u):
 s=math.sin(u*math.tau);rot('spine',.65*s,0,.4*s);rot('neck',-.3*s);rot('head',0,.4*math.sin(u*math.tau+.6),-.35*s)
 rot('upper_arm_L',.6*s,0,.4*s);rot('upper_arm_R',-.6*s,0,-.4*s)

def foot_cycle(p,stride,stance,lift):
 p%=1;travel=stride*stance
 if p<stance:
  y=-travel*.5+travel*p/stance;z=0
  pitch=-8*(1-ease(p/.12)) + 12*ease((p-stance+.12)/.12)
  z+=.16*max(0,math.sin(math.radians(pitch)))
 else:
  s=(p-stance)/(1-stance);y=travel*.5-travel*ease(s)+stride*(1-stance)*s*(1-s)*(1-2*s);z=lift*math.sin(math.pi*s)**1.4+.16*math.sin(math.radians(12))*(1-ease(s));pitch=12-20*ease(s)
 return y,z,pitch

def locomotion(t,u,run=False,armed=False,direction=(0,-1)):
 phase=u%1;s=math.sin(phase*math.tau);bounce=math.cos(phase*math.tau*2)
 stride=2.2 if run else 1.0;stance=.38 if run else .62
 offset('pelvis',(.018*s,0,(-.13 if run else -.115)+(.035 if run else .018)*bounce))
 rot('pelvis',0,0,(5 if run else 3)*s)
 rot('spine',10 if run else 3,0,-(7 if run else 4)*s)
 rot('head',-6 if run else -2,0,(3 if run else 2)*s)
 bpy.context.view_layer.update()
 for side,sg,p in [('L',-1,phase),('R',1,phase+.5)]:
  y,z,pitch=foot_cycle(p,stride,stance,.25 if run else .13)
  # For strafe/backpedal, rotate the same contact trajectory into the desired direction.
  target=(sg*.215-direction[0]*y, -direction[1]*y, .30+z)
  leg(side,target,pitch if direction[1]<0 else -pitch*.5)
 if armed:
  grip('R',(.32,-.45+(0.035*s),1.62+.018*bounce),(-12,0,-8))
  arm('L',(-.31,-.32,1.67+.025*s),(-25,0,12));hold()
 else:
  rot('upper_arm_L',-(37 if run else 23)*s,0,-3);rot('forearm_L',-38 if run else -13+5*s)
  rot('upper_arm_R',(37 if run else 23)*s,0,3);rot('forearm_R',-38 if run else -13-5*s)
  rot('hand_L',5*s);rot('hand_R',-5*s)

def stance(t,u,breath=True):
 s=math.sin(u*math.tau)*(.008 if breath else 0)
 offset('pelvis',(.015,0,-.115+s));rot('pelvis',0,0,-5);rot('spine',5,0,10);rot('head',-3,0,-8)
 bpy.context.view_layer.update();leg('L',(-.24,-.20,.30));leg('R',(.24,.16,.30))
 grip('R',(.33,-.45,1.62+s),(-12,0,-8));arm('L',(-.31,-.34,1.7+s),(-25,0,14));hold()
def combat(t,u):stance(t,u)

def draw(t,u):
 # Left hand reaches the original left-hip grip; both hands meet before transferring.
 global held
 a=ease(u);offset('pelvis',(0,0,-.115*a));rot('spine',3*a,0,7*a);rot('head',-2*a,0,-5*a)
 bpy.context.view_layer.update()
 leg('L',Vector((-.192,0,.3)).lerp(Vector((-.24,-.20,.3)),a));leg('R',Vector((.192,0,.3)).lerp(Vector((.24,.16,.3)),a))
 waist=Vector((-.30,-.31,1.60));center=Vector((0,-.35,1.70));guard=Vector((.33,-.45,1.62))
 if u<.22:
  arm('L',Vector((-.515,-.004,1.30)).lerp(waist-Vector((0,-.076,-.055)),ease(u/.22)))
  arm('R',Vector((.515,-.004,1.30)).lerp(Vector((.29,-.17,1.61)),ease(u/.22)))
 elif u<.60:
  p=waist.lerp(center,ease((u-.22)/.38));grip('L',p)
  arm('R',Vector((.29,-.17,1.61)).lerp(center-Vector((0,-.076,-.055)),ease((u-.22)/.38)));hold('L')
 else:
  p=center.lerp(guard,ease((u-.60)/.40));grip('R',p,(-12*ease((u-.60)/.40),0,-8*ease((u-.60)/.40)))
  arm('L',(center-Vector((0,-.076,-.055))).lerp(Vector((-.31,-.34,1.70)),ease((u-.60)/.40)),(-25*ease((u-.60)/.4),0,14*ease((u-.60)/.4)));hold('R')
def sheathanim(t,u):draw(t,1-u)

def attack(t,u,second=False):
 # Asymmetric anticipation, acceleration, follow-through and recovery.
 wind=ease(u/.24);strike=ease((u-.24)/.24);recover=ease((u-.61)/.39)
 power=wind*(1-strike);impact=math.sin(math.pi*clamp((u-.24)/.42))
 sign=-1 if second else 1
 twist=(-24*power+32*strike*(1-recover))*sign
 offset('pelvis',(.04*sign*impact,-.035*impact,-.115-.055*impact));rot('pelvis',0,0,-5+twist*.40);rot('spine',5+10*impact,0,10+twist);rot('head',-4-6*impact,0,-8-twist*.7)
 bpy.context.view_layer.update()
 # In-place footwork compensates the same forward displacement curve used by the controller.
 distance=.68 if not second else .52;travel=distance*ease((u-.24)/.28)
 front=path(u,[(0,(-.24,-.20,.30)),(.24,(-.24,-.36,.47)),(.49,(-.24,-.20-distance,.30)),(1,(-.24,-.20-distance,.30))])
 back=path(u,[(0,(.24,.16,.30)),(.15,(.24,.16,.30)),(.40,(.24,.16-distance*.55,.43)),(.60,(.24,.16-distance,.30)),(1,(.24,.16-distance,.30))])
 front.y+=travel;back.y+=travel;leg('L',front);leg('R',back)
 # Deliberately authored joint arcs for the strike: no arm-IK pole singularities.
 if not second:
  ux=-35-90*power-22*strike*(1-recover)
  ex=-65+45*power+24*strike*(1-recover)
  side=-8-15*power+34*strike*(1-recover)
 else:
  ux=-58-20*power-65*strike*(1-recover)
  ex=-42-20*power+25*strike*(1-recover)
  side=24+10*power-48*strike*(1-recover)
 rot('upper_arm_R',ux,0,side);rot('forearm_R',ex,15*impact,0)
 rot('upper_arm_L',-42-14*impact,0,20);rot('forearm_L',-58-15*impact,0,0)
 bpy.context.view_layer.update()
 for side,att in [('R',(-12-90*power-65*strike*(1-recover),0,-8+24*impact*sign)),('L',(-25,0,14))]:
  bone='hand_'+side;m=(Euler(tuple(math.radians(v) for v in att)).to_matrix()@ad.bones[bone].matrix_local.to_3x3()).to_4x4();m.translation=P[bone].matrix.translation.copy();P[bone].matrix=m
  bpy.context.view_layer.update()
 hold()

def dodge(t,u):
 # Lateral compact step. Body displacement is applied to the CharacterBody by its phase curve.
 a=math.sin(math.pi*u);offset('pelvis',(.06*a,0,-.115-.20*a));rot('spine',7+12*a,0,-10*a);rot('head',-4-7*a,0,7*a)
 bpy.context.view_layer.update()
 leg('L',(-.24-.13*a,-.13,.30+.12*math.sin(math.pi*ease(u))))
 leg('R',(.24+.12*a,.10,.30+.12*math.sin(math.pi*ease(u))))
 grip('R',(.30,-.39,1.54-.12*a),(-20,0,-15));arm('L',(-.30,-.35,1.59-.15*a),(-30,0,15));hold()
def hit(t,u):
 a=path(u,[(0,(0,0,0)),(.15,(1,0,0)),(.42,(.55,0,0)),(1,(0,0,0))]).x
 offset('pelvis',(.015,0,-.115));rot('pelvis',0,0,-5);rot('spine',5-18*a,0,10-9*a);rot('head',-3+13*a,0,-8)
 bpy.context.view_layer.update();leg('L',(-.24,-.20,.30));leg('R',(.24,.16,.30));grip('R',(.33,-.45+.10*a,1.62-.05*a),(-12,0,-8));arm('L',(-.31,-.34,1.70),(-25,0,14));hold()

specs=[('Idle',2.4,True,idle),('Walk',1,True,lambda t,u:locomotion(t,u)),('Run',1,True,lambda t,u:locomotion(t,u,True)),('Combat_Idle',2.4,True,combat),('Walk_Armed',1,True,lambda t,u:locomotion(t,u,False,True)),('Run_Armed',1,True,lambda t,u:locomotion(t,u,True,True)),('Combat_Back',1,True,lambda t,u:locomotion(t,u,False,True,(0,1))),('Combat_Left',1,True,lambda t,u:locomotion(t,u,False,True,(-1,0))),('Combat_Right',1,True,lambda t,u:locomotion(t,u,False,True,(1,0))),('Sword_Draw',1.15,False,draw),('Sword_Sheath',1.15,False,sheathanim),('Sword_Attack_01',.72,False,lambda t,u:attack(t,u)),('Sword_Attack_02',.74,False,lambda t,u:attack(t,u,True)),('Dodge',.50,False,dodge),('Hit_Reaction',.42,False,hit)]
(R/'godot/motion_config.json').write_text(json.dumps({n:{'duration':d,'loop':loop} for n,d,loop,fn in specs},indent=2))
actions=[animate(n,d,loop,fn) for n,d,loop,fn in specs]
(R/'logs/motion_reach_diagnostics.json').write_text(json.dumps({'clamp_events':len(reach_clamps),'max_unreachable_distance':max([v for n,v in reach_clamps]or[0]),'examples':reach_clamps[:20]},indent=2))
