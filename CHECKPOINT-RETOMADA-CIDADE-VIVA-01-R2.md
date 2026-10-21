# Retomada exata — Cidade Viva 01 R2 (candidato)

Estado preservado em 19/10/2026. Não declarar aprovação definitiva.

1. Extraia o ZIP completo e abra project.godot na Godot 4.6.2 Standard, Compatibility. A importação de recursos pode ser refeita; a pasta .godot não é necessária ao checkpoint.
2. Leia RELATORIO-CIDADE-VIVA-01-R2.md e CIDADE-VIVA-VERSION.json. O manifesto contém SHA-256 da base, dos arquivos alterados/adicionados e dos arquivos protegidos.
3. Os resultados finais estão em cidade_viva/validation/summary.json (23 suítes PASS), rendered-summary.json (captura e benchmark PASS) e RESULTADOS-CIDADE-VIVA-01-R2.json. Os scripts GDScript e comandos exatos acompanham o projeto.
4. Capturas reais: cidade_viva/evidence, 12 PNGs com câmeras e parâmetros em captures.json. Logs anteriores/interrompidos em cidade_viva/validation/history; não confundir com resultados finais.
5. Rotinas: 65 moradores, ciclo completo isolado a 5 Hz após assentamento a 60 Hz e reabertura em processo separado. Não repetir por simples retomada; repetir os testes afetados se o código mudar.
6. A base é o candidato EXO Visual 01, com Core corrigido e Fortificações 02 R2. A integração urbana é ativada em convergence/region.gd; versão urbana 2, regional 6, assentamento 4 e raiz de save 4. Nenhum pacote paralelo posterior foi aplicado.
7. Próximas decisões: revisão humana da composição/densidade frente à referência; validação prolongada de todos os sistemas a 60 Hz; benchmark em hardware real; auditoria de licenças. Não há aprovação definitiva desses pontos.

Incluídos: scripts de execução desta rodada em cidade_viva/validation/checkpoint-tools. O executável da Godot e dependências temporárias do host não são assets do projeto e não acompanham o ZIP; a versão exata está registrada.
