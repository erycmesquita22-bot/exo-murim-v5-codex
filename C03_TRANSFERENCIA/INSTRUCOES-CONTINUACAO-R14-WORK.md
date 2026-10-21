# EXO-MURIM — Convergência 03 Alfa R14: continuação sem restart

**Base exclusiva:** `EXO-MURIM-CONVERGENCIA-03-ALFA-R13.zip` (usar SHA-256 fornecido no TXT externo). Preservar ZIP R12 e todos os saves. **Não** reconstruir merge desde R11, nem criar Convergência 04.

## Primeiro passo obrigatório
1. Extrair cópia integral com `project.godot` na raiz, instalar Godot **4.6.2 Standard Compatibility** e executar `C03_TRANSFERENCIA/QA-R13-RODAR-WINDOWS.ps1` com `-GodotExe`.
2. Corrigir as causas-raiz reais dos logs de parser/import e repetir até boot válido. Guardar logs brutos e capturas do Godot; exit code zero sozinho não homologa.
3. Validar no editor F5: menu → criação de personagem → campanha procedural → região, movimento/câmera/colisões, salvar/reabrir e viajar.
4. Reexecutar Core Persistence, NPCs, fauna R4/R5, Dungeon/Itens R6, Monumental/Interiores R7, Mestre/Jade R8/R9, Humanoides R10, Terrain Forge R11.
5. Seeds 101,816204,707,18026; regiões 14,26,78; medir FPS apenas no Ryzen 3200GE/Vega8 real.

## O que R13 mudou
- Isolamento R13 user data (R12 estava usando namespace R11 indevidamente).
- `change_region` retorna falha real se JourneySave recusar a gravação, sem falsa confirmação de campanha.
- Novo smoke de bootstrap nativo, runner Windows e auditoria estática. Não promete correção de parser não executado.

Se a Godot ainda estiver indisponível, **nunca declarar jogo compilado ou jogável**. Preservar o último checkpoint completo.
