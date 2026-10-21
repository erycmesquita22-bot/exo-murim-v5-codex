from pathlib import Path
import hashlib,json
R=Path('/mnt/data/C03_ALFA_WORK'); entries=json.loads((R/'C03_TRANSFERENCIA/MANIFESTO-ARQUIVOS-ALTERADOS.json').read_text())
def patch(rel,a,b,why):
 p=R/rel;s=p.read_text(); assert s.count(a)==1,(rel,s.count(a),a[:40]);new=s.replace(a,b); p.write_text(new)
 entries.append({'path':rel,'action':'modified','reason':why,'before':hashlib.sha256(s.encode()).hexdigest(),'after':hashlib.sha256(new.encode()).hexdigest()})
patch('convergence/game.gd','''\tif convergence_ready and current_region>=0:
\t\t# Respawn in current region, not the retired legacy camp.
\t\tvar saved_region: int=current_region
\t\treturn_home()
\t\tcall_deferred("change_region",saved_region,"")
\t\treturn
\tsuper.resume_checkpoint()''','''\tif convergence_ready and current_region>=0 and is_instance_valid(active_region):
\t\t# Restore combat/stamina without discarding the procedural region or its save.
\t\tsuper.resume_checkpoint()
\t\tvar anchor: Vector3=Vector3(0,active_region.data.center_h+0.08,0)
\t\tvar safe: Vector3=regional_spawn(active_region,anchor)
\t\tif safe.is_finite():prepare_player_spawn(safe)
\t\telse:message("Sem piso regional seguro para ressurgimento; preservando estado.")
\t\tupdate_camera()
\t\treturn
\tsuper.resume_checkpoint()''','C03 safe respawn without transient legacy save or losing current region')
patch('convergence/game.gd','''\tif player.position.distance_to(Vector3(0,active_region.data.center_h,6))<4:return_home();return''','''\t# Old initial enclosure is not accessible through gameplay. Travel uses real regional gates.
\tif player.position.distance_to(Vector3(0,active_region.data.center_h,6))<4:
\t\tmessage("Para viajar, siga as trilhas até as passagens regionais.");return''','C03 disable interactive legacy initial enclosure return')
patch('convergence/game.gd','''\treturn "E • Retornar ao recinto" if player.position.distance_to(Vector3(0,active_region.data.center_h,6))<4 else "Siga as trilhas até as passagens"''','''\treturn "Siga as trilhas até as passagens regionais"''','C03 no obsolete return hint')
patch('exo_core/persistence/save_coordinator.gd','''  if int(old_world.get("schema",-1))!=1:return false
  if not old_world.get("events") is Dictionary:return false''','''  if int(old_world.get("schema",-1)) not in [1,2]:return false
  if str(old_world.get("seed",""))!=str(source_world.get("seed","")):return false
  if not old_world.get("events") is Dictionary:return false
  if int(old_world.get("schema",-1))==2 and not old_world.get("claim_receipts") is Dictionary:return false''','C02 validate existing migration backup schemas 1/2, seed, identity and receipts')
(R/'C03_TRANSFERENCIA/MANIFESTO-ARQUIVOS-ALTERADOS.json').write_text(json.dumps(entries,indent=2,ensure_ascii=False))
d=json.loads((R/'C03_TRANSFERENCIA/ESTADO-INTEGRACAO-C03.json').read_text())
d['modified_or_added_count']=len(entries)
d['notes']=[v for v in d['notes'] if not v.startswith('Existing base contains active legacy home flows')]+['Legacy home preserved internally for remaining prologue/QA, but player E-return disabled and creator defers to procedural region; native QA remains required']
(R/'C03_TRANSFERENCIA/ESTADO-INTEGRACAO-C03.json').write_text(json.dumps(d,indent=2,ensure_ascii=False))
print('legacy gameplay return disabled and respawn made region-local; backup validation strengthened')
