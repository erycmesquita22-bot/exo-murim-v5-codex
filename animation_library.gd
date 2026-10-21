extends RefCounted
# EXO-MURIM C03 / directional local animation, original procedural code.
# No external animation clips or Kenney model in the release runtime.
# The character rig and combat-specific Arsenal/Anatomy remain authoritative.
static func locomotion(rig: Variant, phase: float, sprint: bool, arms_free: bool, forward: float, speed: float, lateral: float=0.0) -> void:
 if not arms_free or speed<0.06:return
 if not is_instance_valid(rig):return
 if rig.arms.size()!=2 or rig.forearms.size()!=2:return
 # Direction is already measured in the character's LOCAL body coordinates;
 # this prevents elbow swing from staying fixed to a world/screen compass.
 var intensity: float=clampf(speed/3.6,0.0,1.0)
 var cadence: float=sin(phase)
 var stride: float=cadence*intensity*(0.85 if sprint else 0.64)
 for i in range(2):
  var side: float=1.0 if i==0 else -1.0
  # Fore/aft run and lateral sidestep are separate local rotations.
  rig.arms[i].rotation.x=side*stride*forward
  rig.arms[i].rotation.z=side*0.05+side*stride*lateral*0.34
  # Elbows always bend relative to the rotating parent arm, never world +X.
  var compression: float=absf(stride)*(0.16+0.20*absf(forward)+0.12*absf(lateral))
  rig.forearms[i].rotation.x=-0.18-compression
 rig.set_meta("motion_source","EXO_original_local_8directions")
