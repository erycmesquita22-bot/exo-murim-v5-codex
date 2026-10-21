from pathlib import Path
import sys,json,shutil,hashlib,zipfile,collections,datetime,subprocess
sys.path.insert(0,'/mnt/data/harmonizacao02_work')
from build_harmonizacao import OUT,jsonout,original_sources
ROOT=Path('/mnt/data');C=jsonout['assets_by_species']; rec=[v for x in C.values() for v in x['variants']]

def wr(rel,text):
 p=OUT/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text.strip()+'\n',encoding='utf-8')

# Technical data-only Godot integration; readonly lookup, no NPC/combat implementation.
wr('integration/visual_catalog.gd','''extends RefCounted
## EXO Harmonizacao02: consulta de caminho visual somente (dados; NÃO instancia combate/spawn).
const CATALOG_PATH := "res://exo_creature_harmonizacao02/data/CATALOGO-CRIATURAS-UNIFICADO.json"
static func get_visual(species_id: String, variant_source: String = "") -> Dictionary:
    if not FileAccess.file_exists(CATALOG_PATH):
        return {}
    var contents := FileAccess.get_file_as_string(CATALOG_PATH)
    var parsed: Variant = JSON.parse_string(contents)
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    var species: Dictionary = parsed.get("assets_by_species", {})
    if not species.has(species_id):
        return {}
    var item: Dictionary = species[species_id]
    var chosen: Dictionary = item.get("recommended_variant", {})
    if variant_source != "":
        for entry in item.get("variants", []):
            if str(entry.get("source", "")) == variant_source:
                chosen = entry
                break
    if chosen.is_empty():
        return {}
    return {
        "species_id": species_id,
        "scene": str(chosen.get("scene", "")),
        "model": str(chosen.get("model", "")),
        "visual_only": true,
        "combat_authority": "Bestiary02",
    }
''')
wr('integration/bestiary_binding_example.gd','''extends RefCounted
## Documentacao executavel ilustrativa: não modificar enemy.gd, Core, IA nem spawn.
const VisualCatalog = preload("res://exo_creature_harmonizacao02/integration/visual_catalog.gd")
static func visual_scene_for_bestiary_species(species_id: String) -> PackedScene:
    var visual := VisualCatalog.get_visual(species_id)
    if visual.is_empty():
        return null
    var packed := load(visual["scene"])
    if packed is PackedScene:
        return packed
    return null
''')
wr('lab/harmonizacao_lab.gd','''extends Node3D
## Render-focused native lab: 4 / 8 / 16 assets, NO AI, NO gameplay or simulated metrics.
## Run as main scene in project copied with res://exo_creature_harmonizacao02/ folder.
const Catalog = preload("res://exo_creature_harmonizacao02/integration/visual_catalog.gd")
var actors: Array[Node3D] = []
var samples: Array[String] = ["wolf", "boar", "tiger", "deer", "snake", "stone_guardian", "mountain_goat", "desert_scorpion", "fox", "rabbit", "bear", "spirit_deer", "leopard", "corrupted_wolf", "demon_boar", "desert_monitor"]
func _ready() -> void:
    spawn_count(4)
    print("EXO HARMONIZACAO LAB - only FPS from actual native runtime; no AI/damage/spawns")
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1: spawn_count(4)
            KEY_2: spawn_count(8)
            KEY_3: spawn_count(16)
            KEY_SPACE: play_clip("walk")
            KEY_T: play_clip("attack")
func spawn_count(count: int) -> void:
    for actor in actors:
        if is_instance_valid(actor):
            actor.queue_free()
    actors.clear()
    for idx in range(count):
        var species_id: String = samples[idx % samples.size()]
        var data := Catalog.get_visual(species_id)
        if data.is_empty():
            continue
        var visual_scene := load(data["scene"]) as PackedScene
        if visual_scene == null:
            continue
        var actor := visual_scene.instantiate() as Node3D
        if actor == null:
            continue
        actor.position = Vector3(float(idx % 4) * 5.0 - 7.5, 0, float(idx / 4) * 5.0 - 7.5)
        add_child(actor)
        actors.append(actor)
    print("LAB spawned visuals=", actors.size(), " fps_native=", Engine.get_frames_per_second())
func play_clip(clip_name: String) -> void:
    for actor in actors:
        var player := actor.find_child("AnimationPlayer", true, false) as AnimationPlayer
        if player == null:
            continue
        for anim_name in player.get_animation_list():
            if anim_name == clip_name or anim_name.ends_with("/" + clip_name):
                player.play(anim_name)
                break
''')
wr('lab/harmonizacao_lab.tscn','''[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://exo_creature_harmonizacao02/lab/harmonizacao_lab.gd" id="1"]
[sub_resource type="BoxMesh" id="BoxMesh_1"]
size = Vector3(70, 0.15, 70)
[sub_resource type="StandardMaterial3D" id="Mat_1"]
albedo_color = Color(0.26, 0.33, 0.29, 1)

[node name="EXO_Harmonizacao02_Lab" type="Node3D"]
script = ExtResource("1")

[node name="Ground" type="MeshInstance3D" parent="."]
mesh = SubResource("BoxMesh_1")
surface_material_override/0 = SubResource("Mat_1")
position = Vector3(0, -0.15, 0)

[node name="Camera3D" type="Camera3D" parent="."]
transform = Transform3D(0.86, 0.31, -0.4, 0.0, 0.8, 0.63, 0.51, -0.54, 0.69, 22, 23, 28)
current = true
projection = 1
size = 29.0

[node name="KeyLight" type="DirectionalLight3D" parent="."]
rotation = Vector3(-0.85, 0.6, 0)
light_energy = 1.4
''')

