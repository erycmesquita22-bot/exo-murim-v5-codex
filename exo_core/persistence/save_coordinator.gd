extends RefCounted
const Migrations=preload("res://exo_core/persistence/migration_registry.gd")
const WorldSeed=preload("res://procedural/world_state.gd")
var owners: Dictionary={}
var busy:=false
var last_error:=""
var fault_injector: Callable
func checkpoint(stage: String) -> void:
 if fault_injector.is_valid():fault_injector.call(stage)
func register_domain(key: String,owner_id: String,validator: Callable) -> bool:
 if owners.has(key) or not validator.is_valid():return false
 owners[key]={"owner":owner_id,"validator":validator}
 return true
func _migration_backup(path: String) -> bool:
 if not FileAccess.file_exists(path):return true
 var snapshot: String=FileAccess.get_file_as_string(path)
 if snapshot.is_empty():return false
 var source_decoded: Variant=JSON.parse_string(snapshot)
 if not source_decoded is Dictionary or int(source_decoded.get("version",-1))!=4:return false
 if not source_decoded.get("world") is Dictionary or not WorldSeed.valid(source_decoded.world):return false
 var backup: String=path+".pre-corep01.json"
 if FileAccess.file_exists(backup):
  var previous_backup: String=FileAccess.get_file_as_string(backup)
  if previous_backup.is_empty():return false
  var parsed_backup: Variant=JSON.parse_string(previous_backup)
  var parsed_source: Variant=JSON.parse_string(snapshot)
  if not parsed_backup is Dictionary or not parsed_source is Dictionary:return false
  if int(parsed_backup.get("version",-1))!=4 or int(parsed_source.get("version",-1))!=4:return false
  if not parsed_backup.get("world") is Dictionary or not parsed_source.get("world") is Dictionary:return false
  var old_world: Dictionary=parsed_backup.world
  var source_world: Dictionary=parsed_source.world
  if str(old_world.get("id",""))!=str(source_world.get("id","")) or str(old_world.get("id",""))=="":return false
  if int(old_world.get("schema",-1)) not in [1,2]:return false
  if str(old_world.get("seed",""))!=str(source_world.get("seed","")):return false
  if not old_world.get("events") is Dictionary:return false
  if int(old_world.get("schema",-1))==2 and not old_world.get("claim_receipts") is Dictionary:return false
  if not parsed_backup.get("character") is Dictionary or not parsed_backup.get("items") is Array:return false
  if not WorldSeed.valid(old_world) or not WorldSeed.valid(source_world):return false
  # Campaign identity includes character identity when both snapshots possess one.
  var old_character: Dictionary=parsed_backup.character
  var source_character: Dictionary=parsed_source.get("character",{})
  if not source_character is Dictionary:return false
  for key in ["name","skin","id"]:
   if old_character.has(key) and source_character.has(key) and old_character[key]!=source_character[key]:return false
  if parsed_backup.has("exo_core") and not Migrations.valid(parsed_backup.exo_core):return false
  return true
 var tmp: String=backup+".tmp"
 var f:=FileAccess.open(tmp,FileAccess.WRITE)
 if f==null:return false
 f.store_string(snapshot);f.flush();f.close()
 if FileAccess.get_file_as_string(tmp).sha256_text()!=snapshot.sha256_text():return false
 if DirAccess.rename_absolute(tmp,backup)!=OK:return false
 return FileAccess.get_file_as_string(backup).sha256_text()==snapshot.sha256_text()
func commit(save: RefCounted) -> bool:
 if busy:last_error="reentrant_save";return false
 busy=true
 var before: Dictionary=save.data.duplicate(true)
 var disk: Variant=save.decode(FileAccess.get_file_as_string(save.path)) if FileAccess.file_exists(save.path) else null
 var migrate_world: bool=disk is Dictionary and disk.get("world") is Dictionary and disk.world.get("schema")==1
 var migrate_core: bool=disk is Dictionary and disk.get("exo_core") is Dictionary and disk.exo_core.get("schema")==1
 if (migrate_world or migrate_core) and not _migration_backup(save.path):
  last_error="migration_backup_failed";busy=false;return false
 if not Migrations.upgrade(save.data) or (save.data.has("world") and not WorldSeed.upgrade(save.data.world)):
  save.data=before;last_error="migration_invalid";busy=false;return false
 for key in owners:
  if save.data.has(key) and not bool(owners[key].validator.call(save.data[key])):
   save.data=before;save.status="Schema inválido: "+key;last_error=save.status;busy=false;return false
 var original: Variant=save.decode(FileAccess.get_file_as_string(save.path)) if FileAccess.file_exists(save.path) else null
 if original is Dictionary and not original.has("exo_core"):
  var backup: String=save.path+".pre-exocore01.json"
  if not FileAccess.file_exists(backup):
   var f:=FileAccess.open(backup,FileAccess.WRITE)
   if f==null:save.data=before;busy=false;return false
   f.store_string(FileAccess.get_file_as_string(save.path));f.flush();f.close()
 var ok: bool=save._commit_legacy()
 last_error="" if ok else str(save.status)
 if not ok:save.data=before
 busy=false
 return ok
