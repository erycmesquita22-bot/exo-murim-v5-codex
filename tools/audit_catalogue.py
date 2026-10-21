"""Compare executed representatives with the supplied EXO source, without pretending to port it all."""
import json
from pathlib import Path
p=Path(__file__).resolve().parents[1]
source=json.loads((p/'exo-reference-rules.json').read_text())
actives={v['id']:v for v in source['actives']}
passives={v['id']:v for v in source['passives']}
report={'source_content_version':source['contentVersion'],'counts_in_source':{k:len(source[k]) for k in ['classes','titles','actives','passives']},'implemented':[]}
for group,lookup in [('skills',actives),('passives',passives)]:
 for entry in json.loads((p/'data'/(group+'.json')).read_text()):
  canonical=lookup.get(entry['id'])
  report['implemented'].append({'id':entry['id'],'type':group,'status':'executable-adapted' if canonical else 'murim-adaptation','source_name':canonical.get('displayName') if canonical else None,'requirements_in_source':canonical.get('requirements') if canonical else None,'base_effects':'adapted','mastery_curve':'source-table' if group=='skills' else 'partial-event-counter','full_requirements':'pending-level-attribute-class-systems'})
  if canonical and group=='skills':
   rules=json.loads((p/'exo_mastery.json').read_text())['actives'][entry['id']]
   for key in ['masteryStep','maxMasteryRank','damageIncreasePerRank','costReductionPerRank','cooldownReductionPerRank']:
    if key in canonical:assert rules[key]==canonical[key],(entry['id'],key)
(p/'data/SOURCE-AUDIT.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print('Audit:',len(report['implemented']),'representatives;',report['counts_in_source'])
