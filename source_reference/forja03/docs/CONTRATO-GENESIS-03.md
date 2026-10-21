# EXO Forja 03 ↔ World Genesis — Contrato aditivo

A Forja **não gera** o grafo de 88 regiões, estradas, seeds regionais, terreno ou lotes. Genesis fornece **centro global, terreno regularizado, extensão, orientação, via conectada e IDs persistentes**. A Forja fornece um plano tipado validado antes da criação de nós 3D. O contrato de casas da Forja 02 (`forja/forja_planner.gd`, schema=2) permanece intacto.

## Tipos de novos sites

- `civic` → `Civic.plan_civic(seed,parcel)` + `CivicBuilder.build(parent,plan)`; papéis `sect_hall`, `temple`, `guild_hall`, `martial_school`, `granary`, `farmstead`.
- `fort` → `Fort.plan_fort(seed,parcel)` + `FortBuilder.build(parent,plan)`; estilos `stone`, `wood`, `battlement`, `auto`, torre nos quatro cantos por padrão.
- `compound` → `Compound.plan_compound(seed,parcel)` + `Compound.build_compound(parent,planned)`; mesmo terreno reservado para muralha e prédio principal, como clã murado.
- `green` → `Green.plan(seed,parcel)` + `Green.build(parent,{"ok":true,"plan":plan})`; faixa de árvores e bambus com passagem central livre.

## API recomendada: loteamento atômico

```gdscript
const Adapter = preload("res://forja/genesis_adapter_v3.gd")
var batch: Dictionary = Adapter.plan_sites(world_seed, approved_site_requests)
if batch.ok:
    var result: Dictionary = Adapter.build_sites(structures_root, batch)
```

Cada item de `approved_site_requests` é `{"kind":"civic|fort|compound|green", "parcel":{...}}`. Admite até 32 sites por chamada, rejeitando IDs repetidos, colisões AABB conservadoras entre **parcelas diferentes** e qualquer site inválido. Replaneja os blueprints completos antes de instanciar, rejeitando adulterações de localização e papel. Se houver falha de montagem, desfaz os nós criados naquele batch; não desfaz outros batches anteriores. Não substitui a verificação do Genesis contra rios, ruas, lotes fora deste batch e encostas.

Campos comuns: `id` (único e estável), `center_x`, `center_z`, `ground_y`, `width_m`, `depth_m`, `yaw_quadrants` (0..3), `terrain_samples_y` (exatamente 4 alturas cuja diferença para `ground_y` seja <=0,18m). **Civic/fort/compound** exigem `approach_clear=true`, que é uma declaração comprovada pelo chamador, e **green** exige `road_clear=true`. As quatro amostras **não demonstram** que o miolo do terreno é plano: a malha do Genesis também precisa passar na auditoria de nivelamento.

| Tipo | Papel | Largura mínima (m) | Profundidade mínima (m) |
|---|---|---:|---:|
| Civic | Clã / templo / guilda / escola | 24 | 26 |
| Civic | Celeiro | 20 | 24 |
| Civic | Fazenda | 26 | 30 |
| Fortificação retangular plana | Todos | 24 (par, <=100) | 24 (par, <=100) |
| Faixa verde | Todos | 16 | 16 |

**Geometria e saídas:** metros, Y positivo para cima, frente local +Z; orientações em quartos de volta. Fort mantém borda de segurança de 2m dentro da parcela, 3 células de 2m reservadas na frente para o portão, ao menos 4m livres entre pilares, `AnchorGate`, `AnchorApproach`, `AnchorInside`. Civis têm `AnchorEntrance`, `AnchorApproach`, `AnchorNPC`, `AnchorActivity`; AnchorNPC é uma posição inicial, não um agente IA. Faixa verde preserva corredor longitudinal |x| <=2,5m com reserva adicional de copa.

## Limites que a integração não deve ocultar

1. **Muralha de cidade grande em relevo** não está pronta. A implementação aqui é um cercado **retangular plano** para pequenas fortificações, pátios de clã e laboratórios. Para cercar uma cidade irregular, o Genesis precisará fornecer um perímetro amostrado com alturas e portões coerentes com as estradas; isto exige outro adaptador e testes.
2. Hall/templos são fachadas/estruturas 3D com aberturas e colisores simplificados, **não interiores funcionais e nem missões prontas**. Torres são volumes fechados, sem escadas internas.
3. As rotas e entradas têm verificação geométrica conservadora, não provas de **NavMesh nem navegação de NPCs**. É proibido afirmar que estão navegáveis até o Work testar agentes reais.
4. GLBs no catálogo de V03 têm `collision="none"` intencionalmente: os builders criam formas físicas simplificadas para paredes/objetos. Não duplicar trimesh collision nestes elementos.
5. Preservar `schema_version=2` para casas V02; os novos tipos usam schema3. Persistência e migração devem salvar `parcel`, tipo, seed e IDs, e replanejar ao carregar quando a versão de blueprint mudar.