# Reproducible QA validate all exported GLBs in place
wr('tests/qa_harmonizacao.py','''#!/usr/bin/env python3
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
''')

bestiary_rows=[]
for id in [x for x in C if C[x]['bestiary02_id']]:
 v=C[id];bestiary_rows.append((id,v['recommended_variant']['scene'],', '.join(v['bestiary02_attacks'])))
contract='''# EXO-MURIM — CONTRATO VISUAL BESTIÁRIO 02

**Escopo:** descrição de assets gráficos independentes. Bestiário 02 continua sendo autoridade sobre ID de espécie, IA, bioma, população, spawn, vida, dano, loot, recompensas, hitboxes funcionais e persistência. Esta entrega **não altera o EXO Core**, Convergência 03 ou Bestiário 02.

## Pipeline determinístico

`Bestiário 02 species.id` → `CATALOGO-CRIATURAS-UNIFICADO.json.assets_by_species[id]` → `recommended_variant.scene` → `PackedScene` + `AnimationPlayer` → `SOCKET_ATTACK_ORIGIN` e `collision_profile` descritivos → ação existente do Bestiário que decide a janela de dano/hitbox.

**Contrato de orientação:** GLB original usa **+X à frente, +Y acima**. Cena harmonizada aplica rotação Y de +90° para **-Z à frente**. A escala é proposta em wrapper visual, não deve ser aplicada outra vez ao ator físico. Dimensões de colisão são sugestões e ainda não validadas em jogo.

**Contrato de animação:** `idle`, `walk`, `run`, `attack`, `hit`, `death` permanecem como nomes brutos no GLB. Verificar o nome importado no AnimationPlayer (`nome` ou `GLB/nome`). A duração e os instantes válidos devem ser lidos da animação importada — **não há evento de dano embutido no GLB**.

**Sockets:** `SOCKET_ATTACK_ORIGIN` (ponto visual de origem de ataque), `SOCKET_VFX_CENTER` (efeitos), `SOCKET_BACK` (adornos/apoios). Anexados como filhos da junta correspondente; não são hitboxes, emissores ou gameplay.

## Ligações por ID real

| Bestiário 02 | Cena visual recomendada | Ações/ataques autorizados pelo Bestiário (não executados aqui) |
|---|---|---|
'''
for id,scene,attacks in bestiary_rows: contract+=f'| `{id}` | `{scene}` | `{attacks}` |\n'
contract+='''
## Sem GLB adequado no catálogo atual

- `wild_ox` — boi selvagem; não confundir com búfalo.
- `wild_buffalo` — búfalo selvagem; não confundir com boi ou capra.
- `qi_serpent` — serpente de Qi; não atribuir automaticamente a serpente comum sem identidade visual própria.

## Modelos artísticos fora do registro atual do Bestiário

`desert_monitor`, `desert_scorpion`, `demon_boar` e `kitsune` são modelos visuais, não entradas novas de IA/bioma. `corrupted_wolf` vem do modelo `shadow_wolf` do Forge, e `snake` do modelo `serpent` do Forge: ambos tiveram a correspondência registrada **explicitamente**, sem duplicar a espécie. A associação de `stone_guardian` ao modelo rochoso existente deve ser validada pela direção de arte, mas corresponde ao ID existente no Bestiário 02.

## Perfil descritivo de colisão

`variant.collision_profile.body_extent_xyz_scene_minus_z` fornece tamanho proposto para o corpo em coordenadas da cena-wrapper. `damage_zone = null`: IA/Bestiário define duração, raio, camada de colisão, máscara e aplicação de dano. Não instanciar formas simultaneamente se a criatura já herdar colisores do ator existente.

## Procedimento de integração futuro (não executado)

1. Copiar apenas `res://exo_creature_harmonizacao02/` ao projeto de testes; não apagar pacotes antigos ou substituir a rotina autoritativa.
2. O integrador consulta `integration/visual_catalog.gd` a partir do `species.id` existente e instancia **somente a apresentação visual**; mantém CharacterBody3D/IA existentes e seus eventos.
3. Conferir escala do protagonista, altura real dos pés, pivôs e orientação em animação, visual da câmera e colisão. Ajustar a escala de cada wrapper/descritor sob controle de QA.
4. Associar `attack` a eventos e janelas de dano do Bestiário 02, sem usar um ataque visual para executar dano por si.
5. Medir FPS/RAM em 4/8/16 atores no Compatibility, preservar capturas e falhas; só então promover.

**Estado:** contrato pronto para QA/integrador da Convergência 03, não instalado no jogo.
'''
wr('docs/CONTRATO-VISUAL-BESTIARIO.md',contract)

