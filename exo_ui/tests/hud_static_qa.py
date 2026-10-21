"""Offline smoke checks: source wiring and dependency contracts, not Godot execution."""
from pathlib import Path
from zipfile import ZipFile
import re, json, hashlib
root=Path(__file__).resolve().parents[2]
hud=(root/'exo_ui/hud_murim.gd').read_text(encoding='utf8')
pause=(root/'pause_ui.gd').read_text(encoding='utf8')
old=(root/'exo_hud.gd').read_text(encoding='utf8')
menu=(root/'exo_menu.gd').read_text(encoding='utf8')
settings=(root/'ui/pages/settings.gd').read_text(encoding='utf8')
checks={
 'native_resource_exists':(root/'assets/manuscrito.otf').exists(),
 'live_qi_label':'BLUE, "Qi"' in hud and '"Mana"' not in hud,
 'player_health_real':'world.max_health' in hud and 'world.health' in hud,
 'progress_real':'Rewards.required_total' in hud and 'journey_dynamic' in hud,
 'cooldown_real':'world.techniques.cooldowns[i]' in hud,
 'regional_map_real':'data.settlement_roads' in hud and 'data.lots' in hud,
 'missions_real':'journey_data.get("quests", {})' in hud,
 'currency_real':'world.journey.data.get("coins", 0)' in hud,
 'portrait_real':'world.model.skin.albedo_texture' in hud,
 'hotbar_real':'world.techniques.DATA[i]' in hud,
 'inventario_key_I':'event.physical_keycode==KEY_I' in pause and 'exo.open("inventario")' in pause,
 'menu_P_and_map_TAB':'KEY_P,KEY_TAB,KEY_I' in pause and 'show_extra(event.physical_keycode==KEY_TAB)' in pause,
 'legacy_hud_retained':'EXO Murim (oficial)' in old and 'STYLES=' in old,
 'new_hud_wired':'res://exo_ui/hud_murim.gd' in pause,
 'avoid_quest_overlay':'quest.get_parent().get_parent().visible' in pause,
 'help_consistent':'I • inventário' in settings,
 'menu_qi_label':'Qi %.0f / 100' in menu,
 'no_unsafe_stats_updates':not bool(re.search(r'\bworld\.(?:health|max_health|techniques|journey)\s*(?:=(?!=)|\+=|-=)',hud)),
 'no_custom_save_state':'FileAccess.' not in hud and 'save_progress(' not in hud,
 'godot_smoke_script':(root/'exo_ui/tests/qa_hud_01.gd').exists(),
}
# Check lexical delimiter balance across modified scripts, ignore strings/comments.
def balanced(src):
 stack=[];pairs={')':'(',']':'[','}':'{'};instr=False;esc=False
 for line in src.splitlines():
  for c in line:
   if not instr and c=='#':break
   if instr:
    if esc:esc=False
    elif c=='\\':esc=True
    elif c=='"':instr=False
    continue
   if c=='"':instr=True;continue
   if c in '([{':stack.append(c)
   if c in ')]}':
    if not stack or stack.pop()!=pairs[c]:return False
  if instr: return False
 return not stack
for path in ['exo_ui/hud_murim.gd','pause_ui.gd','exo_hud.gd','exo_menu.gd','ui/pages/settings.gd','exo_ui/tests/qa_hud_01.gd']:
 checks['lexical_'+path]=balanced((root/path).read_text('utf8'))
result={'status':'PASS' if all(checks.values()) else 'FAIL','tests_total':len(checks),'passed':sum(checks.values()),'checks':checks,'scope':'static only; Godot executable unavailable','source_sha256':hashlib.sha256(hud.encode('utf8')).hexdigest()}
(root/'exo_ui/RESULTADOS-QA-HUD-01.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n','utf8')
print(json.dumps(result,ensure_ascii=False,indent=2))
if result['status'] != 'PASS':raise SystemExit(1)
