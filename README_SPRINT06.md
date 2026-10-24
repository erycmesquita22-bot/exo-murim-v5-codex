# EXO HANEUL V1.0 — SPRINT 6: INTERIORES MURIM

**Base real:** V0.9 integral do Sprint 5. Godot **4.7.2 Compatibility**. Não mesclar diretórios ou arquivos com versões antigas.

## Pronto para testar

1. Extrair o ZIP integral em uma pasta nova.
2. Abrir `project.godot` na Godot 4.7.2 e pressionar F5.
3. Aproximar-se de uma das 15 portas da Vila de Haneul até aparecer o indicador.
4. Pressionar **F** para entrar; dentro do cômodo, chegar à entrada e pressionar **F** para retornar.
5. **E** continua sacando/guardando a arma. WASD, Shift, Q etc. permanecem no Character Core V3.

### Tipos dos interiores

- **Solar:** salão de recepção com tatame, biombos, pinturas de montanhas e estandartes variáveis; ala de treino com suportes de armas; ala de biblioteca com estantes e pergaminhos.
- **Casa de chá:** mesas baixas, almofadas, serviço e lanternas.
- **Clínica:** balcão, ervas, potes e prateleiras.
- **Hospedaria:** balcão e mesas de descanso.
- **Armazém/loja:** balcão, prateleiras e fardos.
- **Casas familiares, pescadores e fazenda:** camas, cestos, utensílios e decoração proporcional às condições sociais.

A mesma arquitetura exterior do solar é compartilhada por Wong e Wudong. Somente os banners mudam; não há reconfiguração procedural dos edifícios.

### Arquitetura técnica

- Cada portal exterior usa **a mesma ID estável definida em S05**.
- O script `godot/S06_Haneul_InteriorController.gd` estende S05, que por sua vez herda do controlador V3. Nenhum script do personagem foi sobrescrito.
- Cada cômodo é uma cena independente em `godot/interiors/<id>.tscn`; o GLB próprio fica em `interiors_sprint06/models/`.
- A instância interna é carregada em espaço remoto do mesmo `World3D` para simular uma área independente, sem carregar outro mapa; exterior oculto visualmente e mantido na memória. **Não é uma dimensão Godot independente.**
- Paredes e piso têm colisão real; mobiliário sólido selecionado também.
- Para preservar a câmera terceira pessoa, o teto dos interiores é propositalmente aberto, com vigas no perímetro. O **telhado exterior permanece intacto**.
- O painel de transição escurece a tela por frações de segundo; a posição do jogador é restaurada no exterior.

## Testes

- Godot 4.7.2: importação real, 30 transições programáticas (15 × 2 famílias), física do piso verificada com raios, 2 fluxos reais de tecla F para entrar/sair, Character Core V3 com 25 ossos e 15 animações preservado.
- Capturas gráficas reais na engine em `interiors_sprint06/previews/`.
- Teste manual de todas as portas e inspeção visual final pelo usuário **PENDENTE**.

**Limitações conhecidas:** telas interiores usam um stage remoto (não uma instância de mundo totalmente separada); NPCs e rotinas comerciais ainda ausentes; portas exteriores não têm animação; sem persistência de estado dos móveis; sem prova de travessia manual de todos os cômodos; avisos não bloqueantes de `AnimationTree` herdados do controlador V3. Não foram adicionados shaders/clima dos outros módulos.

## Direitos comerciais

Geometria, pinturas e símbolos interiores S06 foram produzidos como código e texturas originais neste pacote, sem arquivos de mods/obras externas. A originalidade comercial deve ser revisada antes de lançamento.
