# Contrato obrigatório de módulos EXO — versão 1.0.0

Aplicável à Convergência 02 / EXO Core 01. Godot 4.6.2 Standard Compatibility.

1. Cada módulo entrega ID estável, versão semântica, dependências obrigatórias/opcionais, serviços fornecidos, eventos publicados/consumidos, schemas e entrypoint em manifesto. IDs de módulos/serviços não podem colidir.
2. Dependência exige mesmo major e versão pelo menos igual ao mínimo declarado. Dependências opcionais existentes também devem ser compatíveis. Ciclos são recusados; ordem é determinística. Marcar `optional_module` não torna opcional uma dependência exigida por outro módulo.
3. `initialize(core)` registra serviços, dados e consumidores; retorna bool. Pode consultar `core.services.invoke(...)`. `shutdown()` libera referências. O Core carrega `entrypoint` de módulos novos; não é necessário editar todos os sistemas antigos.
4. IDs oficiais qualificam o ID local já persistido pelo dono. Não criar outro morador para preencher contrato, nem renumerar NPC, loot ou geração de inimigos. Usar `entity_contracts.gd` ao trocar referências externas.
5. Eventos usam `event_contracts.gd`, schema, origem oficial, ID e contexto limitado. Publicar no ponto autoritativo uma única vez. Consumidores não republicam a mesma ação. Retornar false para recusar o lote e não persistir efeitos parciais. Não realizar operações externas irreversíveis dentro de callbacks.
6. Tipos de evento novos exigem contrato, autoria e revisão do Core. Não adicionar nomes livres sem validação. Eventos existentes não mudam de significado sob o mesmo schema. IDs de transação distinguem ações repetíveis; recibos de recompensas distinguem efeitos que só podem acontecer uma vez.
7. Registrar domínio único em `save.save_coordinator.register_domain(key, owner, validator)`. O módulo altera seu domínio no documento; nunca abre outro arquivo de progresso, nem chama a primitiva privada `_commit_legacy`. O coordenador grava a raiz v4 inteira. Contêineres delegados, como convergence.ecology, devem documentar explicitamente dono/validação.
8. Schema novo inclui validador e migração que preserva campos anteriores, backup, falha controlada e teste de reversão. Não rerrolar item/identidade/aparência materializados. Manter v4 até existir justificativa e migração nativa demonstrada.
9. Fornecer testes próprios, testes no projeto completo, casos de eventos repetidos, inventário cheio, falha de escrita, reabertura em processo novo e compatibilidade com a versão mínima do Core. Erro de script invalida PASS mesmo que haja assertivas aprovadas no log.
10. Entregar manifesto de arquivos/hashes, origem dos assets, instruções de reprodução e limitações. Asserções alteradas exigem justificativa; não apagar testes para aprovar. Novos eventos/schemas precisam de documentação.
11. Atualização compatível mantém major; correção sem nova interface é patch; interface aditiva é minor. Mudança incompatível exige major, adaptador/migração e gate de regressão. Runtime não aceita automaticamente qualquer mudança só porque seu número é maior.
12. Aprovação: importação limpa, saúde dos módulos, serviços reais, suítes nativas limpas, fluxo jogável e persistência. FAIL crítico impede status estável. NOT_RUN permanece explícito. Captura conceitual, Python independente e FPS fixo não substituem esses gates.

O template em `exo_core/module_template/` é um projeto executável de contratos, não um segundo jogo. Copiar apenas `example/` e o manifesto adaptado para integrar. Não substituir o Core oficial com a infraestrutura mínima copiada para o harness.
