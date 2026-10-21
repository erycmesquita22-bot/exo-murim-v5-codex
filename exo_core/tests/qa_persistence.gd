extends SceneTree
const Save=preload("res://journey_save.gd")
var failures: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label)
func _initialize() -> void:
 var args: PackedStringArray=OS.get_cmdline_user_args()
 var path: String="user://exo_core_crash_test.json"
 if "crash" in args:
  var s=Save.new(path,101);s.data.seconds=10
  if not s.write():quit(2);return
  s.data.seconds=99
  s.save_coordinator.fault_injector=func(stage):
   if stage=="before_replace":OS.kill(OS.get_process_id())
  s.write();quit(3);return
 var s=Save.new(path,101)
 check(s.load_progress() and s.data.seconds==10,"recover_committed_backup_after_process_kill")
 check(FileAccess.file_exists(path+".tmp"),"uncommitted_tmp_preserved")
 check(s.write(),"write_after_recovery")
 # Existing v4 without core fields must be accepted, backed up, upgraded without losing values.
 var legacy: Dictionary=s.data.duplicate(true);legacy.erase("exo_core");legacy.seconds=37
 var old_path: String="user://exo_core_legacy_v4.json"
 if FileAccess.file_exists(old_path+".pre-exocore01.json"):DirAccess.remove_absolute(old_path+".pre-exocore01.json")
 FileAccess.open(old_path,FileAccess.WRITE).store_string(JSON.stringify(legacy))
 var old_bytes: String=FileAccess.get_file_as_string(old_path)
 var m=Save.new(old_path);check(m.load_progress(),"load_legacy_v4_optional_missing")
 check(m.write() and m.data.version==4 and m.data.seconds==37,"v4_preserved")
 check(FileAccess.get_file_as_string(old_path+".pre-exocore01.json")==old_bytes,"byte_exact_migration_backup")
 var committed_bytes: String=FileAccess.get_file_as_string(old_path)
 m.data.exo_core.schema=999
 check(not m.write(),"future_schema_rejected")
 check(FileAccess.get_file_as_string(old_path)==committed_bytes,"failed_write_does_not_replace_primary")
 print("EXO_PERSISTENCE_QA ",JSON.stringify({"checks":checks,"failures":failures}));quit(int(not failures.is_empty()))
func safe_data(path: String) -> Dictionary:return JSON.parse_string(FileAccess.get_file_as_string(path))
