extends RefCounted
## Short hand-authored pose loops on the approved 25-bone V4 rig.
const ROOT := "EXO_Rig/Skeleton3D:"
static func add_cultivation(player: AnimationPlayer) -> void:
 var library := AnimationLibrary.new()
 # Gather: sink at the knees, draw energy from the ground to the abdomen.
 library.add_animation("Gather_Qi",_clip(2.0,{"spine":[Vector3(.08,0,0),Vector3(.23,0,0),Vector3(.08,0,0)],"head":[Vector3(-.05,0,0),Vector3(.11,0,0),Vector3(-.05,0,0)],"upper_arm_L":[Vector3(.06,0,-.12),Vector3(.35,0,-.42),Vector3(.51,0,-.28)],"upper_arm_R":[Vector3(.06,0,.12),Vector3(.35,0,.42),Vector3(.51,0,.28)],"forearm_L":[Vector3.ZERO,Vector3(.25,0,.16),Vector3(.46,0,.10)],"forearm_R":[Vector3.ZERO,Vector3(.25,0,-.16),Vector3(.46,0,-.10)],"thigh_L":[Vector3.ZERO,Vector3(.10,0,-.08),Vector3.ZERO],"thigh_R":[Vector3.ZERO,Vector3(.10,0,.08),Vector3.ZERO]},[1.31,1.19,1.25]))
 # Circulate: alternate hands and shoulders while the torso twists and breathes.
 library.add_animation("Circulate_Qi",_clip(5.0,{"spine":[Vector3(-.03,-.14,0),Vector3(-.09,.16,0),Vector3(-.03,-.14,0)],"head":[Vector3(.04,.08,0),Vector3(-.02,-.08,0),Vector3(.04,.08,0)],"upper_arm_L":[Vector3(.46,0,-.33),Vector3(.16,0,-.73),Vector3(.46,0,-.33)],"upper_arm_R":[Vector3(.14,0,.68),Vector3(.45,0,.34),Vector3(.14,0,.68)],"forearm_L":[Vector3(.44,0,.13),Vector3(.27,0,.27),Vector3(.44,0,.13)],"forearm_R":[Vector3(.26,0,-.24),Vector3(.48,0,-.12),Vector3(.26,0,-.24)]},[1.26,1.30,1.26]))
 # Release: two-handed measured push and return; visual wave carries the impact.
 library.add_animation("Release_Qi",_clip(1.8,{"spine":[Vector3(-.10,0,0),Vector3(.17,0,0),Vector3.ZERO],"head":[Vector3.ZERO,Vector3(-.09,0,0),Vector3.ZERO],"upper_arm_L":[Vector3(.36,0,-.35),Vector3(.79,0,-.18),Vector3(.25,0,-.25)],"upper_arm_R":[Vector3(.36,0,.35),Vector3(.79,0,.18),Vector3(.25,0,.25)],"forearm_L":[Vector3(.40,0,.14),Vector3(.12,0,.04),Vector3(.31,0,.12)],"forearm_R":[Vector3(.40,0,-.14),Vector3(.12,0,-.04),Vector3(.31,0,-.12)]},[1.27,1.34,1.31]))
 # Settle restores posture slowly so the next gather has a readable beginning.
 library.add_animation("Cultivate",_clip(2.2,{"spine":[Vector3(.05,0,0),Vector3(-.05,0,0),Vector3(.05,0,0)],"head":[Vector3(-.03,0,0),Vector3(.03,0,0),Vector3(-.03,0,0)],"upper_arm_L":[Vector3(.25,0,-.25),Vector3(.36,0,-.38),Vector3(.25,0,-.25)],"upper_arm_R":[Vector3(.25,0,.25),Vector3(.36,0,.38),Vector3(.25,0,.25)],"forearm_L":[Vector3(.22,0,.11),Vector3(.36,0,.18),Vector3(.22,0,.11)],"forearm_R":[Vector3(.22,0,-.11),Vector3(.36,0,-.18),Vector3(.22,0,-.11)]},[1.29,1.31,1.29]))
 player.add_animation_library("village_life",library)