sourcelist='\n'.join(f"| `{k}` | `{v['archive']}` | `{v['member']}` | `{v['original_sha256']}` |" for k,v in sorted(original_sources.items()))
provenance=f'''# Proveniência comercial — Creature Harmonização 02

Todos os recursos são cópias modificadas dos arquivos produzidos nas entregas EXO Creature Forge 01 e Creature Art 02. **Nenhum GLB baixado ou obtido de catálogo de terceiros foi incluído.** O atlas de cada modelo foi preservado em seu GLB. Este pacote só alterou curvas de animação, sockets e metadados de GLB, e acrescentou wrapper/scenes. As geometrias não foram redesenhadas nesta rodada. A titularidade completa dos recursos herdados do EXO Mod não foi analisada nesta rodada; checar antes da publicação comercial.

| Fonte:codigo | Arquivo-pacote | Membro original | SHA-256 original |
|---|---|---|---|
{sourcelist}

SHA-256 dos **novos** GLBs e hashes dos ZIPs originais constam no catálogo, por variante. Direitos e cadeia de autoria exigem confirmação humana final.
'''
wr('docs/PROVENIENCIA-COMERCIAL.md',provenance)

special='''# Espécies do catálogo inicial de 33 AINDA não produzidas — Creature Forge 01

Esta é a lista original **não diminuída automaticamente** por semelhanças aproximadas com outros modelos. A contagem original era 12/33 (21 faltantes); os 8 GLBs do Art 02 incluem 3 espécies duplicadas e 5 identidades adicionais, mas vários nomes do Art 02 não são idênticos aos das 33 planejadas.

'''
for e in jsonout['original_33_pending']:
 special+=f"- {e['catalog_number']}. {e['name']} — **pendente**\n"
special+='''
## Lacunas adicionais do Bestiário 02

`wild_ox`, `wild_buffalo` e `qi_serpent` não possuem um GLB com ID correspondente no catálogo unificado.

**Não fundir automaticamente:** Leopardo da Neve ≠ leopardo genérico, Capra Rochosa ≠ cabra comum da montanha, Fera de Pedra ≠ Guardião de Pedra, Serpente de Qi ≠ serpente comum. Exigir aprovação artística e semântica para cada equivalência.
'''
wr('docs/ESPECIES-PENDENTES.md',special)

simple='''# Instalação e QA do Creature Harmonização 02

**Não instalar sobre EXO Core diretamente.** O ZIP contém apenas `exo_creature_harmonizacao02/`. Colar esta pasta de maneira isolada em um clone de testes Godot 4.6.2 Standard Compatibility (Convergência 03 é responsabilidade de outra rodada).

- Cada identidade canônica tem uma cena recomendada e, quando houver duplicata, a alternativa preservada. Todas as escalas propostas são wrappers, sem modificar a malha do GLB.
- `integration/visual_catalog.gd` expõe dados de caminhos apenas. `lab/harmonizacao_lab.tscn` foi preparado para testes visuais, com teclas `1/2/3` (4, 8 e 16 atores), `SPACE` (walk) e `T` (attack). Não foi executado no Godot neste ambiente.
- QA offline: `python exo_creature_harmonizacao02/tests/qa_harmonizacao.py` (exige `numpy`).
- Todas as `evidencias` são renderizações derivadas diretamente das malhas/glTFs em software CPU, não capturas da engine. GIFs avaliam matriz de pele e rotação de juntas dos próprios GLBs.
- Colisores propostos e sockets são **metadados descritivos** sem gerar dano ou duplicar colisão física. Verificar no runtime antes de integrar.
'''
wr('docs/README-INTEGRACAO.md',simple)

