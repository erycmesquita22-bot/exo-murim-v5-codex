# EXO-Murim — base de personalização 01

Cinco residentes HWA-02 agora usam perfis diferentes de rosto, cabelo, roupa e proporções. A API reutilizável em `modules/character_customization/appearance.gd` aceita perfis JSON, mantém o contrato de UV/ossos e limita largura/altura/profundidade. As cápsulas e hurtboxes dos NPCs acompanham a escala. O player continua na V4 aprovada, sem mudança de aparência.

A fonte da Bíblia disponível é EXO-Murim V0.1, seção 6.5. Ela define Ji Wol e HWA-02, mas não fornece uniforme de seita para estes cinco civis. As paletas refletem trabalho no vau, pesca, praça e casa de chá; nenhuma filiação foi inventada.

Verificação: Godot 4.6.3 Standard Compatibility importou os assets; `customization_test.log` contém VILLAGE_APPEARANCE_PASS; `customization_suite.log` contém VILLAGE_NPCS_PASS (movimento, dano, save, região e reset). `customization_gallery.log` contém CUSTOMIZATION_GALLERY_PASS, com cinco capturas reais `appearance_*.png`. O GLB fonte mantém SHA-256 fc8af84dc28bd3c5e1a308df7a72efe702558824e924b52ac5d49ea75d11e557, atlas original SHA-256 9e8a956f10bddd67070a52e593222f203650f235368b7b26d5095c166264fbb9.

Limites: mudanças faciais são variações pintadas sobre o rosto base, não retratos inteiramente novos; roupas compartilham a geometria V4; cabelo usa peças existentes. Não há tela de personalização do player nem integração do perfil com save do player. Teste manual humano e Godot 4.7.2 não disponíveis.