static func install(player: AnimationPlayer, profile: String) -> String:
 var library: AnimationLibrary
 if player.has_animation_library("village_life"):
  library = player.get_animation_library("village_life")
 else:
  library = AnimationLibrary.new()
  player.add_animation_library("village_life",library)
 library.add_animation("LookAround",_clip(3.2,{"head":[Vector3(0,-.24,0),Vector3(0,.22,0),Vector3(0,-.24,0)],"spine":[Vector3(0,-.05,0),Vector3(0,.05,0),Vector3(0,-.05,0)]},[1.32,1.335,1.32]))
 library.add_animation("Stretch",_clip(3.6,{"spine":[Vector3(-.02,0,0),Vector3(-.10,0,0),Vector3(-.02,0,0)],"upper_arm_L":[Vector3(0,0,-.20),Vector3(0,0,-1.12),Vector3(0,0,-.20)],"upper_arm_R":[Vector3(0,0,.20),Vector3(0,0,1.12),Vector3(0,0,.20)],"head":[Vector3.ZERO,Vector3(-.08,0,0),Vector3.ZERO]},[1.32,1.36,1.32]))
 library.add_animation("Elder_Idle",_clip(4.2,{"spine":[Vector3(.085,0,0),Vector3(.10,.035,0),Vector3(.085,0,0)],"head":[Vector3(-.04,-.10,0),Vector3(-.02,.11,0),Vector3(-.04,-.10,0)]},[1.29,1.305,1.29]))
 var work := "Resident_Gesture"
 match profile:
  "field":
   work = "Field_Work"
   library.add_animation(work,_clip(2.8,{"spine":[Vector3(.18,0,0),Vector3(.44,0,0),Vector3(.18,0,0)],"upper_arm_L":[Vector3(.28,0,-.16),Vector3(.60,0,-.32),Vector3(.28,0,-.16)],"upper_arm_R":[Vector3(.34,0,.15),Vector3(.62,0,.29),Vector3(.34,0,.15)],"head":[Vector3(-.05,0,0),Vector3(.08,0,0),Vector3(-.05,0,0)]},[1.29,1.20,1.29]))
  "trade":
   work = "Offer_Wares"
   library.add_animation(work,_clip(2.9,{"upper_arm_R":[Vector3(0,0,.25),Vector3(.28,0,.82),Vector3(0,0,.25)],"forearm_R":[Vector3.ZERO,Vector3(.18,0,.48),Vector3.ZERO],"spine":[Vector3.ZERO,Vector3(0,-.12,0),Vector3.ZERO],"head":[Vector3.ZERO,Vector3(0,.09,0),Vector3.ZERO]},[1.32,1.33,1.32]))
  "serve":
   work = "Serve_Tea"
   library.add_animation(work,_clip(2.6,{"upper_arm_L":[Vector3(.16,0,-.34),Vector3(.34,0,-.52),Vector3(.16,0,-.34)],"upper_arm_R":[Vector3(.16,0,.34),Vector3(.34,0,.52),Vector3(.16,0,.34)],"forearm_L":[Vector3(.25,0,0),Vector3(.45,0,0),Vector3(.25,0,0)],"forearm_R":[Vector3(.25,0,0),Vector3(.45,0,0),Vector3(.25,0,0)],"spine":[Vector3.ZERO,Vector3(.12,0,0),Vector3.ZERO]},[1.32,1.30,1.32]))
  "guard":
   work = "Guard_Survey"
   library.add_animation(work,_clip(3.4,{"spine":[Vector3.ZERO,Vector3(0,.16,0),Vector3.ZERO],"head":[Vector3(0,-.22,0),Vector3(0,.28,0),Vector3(0,-.22,0)],"upper_arm_R":[Vector3.ZERO,Vector3(0,0,.20),Vector3.ZERO]},[1.32,1.33,1.32]))
  "martial","master":
   work = "Train_Form"
   library.add_animation(work,_clip(2.4,{"spine":[Vector3(0,-.16,0),Vector3(-.10,.18,0),Vector3(0,-.16,0)],"upper_arm_L":[Vector3(.23,0,-.40),Vector3(.12,0,-.88),Vector3(.23,0,-.40)],"upper_arm_R":[Vector3(.15,0,.70),Vector3(.32,0,.30),Vector3(.15,0,.70)],"forearm_L":[Vector3(0,0,.35),Vector3(0,0,.58),Vector3(0,0,.35)],"forearm_R":[Vector3(0,0,-.42),Vector3(0,0,-.25),Vector3(0,0,-.42)],"thigh_L":[Vector3.ZERO,Vector3(.10,0,-.13),Vector3.ZERO],"thigh_R":[Vector3.ZERO,Vector3(.10,0,.13),Vector3.ZERO]},[1.30,1.23,1.30]))
  _:
   library.add_animation(work,_clip(3.0,{"head":[Vector3.ZERO,Vector3(0,.09,0),Vector3.ZERO],"upper_arm_R":[Vector3.ZERO,Vector3(0,0,.32),Vector3.ZERO],"forearm_R":[Vector3.ZERO,Vector3(0,0,.26),Vector3.ZERO]},[1.32,1.33,1.32]))
 var approved_idle: Animation = player.get_animation("Idle")
 for name in library.get_animation_list(): _apply_approved_pose(library.get_animation(name),approved_idle)
 return "village_life/"+work
static func _apply_approved_pose(clip: Animation, reference: Animation) -> void:
 # V4's raw skeleton rests with horizontal arms. Every custom clip must retain
 # the artist-approved Idle rotations before adding a gesture offset.
 for original_index in reference.get_track_count():
  var type := reference.track_get_type(original_index)
  if type != Animation.TYPE_ROTATION_3D: continue
  var path := reference.track_get_path(original_index)
  var neutral: Quaternion = reference.track_get_key_value(original_index,0)
  var index := clip.find_track(path,Animation.TYPE_ROTATION_3D)
  if index < 0:
   index = clip.add_track(Animation.TYPE_ROTATION_3D)
   clip.track_set_path(index,path)
   for t in [0.0,clip.length*.5,clip.length]: clip.rotation_track_insert_key(index,t,neutral)
  else:
   for key in clip.track_get_key_count(index):
    var offset: Quaternion = clip.track_get_key_value(index,key)
    clip.track_set_key_value(index,key,neutral*offset)
static func _clip(duration: float, pose: Dictionary, pelvis: Array) -> Animation:
 var clip := Animation.new()
 clip.length = duration
 clip.loop_mode = Animation.LOOP_LINEAR
 for bone in pose:
  var frames: Array = pose[bone]
  var track := clip.add_track(Animation.TYPE_ROTATION_3D)
  clip.track_set_path(track,NodePath(ROOT+str(bone)))
  for i in 3: clip.rotation_track_insert_key(track,duration*float(i)/2.0,Quaternion.from_euler(frames[i]))
 var p := clip.add_track(Animation.TYPE_POSITION_3D)
 clip.track_set_path(p,NodePath(ROOT+"pelvis"))
 for i in 3: clip.position_track_insert_key(p,duration*float(i)/2.0,Vector3(0,float(pelvis[i]),0))
 return clip