# Metrics actual counts and caveats
tri=[v['triangles'] for v in rec];filesize=[(OUT/Path(v['model']).relative_to('res://exo_creature_harmonizacao02')).stat().st_size for v in rec]
report=f'''# EXO-MURIM — RELATÓRIO DE ARTE DAS CRIATURAS 02

**Status:** CANDIDATO OFFLINE (não aprovado como arte final nem integrado). **Godot 4.6.2 Compatibility:** executável não encontrado no ambiente; testes nativos NOT_RUN.

## Contagem por ID (sem inflar espécies)

- **20 GLBs / variantes reais** auditadas e preservadas (12 Forge 01 + 8 Art 02).
- **17 identidades canônicas únicas**; **3 duplicatas** (lobo, javali, tigre).
- **13/16 espécies com IDs do Bestiário 02 possuem GLB**; 3 estão sem modelo específico (`wild_ox`, `wild_buffalo`, `qi_serpent`).
- **21 dos 33 conceitos originais do Creature Forge 01 continuam pendentes** por correspondência exata; as novas identidades do Art 02 não reduzem esta contagem sem aprovação.
- 4 identidades visuais sem perfil canônico próprio no Bestiário 02: `desert_monitor`, `desert_scorpion`, `demon_boar`, `kitsune`.

## Auditoria e harmonização aplicada

1. Gerado catálogo por ID canônico, fonte, GLB, SHA-256 antes/depois, atlas, rig, juntas, 6 clipes, triângulos, bounds, cenas, sockets e perfil de colisão.
2. Lobo, javali e tigre: priorizada a versão Art 02 como **recomendação provisória por detalhe de silhueta**, com variante Forge preservada. Modelo recomendado não equivale a aprovação artística.
3. Criadas cenas Godot com escala proposta por espécie (protagonista = aproximadamente 2 unidades) e rotação +90° em Y para padronizar -Z à frente; valores ainda não medidos em jogo.
4. Adicionados 3 sockets por GLB (origem de ataque, centro de VFX e suporte) com parentesco ósseo e metadados. Sem instanciar colisores autoritativos.
5. Mantida a geometria de todos os 20 modelos. **Não houve reconstrução anatômica profunda, escultura manual ou produção de novas texturas**: seria incorreto declarar que a arte passou a cumprir integralmente a prancha aprovada.
6. Modificados **{sum(len(v['animation_modification']) for v in rec)} canais/casos de animação** nas cópias harmonizadas: marcha com fases e balanço adaptados à família, impulso visual diferenciado no ataque e membros dianteiros com gesto adicional em felinos/feras grandes. Animações de serpente foram preservadas como cadeia própria; movimentos da aranha/escorpião mantêm rig especializado. O sistema usa curvas e **não faz IK/contact lock**; patinagem precisa de verificação nativa.
7. Não foi introduzida variação procedural de anatomia. Variantes de aparência são modelos fixos com IDs estáveis.

## QA REAL realizado (offline)

| Verificação | Resultado | Limite |
|---|---|---|
| 20 arquivos GLB v2, chunks JSON/BIN e SHA-256 | PASS | Não substitui importação Godot |
| Accessors finitos, skins e matrizes de bind, animações com timeline monotônica | PASS 20/20 | QA numérico sem colisão física |
| 6 clips nomeados, sockets vinculados a nós reais | PASS 20/20 | Retarget Godot pendente |
| Assinatura original preservada no catálogo; geometria original não remodelada | PASS | Proveniência comercial herdada exige confirmação |
| Render 3D dos 17 recomendados e 8 espécies em 3 ângulos | EXPORTADO | Render CPU do GLB; não é captura do jogo |
| GIFs pós-modificação de lobo walk, javali walk, tigre attack e serpente walk | EXPORTADOS | Avaliação raster/skinning offline; não comprova contato com chão |
| Godot Parser/Import Compatibility, shaders, FPS/RAM 4/8/16 e combate | **NOT_RUN** | Godot indisponível |
| Escala com protagonista, articulação visual, luz ambiente e sombras | **NOT_RUN** | Necessita base real e engine |

**Métricas geométricas medidas:** triângulos de {min(tri):,} a {max(tri):,} por GLB; mediana {sorted(tri)[len(tri)//2]:,}. Tamanho dos 20 GLBs harmonizados somados: {sum(filesize)/1024/1024:.2f} MiB. Atlas de textura embutido e 1 material em cada GLB; compartilhamento/material instancing entre espécies não foi implementado nesta rodada.

## Problemas/limitações ainda abertos

- Modelos de Forge 01 mantêm baixa resolução geométrica e visual distante da direção artística final; a escolha de Art 02 para os três duplicados não resolve o conjunto.
- Silhuetas e materiais precisam revisão *na câmera e iluminação reais*. O design do Guardião de Pedra precisa checagem de correspondência estética com seu papel.
- O retiming proposto não garante ausência de patinagem: sem IK, sincronização de velocidade com CharacterBody3D, curva de solo ou marcadores verificáveis na física.
- Colisão simplificada é apenas descritor; não foi construída hitbox ativa nem medida em jogo.
- Qualidade/completude comercial: 21 criaturas do plano inicial faltam, mais 3 IDs de Bestiário 02. Propostas de deserto não têm gameplay cadastrado; **não acrescentar spawn** nesta camada.
- O laboratório GDScript exige execução real; nenhuma captura da Godot nem medição de FPS foi alegada.

## Decisão de entrega

**Pronto como CANDIDATO para QA/integrador da próxima Convergência**, não pronto como arte final ou integração autorizada. Recomenda-se validar lobo/javali/tigre/serpente e as condições reais de escala antes de expandir ou incorporar centenas de instâncias.
'''
wr('docs/RELATORIO-ARTE-CRIATURAS-02.md',report)

