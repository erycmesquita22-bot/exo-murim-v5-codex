# R10 — Contrato classic/slim e texturas

- Skin3D original permanece com seu codec, `UV.build_box` e `layer_material` (transparência alpha scissor), sem alteração de UVs, materiais base ou rig oficial.
- `HumanoidesR2.apply()` lê o campo efetivo `skin3d_cosmetics.model` e ajusta largura volumétrica das mangas para classic ou slim, sem mudar a malha UV do corpo. A skin do usuário 64x64 importada literalmente por `user://exo_skins/` é respeitada e excluída da sobreposição automática R2.
- As texturas EXO 256×256 geradas pelo Wardrobe oficial permanecem; nenhuma textura nova de terceiros entrou na R10.
- Verificações offline passaram na presença dos contratos. **Godot visual 64×64 classic/slim, transparências, joelhos, clipping de cuffs e reaplicação de arma = NOT_RUN**.
