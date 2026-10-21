# Matriz de integração — EXO Core 01

Comparação por bytes/SHA-256 das quatro linhas completas e inspeção dos patches, relatórios e manifestos. Nenhum ZIP foi aplicado por sobreposição sequencial. Base do trabalho: Núcleo Narrativo 01 em checkout Git próprio. Originais preservados separadamente.

| Módulo/origem | Dependências | Entrada → saída | Arquivos afetados | Dados persistentes | Validação/riscos |
|---|---|---|---|---|---|
| R3 / Mundo Vivo 02 R2 Validação Funcional | Genesis, Living World, IA e combate legados | seed/atlas → região física, população e ecologia | convergence/game.gd, region.gd | world, convergence, ecology | regressão nativa e aceitação; preservar regional_version 5 / Settlement 4 |
| Jornada Dinâmica 01 | R3, inventário, NPCs existentes | região/conversa/morte/coleta → sete tipos de objetivo, XP, atributos, reputação | quest_manager.gd, inventory.gd, journal.gd, character.gd, journey_save.gd | journey_dynamic | suíte 4.053; risco de emissão duplicada resolvido com intake Core |
| Núcleo Narrativo 01 | Jornada | eventos → fatos, memória, influência, rumores, destino e agenda | narrative/*, quest_manager.gd, game.gd, journey_save.gd | narrative | suíte 2.539 + reabertura; cenários lógicos não anunciados como missões físicas |
| Skin 3D Hybrid 01 | R3 em ramo paralelo | perfil/PNG → classic/slim, overlays e acessórios | wardrobe.gd, resident.gd, enemy.gd, people.gd, murim_flow.gd, character_creation.gd, journey_save.gd | character.skin3d / skin_file | suíte renderizada 146 resultados; pivôs/rig/controlador preservados |
| Forja Arquitetônica 03 | Genesis oferece parcelas; modular_kit | lotes/blueprints → casas/pátios e APIs de civis | forja/* V03 aditivo, 163 GLBs, catálogo V03, modular_kit | deriva de seed/parcela; não cria save paralelo | 15.032 testes; novos halls grandes ficam nos laboratórios até haver parcela válida |
| Fortificações 01 → planejador 2 | Genesis e GLBs V03 | lotes/estradas/relevo → anéis externos | fortifications/planner.gd, exo_core/adapters_architecture.gd | plano determinístico reconstruído | 36.029 testes finais; 378 amostras físicas em portões; rios sem solução bloqueiam implantação |
| EXO Core 01 | todos os anteriores por registro | manifests + eventos + serviços → ciclo e persistência coordenados | exo_core/*, game.gd, journey_save.gd | exo_core schema 1 | 20 testes unitários, aceitação/reabertura e falha forçada |

## Diferenças verificadas

R3 → Jornada: 6 arquivos adicionados, 5 modificados, zero removidos; 3.536 idênticos.
Jornada → Narrativa: 20 adicionados, 4 modificados, zero removidos; 3.543 idênticos.
R3 → Skin: 13 adicionados, 7 modificados, zero removidos; 3.534 idênticos.
Conflito paralelo real: `journey_save.gd`. A alteração Skin era a validação do campo cosmético opcional; foi acrescentada ao arquivo da Narrativa, preservando validadores e extensão de atributos da Jornada.

O patch Jornada inclui manifesto externo que não está no ZIP completo; os bytes de código foram comparados com o completo. O mesmo procedimento se aplica aos demais patches; diferenças documentais não autorizam substituir um projeto integral.

## Defeitos de origem reproduzidos

- Narrativa não compilava por duas inferências de tipo; corrigidas para String.
- Estado narrativo inicial criava rumores como Dictionary, embora o próprio schema exija Array; corrigido e suíte reexecutada.
- Skin: declaração `z: float` sem `var`; corrigida após parser nativo.
- Skin: versão cosmética após JSON era float; normalização preserva semântica inteira e igualdade de perfil.
- Captura Skin: amostragem muito esparsa rejeitava uma imagem não vazia; amostragem passou a ser densa, com ambiente iluminado explícito e espera de frame desenhado. Não foi removido o teste de imagem não vazia.
- Teste multi-seed legado removia só Living World ao trocar artificialmente a seed no mesmo save. Agora limpa todas as extensões vinculadas àquele mundo de teste; não é migração de dados do jogador.
- Reservas de portão chanfrado suprimiam pequenos trechos sem convertê-los em abertura. Reserva ampliada e versão do planejador incrementada; todas as condições geométricas continuaram ativas.
