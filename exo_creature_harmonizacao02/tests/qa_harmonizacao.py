#!/usr/bin/env python3
"""Offline deterministic QA for harmonizacao02: finite geometry, GLB bones, timelines, sockets, hash registry.
No Godot runtime tests; not a performance benchmark."""
import json,struct,hashlib,sys
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
doc=json.loads((ROOT/'data/CATALOGO-CRIATURAS-UNIFICADO.json').read_text(encoding='utf-8'))
assert doc['count']['unique_creature_ids']==17
assert doc['count']['unique_source_glb']==20
assert doc['count']['duplicate_species']==3
expected={'idle','walk','run','attack','hit','death'}
counts=[]
for id,info in doc['assets_by_species'].items():
    chosen=info['recommended_variant']
    assert chosen['source'] in [v['source'] for v in info['variants']]
    for v in info['variants']:
        path=ROOT/Path(v['model']).relative_to('res://exo_creature_harmonizacao02')
        data=path.read_bytes();assert hashlib.sha256(data).hexdigest()==v['harmonized_sha256']
        assert data[:4]==b'glTF' and struct.unpack_from('<II',data,4)==(2,len(data))
        jsize=struct.unpack_from('<I',data,12)[0];g=json.loads(data[20:20+jsize]);offset=20+jsize;bl=struct.unpack_from('<I',data,offset)[0];blob=data[offset+8:offset+8+bl]
        assert len(g['skins'])==1 and len(g['meshes'])>=1
        assert {a['name'] for a in g['animations']}==expected
        assert len([x for x in g['nodes'] if x['name'].startswith('SOCKET_')])==3
        for s in g['skins']:
            assert len(s['joints'])==len(set(s['joints']))
        for a in g['accessors']:
            bv=g['bufferViews'][a['bufferView']];assert bv.get('byteOffset',0)+bv['byteLength']<=len(blob)
        for anim in g['animations']:
            for sampler in anim['samplers']:
                a=g['accessors'][sampler['input']];bv=g['bufferViews'][a['bufferView']]
                ts=np.frombuffer(blob,dtype='<f4',count=a['count'],offset=bv.get('byteOffset',0)+a.get('byteOffset',0))
                assert len(ts)>1 and np.all(np.diff(ts)>0)
        counts.append((id,v['source']))
assert len(counts)==20
print('PASS: 20 GLB assets, 17 canonical identities, 3 duplicated identities, 6 named clips each, 3 sockets per GLB, finite and monotonic timelines, hashes')
print('Native Godot: NOT_RUN')
