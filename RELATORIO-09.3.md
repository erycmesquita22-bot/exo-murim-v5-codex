# EXO-Murim 09.3 — Entrega de código (não validada na Godot)

## Base
Partiu do ZIP 09.2. A origem é preservada no ZIP anterior; este pacote é uma cópia modificada. Não contém novos terrenos, biomas ou coop.

## Implementado nos arquivos
- `rig.gd`: corpo Minecraft de skin 64×64 com antebraços e canelas como nós filhos; cotovelos/joelhos articulam na locomoção, meditação, combate e rolagem. Os braços/pernas retornam alinhados quando não há flexão.
- `wardrobe.gd`: base quadrada da cabeça e tronco agora visível; rosto e roupa inicial desenhados na skin; cabelos, saias e acessórios preservados de maneira opcional; botas e punhos no segmento móvel. Suporte a PNG 64×64 importado, sem sobrepor roupas 3D no corpo personalizado.
- `ui/character_creation.gd`, `pause_ui.gd`, `journey_save.gd`: criação com aparência inicial sorteada, escolhas manuais, importação de PNG 64×64 copiado em `user://exo_skins`, e preservação da referência no perfil salvo. Imports que não são 64×64 são rejeitados. Essa importação usa seleção de arquivos do SO; mobile não foi validado.
- Modelo Wizard e a cena externa foram retirados junto ao controlador e suas texturas exclusivas. Não há fallback para esse modelo. Saves antigos têm ignorados os campos de aparência descontinuada, sem migração destrutiva.
- `arsenal.gd` e `combat/martial_motion.gd`: armas equipadas sob o antebraço; controles de visibilidade exclusivos; bainha presa ao pivô corporal para acompanhar rolagem; adaga sem bainha gigante, separação do kit de manoplas. Movimentos base com flexão de antebraços para armas pesadas.
- `murim_flow.gd`: marcadores físicos de patrulha e círculo artificial das ruínas retirados; detecção das coordenadas e progresso mantidos. Retirado o som de aterrissagem de pontos de patrulha.
- `audio/skill_registry.json`, `audio/events.json`, `techniques.gd`: fase de vento do Salto Impetuoso com `wind_break.ogg` do EXO Visual já presente; cast e impacto originais preservados.
- `quality09_qa.gd`, `martial_qa.gd`: referências obrigatórias a esqueleto/modelo externo substituídas por verificações do corpo articulado; `qa093.gd` acrescenta smoke test estrutural.

## Validação real
- **Realizado:** verificação de presença de arquivos, auditoria de referências a recursos removidos, testes de integridade do ZIP, JSON e comparativo de arquivos.
- **Não realizado:** execução de Godot (editor/binário indisponível), importação de assets na engine, teste humano, FPS real, verificação de todos os quadros de animação e importação Android. Não declarar o jogo visualmente aprovado antes desses testes.
- **Observação:** movimentos com armas muito grandes receberam ajustes iniciais de articulação, mas não estão validados como animações finais de estúdio. Corrigir eventuais interseções observadas nos testes, sem alterar o inventário ou a progressão.

## Como testar
1. Extraia a pasta e abra `project.godot` no Godot 4.6.x.
2. Faça uma cópia do save antes de testar.
3. Execute o teste de fumaça pelo terminal: `godot --headless --path . --script res://qa093.gd`.
4. Abra a criação de personagem: teste aparência aleatória, escolha livre e importação de PNG 64×64.
5. Teste espada, espadão, adaga e manoplas: girar, correr, rolar e alternar itens. Teste meditação, missão de patrulha e Salto Impetuoso.
6. Caso algo falhe, envie primeiro o log/erro e a captura. Não sobrescreva sua versão de referência 09.2.
