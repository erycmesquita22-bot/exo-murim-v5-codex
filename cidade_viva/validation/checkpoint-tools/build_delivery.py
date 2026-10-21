from pathlib import Path
import json,zipfile,hashlib,shutil,re,datetime
base=Path('/workspace/scratch/19f3e29d2e70')
root=base/'project/EXO-Murim-EXO-Visual-01'
out=base/'deliverables';out.mkdir(exist_ok=True)
history=root/'cidade_viva/validation/history';history.mkdir(exist_ok=True)
for name in [p.name for p in (base/'qa').iterdir() if p.is_file()]:
 if (base/'qa'/name).exists():shutil.copy2(base/'qa'/name,history/('historical-'+name))
partial=root/'cidade_viva/validation/validation_r3_npc_day.log'
if partial.exists():shutil.move(partial,history/'incomplete-original-day-60hz.log')
rows=json.loads((root/'cidade_viva/validation/summary.json').read_text())
assert all(r['status']=='PASS' for r in rows),[(r['script'],r['status']) for r in rows if r['status']!='PASS']
def result(name):return json.loads((root/'validation_r3/results'/f'{name}.json').read_text())
floor=result('cidade_viva_flat_floor');live=result('cidade_viva_live');day=result('npc_day');reopen=result('npc_reopen');bench=result('cidade_viva_benchmark')
captures=json.loads((root/'cidade_viva/evidence/captures.json').read_text())
assert len(captures)==12
assert not live['failures'] and not day['failures'] and not reopen['failures'] and not bench['failures']
facts=live['facts'];urban=facts['urban'];budget=urban['metrics']['max_visuals']
rendered=json.loads((root/'cidade_viva/validation/rendered-summary.json').read_text())
assert all(r['status']=='PASS' for r in rendered)
summary={'status':'CANDIDATO_CHECKPOINT','rendered_runs':rendered,'engine':'4.6.2.stable.official.71f334935','renderer':'gl_compatibility','native_suites':rows,'planner_cases':92,'flat_floor':floor,'live_city':live,'npc_day':day,'reopen':reopen,'captures':captures,'render_benchmark':bench,'limits':['Automated input is not human gameplay.','Frozen render benchmark on CPU llvmpipe is not live gameplay FPS or owner hardware.','Street layout preserved; new props do not implement shops, harvesting or new interiors.']}
(root/'cidade_viva/validation/RESULTADOS-CIDADE-VIVA-01-R2.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2))
report=f'''# EXO-MURIM — CIDADE VIVA 01 R2

Data: 19/10/2026. Engine: Godot 4.6.2 Standard, Compatibility.

**Estado: CANDIDATO DE CHECKPOINT — sem aprovação definitiva.** Integração executada e verificada automaticamente na Godot. Revisão artística e caminhada humana no computador do proprietário continuam pendentes. Nenhum novo sistema ou teste demorado foi iniciado para este checkpoint.

## Entrega e base

Projeto completo baseado em EXO-Murim-EXO-Visual-01-CANDIDATO.zip, que já contém EXO Core 01 corrigido e Fortificações 02 R2. Aplicado Cidade Viva 01 e realizado o polimento R2. A cena principal continua convergence/game.tscn; não é necessário combinar os pacotes manualmente.

Os documentos antigos no projeto são históricos. Este relatório, cidade_viva/validation/RESULTADOS-CIDADE-VIVA-01-R2.json e os logs desta rodada descrevem a entrega atual.

## Mudanças reais

- Corrigida a leitura do polígono das muralhas. O teste inicial recusava a camada urbana das 16 cidades examinadas; o planejador agora aceita tanto o contrato direto da fortificação quanto o relatório do adaptador central.
- Raios calculados a partir dos bounds reais do catálogo. Reservados os retângulos das edificações, pátios ampliados, estações de fachada dos moradores, acessos, vias e margens de rios/muralhas.
- Tentativas locais por seed e lote, densidade por função, anexos comerciais/marciais e agrupamentos junto às ruas de mercado. Tetos: aldeia 24, vila 86 e cidade 180 objetos adicionais. Um teto não é uma obrigação de preencher espaço inseguro.
- Jardins, hortas, pomares, bambus, pavilhões e anexos do santuário usam os modelos existentes. A grama aprovada é aplicada em pequenas malhas conformadas à altura real do solo; os arquivos de textura originais foram preservados.
- Interação por E prioriza o morador visível mais próximo, alinhando seleção e aproximação em grupos.
- Iluminação urbana acompanha o relógio persistido do EXO. Limites de 2/5/12 luzes locais para aldeia/vila/cidade; lanternas sem sombras dinâmicas.
- Colisão dos objetos usa bounds reais. Árvores colidem pelo tronco; pavilhões têm colisão nos pilares e espaço central livre. Cultivo baixo permite passagem.
- Colisão de terreno: trechos estritamente planos usam BoxShape3D com a mesma superfície superior; relevo e canais não planos mantêm os triângulos originais. Na cidade 78, foram simplificados {floor['facts']['flat_collision_chunks']} trechos, com {floor['facts']['floor_samples']} amostras de altura aprovadas, inclusive nas emendas, sob tolerância de 1 mm. A malha renderizada e o algoritmo de geração não foram alterados.
- Geometria estática agrupada por material e material de jardim compartilhado. Reaplicar a camada não duplica objetos, moradores ou estado de save.
- Corrigidos problemas herdados do EXO Visual: chamada de API do renderizador inexistente na versão alvo, indentação inválida na página de configurações e acesso fora do array na prévia do personagem ao selecionar os novos perfis.

## Cidade de referência executada

Seed 101, região 78: **43 construções originais, {facts['npcs']} moradores e {urban['objects']} objetos urbanos adicionais**, com {urban['night_lamps']} lanternas locais. O teto configurado é {budget}. Não foram criadas identidades de NPCs para inflar artificialmente a população.

A camada anterior do Cidade Viva colocava 60 objetos nessa cidade após corrigir a leitura da muralha. O R2 aumenta a ocupação com vegetação produtiva e instalações contextuais. As imagens 01/02 usam a mesma câmera e cidade, com a camada urbana desligada/ligada.

## Verificação executada

- **{len(rows)} suítes nativas passaram**, sem SCRIPT ERROR, ERROR ou asserção FAIL nos logs finais. Incluem as 13 suítes legadas obrigatórias, Core, extensão de módulos, fortificações fluviais, EXO Visual, planejador urbano, circulação/colisão, portões, ciclo de NPCs e reabertura.
- Planejador GDScript: 92 assentamentos com planos válidos, em quatro seeds (101, 816204, 707 e 18026). Determinismo, não mutação dos lotes originais, limite e reservas de ocupação.
- Circulação: {facts['physics_samples']} amostras físicas de cápsula ao longo de {facts['unique_route_points']} pontos únicos das rotas existentes; nenhum novo objeto sólido bloqueando os trajetos. Controle positivo detectou um colisor urbano real. Reaplicação manteve uma única camada e save idêntico.
- Rotinas: ciclo completo de um dia do relógio do jogo, em fixture acelerada a 5 Hz (passos de 0,2 s), após assentamento inicial a 60 Hz, movimento físico, deslocamentos, trabalho, convivência, descanso, interrupção por conversa e retomada. Resultados completos, inclusive profissões, constam do JSON. Sem simulação de tempo offline. O jogo normal permanece a 60 Hz; este é um teste de estresse contínuo das agendas, não uma sessão de gameplay a 60 Hz. A tentativa integral a 60 Hz foi interrompida pelo custo no host. Na fixture isolada, subárvores visuais dos moradores ficam destacadas, e atualizações do jogador/ecologia ficam suspensas; cada morador executa seu método step real, com locomoção física e colisões. Não é um teste de um dia inteiro de todos os sistemas simultaneamente.
- Persistência: outro processo Godot reabriu a cidade e verificou identidades, vínculos, população, conversas, trabalho e visitas. Sem duplicar os 65 moradores.
- Portões: testes físicos de passagem e apoio no chão. Fortificação fluvial: 52 verificações nativas, incluindo variantes pequena, média e monumental, e cidades reais com rio.
- Gráficos: abertura da página de configurações nos cinco presets e em Personalizado, preferências independentes, fallback de valores inválidos, materiais e preservação do estado de gameplay durante a troca.
- 12 capturas novas do viewport Godot, com seed, região e transformações da câmera registradas. Incluem cidade, serviços, moradias, noite e passagem fluvial.

Erros e tentativas anteriores foram preservados como histórico, identificados por before-fix. Não são apresentados como resultados aprovados. Um teste antigo foi atualizado para o índice atual do perfil Alto. A fixture gráfica suspende o relógio durante a comparação de saves; a fixture headless retira o limite de exibição para executar os mesmos passos físicos sem esperar o tempo de uma sessão humana.

## Desempenho e limites

O arquivo cidade_viva_benchmark.json registra amostras brutas, P95, memória e draw calls, com composição urbana desligada/ligada no mesmo processo gráfico. O benchmark não usa FPS fixo. A simulação fica congelada para isolar o custo de renderização; o host usa llvmpipe por CPU. Esses números **não representam FPS de gameplay, GPU real ou desempenho no computador do proprietário**.

As ruas, posições das casas e o perímetro não foram redesenhados. A cidade ganhou composição e ocupação, mas ainda conserva o traçado amplo anterior; não é uma reprodução exata dos quarteirões e grandes complexos da imagem conceitual. Bancas, cultivo e anexos novos não implementam outra economia, colheita ou interiores. Os moradores continuam usando as rotinas e serviços já existentes do Living World.

Não houve teste humano, cooperativo, Android ou Forward+. Compatibility foi mantido.

## Pendências e problemas ainda não resolvidos

- Aprovação humana da arte, densidade e experiência murim: o traçado amplo e as pequenas casas da base ainda diferem da referência conceitual. Uma reformulação dos quarteirões não foi executada.
- Dia completo com todos os sistemas simultâneos a 60 Hz e sessão prolongada de gameplay: pendentes. A aprovação das agendas vem da fixture isolada descrita acima.
- Benchmark em GPU real, com câmera e simulação ativas: pendente. O ensaio disponível isola renderização em CPU llvmpipe.
- Android, Forward+ e cooperativo: não testados nesta rodada.
- Bancas e cultivos adicionais são ambientais; economia, colheita e interiores novos não foram implementados.
- Auditoria documental de procedência e direitos comerciais dos assets da base: pendente. Os binários originais foram preservados; isso não equivale a uma certificação de licença.
- Outros pacotes paralelos de HUD, mestres, itens, dungeons e bestiário não compõem este checkpoint. A base utilizada é exclusivamente a identificada neste relatório e por SHA-256 no manifesto.

## Falhas encontradas e tratamento

As recusas iniciais das cidades por polígono de muralha, os erros herdados de API/configuração gráfica e os bounds de colisão foram corrigidos conforme a lista de mudanças. O índice legado do perfil Alto foi atualizado no teste. No ensaio acelerado de NPCs, a inicialização grosseira a 5 Hz deixava cinco moradores sem apoio correto; a fixture foi corrigida para assentar os corpos a 60 Hz antes do estresse. A fixture de conversa passou a apoiar o jogador no solo real antes da interação. As tentativas interrompidas e os logs anteriores estão preservados como histórico, sem serem contados como aprovação final. A suíte final aprovou os 65 moradores.

## Abrir e reproduzir

Extraia o projeto completo, importe project.godot na Godot 4.6.2 e aguarde a importação. F5 inicia o jogo. Cidade Viva aparece nas regiões externas de assentamento; o recinto inicial legado continua separado.

Para as capturas: seed 101, cidade 78; cidades com rio 14 e 26. P abre a central, Tab abre o mapa, E interage, R alterna arma/mãos livres e F executa esquiva.

```sh
python3 cidade_viva/tests/run_validation.py /caminho/para/Godot
Godot --path . --script cidade_viva/tests/capture_live.gd
Godot --path . --script cidade_viva/tests/benchmark_urban.gd
```

Capturas podem usar FPS fixo para reprodução. O benchmark deve ser executado sem esse parâmetro, sozinho, sem suítes concorrentes.
'''
report_name='RELATORIO-CIDADE-VIVA-01-R2.md'
(root/report_name).write_text(report)
shutil.copy2(root/report_name,out/report_name)
old_readme=root/'cidade_viva/docs/LEIA-ME-BASE-09.2.txt';old_readme.parent.mkdir(exist_ok=True)
if not old_readme.exists():shutil.copy2(root/'LEIA-ME.txt',old_readme)
(root/'LEIA-ME.txt').write_text('EXO-MURIM — CIDADE VIVA 01 R2\n\nGodot 4.6.2 Standard, Compatibility.\nExtraia todo o projeto, importe project.godot, aguarde a importação e pressione F5.\n\nBase unificada: EXO Core 01 corrigido + Fortificações 02 R2 + EXO Visual 01 + Cidade Viva 01 R2.\n\nA camada urbana aparece nos assentamentos das 88 regiões externas. O recinto inicial é separado.\nReferência de teste: seed 101, cidade 78; cidades fluviais 14 e 26.\nP: central; Tab: mapa; E: interação; R: arma/mãos livres; F: esquiva.\n\nRelatório atual: RELATORIO-CIDADE-VIVA-01-R2.md.\nEvidências novas: cidade_viva/evidence.\nQA atual: cidade_viva/validation.\nNão confundir relatórios e imagens históricos com esta rodada.\n\nO projeto preserva o diretório de saves. Para comparar versões, guarde cópia do seu save antes de alternar.\nBancas/cultivo novos são ambientação; as rotinas de moradores existentes foram preservadas.\n')
(root/'CIDADE-VIVA-VERSION.json').write_text(json.dumps({'status':'CANDIDATO_CHECKPOINT','release':'Cidade Viva 01 R2','engine':'4.6.2 Standard','renderer':'gl_compatibility','urban_version':2,'regional_version':6,'settlement_version':4,'save_root':4,'base':'EXO Visual 01 + Core 01 corrigido + Fortificacoes 02 R2'},indent=2))
resume='''# Retomada exata — Cidade Viva 01 R2 (candidato)

Estado preservado em 19/10/2026. Não declarar aprovação definitiva.

1. Extraia o ZIP completo e abra project.godot na Godot 4.6.2 Standard, Compatibility. A importação de recursos pode ser refeita; a pasta .godot não é necessária ao checkpoint.
2. Leia RELATORIO-CIDADE-VIVA-01-R2.md e CIDADE-VIVA-VERSION.json. O manifesto contém SHA-256 da base, dos arquivos alterados/adicionados e dos arquivos protegidos.
3. Os resultados finais estão em cidade_viva/validation/summary.json (23 suítes PASS), rendered-summary.json (captura e benchmark PASS) e RESULTADOS-CIDADE-VIVA-01-R2.json. Os scripts GDScript e comandos exatos acompanham o projeto.
4. Capturas reais: cidade_viva/evidence, 12 PNGs com câmeras e parâmetros em captures.json. Logs anteriores/interrompidos em cidade_viva/validation/history; não confundir com resultados finais.
5. Rotinas: 65 moradores, ciclo completo isolado a 5 Hz após assentamento a 60 Hz e reabertura em processo separado. Não repetir por simples retomada; repetir os testes afetados se o código mudar.
6. A base é o candidato EXO Visual 01, com Core corrigido e Fortificações 02 R2. A integração urbana é ativada em convergence/region.gd; versão urbana 2, regional 6, assentamento 4 e raiz de save 4. Nenhum pacote paralelo posterior foi aplicado.
7. Próximas decisões: revisão humana da composição/densidade frente à referência; validação prolongada de todos os sistemas a 60 Hz; benchmark em hardware real; auditoria de licenças. Não há aprovação definitiva desses pontos.

Incluídos: scripts de execução desta rodada em cidade_viva/validation/checkpoint-tools. O executável da Godot e dependências temporárias do host não são assets do projeto e não acompanham o ZIP; a versão exata está registrada.
'''
resume_name='CHECKPOINT-RETOMADA-CIDADE-VIVA-01-R2.md'
(root/resume_name).write_text(resume)
shutil.copy2(root/resume_name,out/resume_name)
checkpoint_tools=root/'cidade_viva/validation/checkpoint-tools';checkpoint_tools.mkdir(exist_ok=True)
for name in ['run_render_checks.py','build_delivery.py','polish.py']:
 if (base/name).exists():shutil.copy2(base/name,checkpoint_tools/name)
source_zip=zipfile.ZipFile(base/'inputs/EXO-Murim-EXO-Visual-01-CANDIDATO.zip')
original={Path(n).relative_to('EXO-Murim-EXO-Visual-01').as_posix():n for n in source_zip.namelist() if not n.endswith('/')}
protected=['main.gd','rig.gd','arsenal.gd','inventory.gd','journey_save.gd','combat/player_combat.gd','genesis/region_data.gd','convergence/occupancy.gd','convergence/resident.gd','convergence/streets.gd','exo_core/modules.json']
manifest={'base_archive':'EXO-Murim-EXO-Visual-01-CANDIDATO.zip','base_sha256':hashlib.sha256((base/'inputs/EXO-Murim-EXO-Visual-01-CANDIDATO.zip').read_bytes()).hexdigest(),'changed':{},'added':{},'protected_unchanged':{},'binary_assets_unchanged':0,'missing':[]}
changed=[];all_files=[]
for p in sorted(root.rglob('*')):
 if not p.is_file() or '.godot' in p.parts or '__pycache__' in p.parts or p.name=='MANIFESTO-CIDADE-VIVA-01-R2.json':continue
 rel=p.relative_to(root).as_posix();all_files.append((p,rel));b=p.read_bytes();digest=hashlib.sha256(b).hexdigest()
 if rel in original:
  old=source_zip.read(original[rel]);same=old==b
  if rel in protected:
   assert same,rel;manifest['protected_unchanged'][rel]=digest
  if p.suffix.lower() in ['.png','.glb','.ogg','.ttf','.wav']:
   assert same,'Unexpected binary asset change: '+rel
   manifest['binary_assets_unchanged']+=1
  if not same:manifest['changed'][rel]={'before':hashlib.sha256(old).hexdigest(),'after':digest};changed.append((p,rel))
 else:manifest['added'][rel]=digest;changed.append((p,rel))
for rel in original:
 if not (root/rel).exists():manifest['missing'].append(rel)
assert not manifest['missing']
manifest_path=root/'MANIFESTO-CIDADE-VIVA-01-R2.json';manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
all_files.append((manifest_path,manifest_path.name));changed.append((manifest_path,manifest_path.name))
def archive(name,files,prefix=''):
 path=out/name
 with zipfile.ZipFile(path,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p,rel in files:z.write(p,prefix+rel)
 with zipfile.ZipFile(path) as z:assert z.testzip() is None
 return path
archive('EXO-Murim-Cidade-Viva-01-R2-PROJETO.zip',all_files,'EXO-Murim-Cidade-Viva-01-R2/')
archive('EXO-Murim-Cidade-Viva-01-R2-PATCH.zip',changed)
evidence=[(p,rel) for p,rel in all_files if rel.startswith('cidade_viva/evidence/') or rel.startswith('cidade_viva/validation/') or rel.startswith('validation_r3/results/') or rel in [report_name,resume_name,manifest_path.name,'CIDADE-VIVA-VERSION.json']]
archive('EVIDENCIAS-CIDADE-VIVA-01-R2.zip',evidence)
shutil.copy2(root/'cidade_viva/evidence/02-cidade-integrada.png',out/'EXO-Murim-Cidade-Viva-01-R2.png')
print(json.dumps({'files':[{'path':str(p),'bytes':p.stat().st_size} for p in out.iterdir()],'native_suites':len(rows),'objects':urban['objects'],'lamps':urban['night_lamps'],'protected_binary_assets':manifest['binary_assets_unchanged'],'changed_files':len(changed)},ensure_ascii=False))