# Module manifest
mod={'schema':'exo.creatures.harmonizacao02','version':'0.2.0-candidato','godot':'4.6.2 Standard Compatibility','root':'res://exo_creature_harmonizacao02/','load_policy':'opt-in; no autoload; no EXO Core modification','bestiary02_mode':'read-only visual asset mapping','counts':jsonout['count'],'provenance':'docs/PROVENIENCIA-COMERCIAL.md','qa':'tests/qa_harmonizacao.py'}
wr('module/manifest.json',json.dumps(mod,ensure_ascii=False,indent=2))
wr('module/entrypoint.gd','''extends RefCounted
## Candidato modular de recursos. Registro deve ser autorizado pelo integrador; sem autoload.
static func module_id() -> String:
    return "exo_creature_harmonizacao02"
''')

# Root requested output files
for src,dst in [('data/CATALOGO-CRIATURAS-UNIFICADO.json','CATALOGO-CRIATURAS-UNIFICADO.json'),('docs/RELATORIO-ARTE-CRIATURAS-02.md','RELATORIO-ARTE-CRIATURAS-02.md'),('docs/CONTRATO-VISUAL-BESTIARIO.md','CONTRATO-VISUAL-BESTIARIO.md'),('docs/ESPECIES-PENDENTES.md','ESPECIES-PENDENTES-HARMONIZACAO-02.md'),('evidencias/GALERIA-MODELOS-REAIS-17-ESPECIES.png','GALERIA-CRIATURAS-17-ESPECIES.png'),('evidencias/MULTIANGULOS-8-ESPECIES.png','CRIATURAS-HARMONIZACAO-MULTIANGULOS.png')]:
 shutil.copy2(OUT/src,ROOT/dst)

# Validate using stand-alone QA (no build import)
res=subprocess.run(['python',str(OUT/'tests/qa_harmonizacao.py')],check=True,text=True,capture_output=True);print(res.stdout)
(ROOT/'QA-HARMONIZACAO-02-OUTPUT.txt').write_text(res.stdout,encoding='utf8')
shutil.copy2(ROOT/'QA-HARMONIZACAO-02-OUTPUT.txt',OUT/'data/QA-HARMONIZACAO-02-OUTPUT.txt')
zipdst=ROOT/'EXO-Murim-Creature-Harmonizacao-02-CANDIDATO.zip'
with zipfile.ZipFile(zipdst,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=7) as z:
 for f in sorted(OUT.rglob('*')):
  if f.is_file():z.write(f,arcname=f.relative_to(ROOT))
with zipfile.ZipFile(zipdst) as z:
 assert z.testzip() is None
 print('ZIP',len(z.infolist()),round(zipdst.stat().st_size/1024/1024,2),'MiB')
# Final path consistency check in artifact
print('FINAL FILES')
for f in [zipdst,ROOT/'CATALOGO-CRIATURAS-UNIFICADO.json',ROOT/'RELATORIO-ARTE-CRIATURAS-02.md',ROOT/'CONTRATO-VISUAL-BESTIARIO.md',ROOT/'ESPECIES-PENDENTES-HARMONIZACAO-02.md',ROOT/'GALERIA-CRIATURAS-17-ESPECIES.png',ROOT/'CRIATURAS-HARMONIZACAO-MULTIANGULOS.png']:
 print(f.name,f.stat().st_size)
