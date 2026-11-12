# Restaurante jogável — Godot .7

Primeira integração das pranchas aprovadas. Abra **Começar na taverna** para ver a composição inicial; carregar um save preserva sua disposição anterior.

- Piso de madeira no salão e azulejo na cozinha em TileMapLayer; paredes, janelas, luminárias, plantas e tapetes.
- Três mesas com velas e 12 cadeiras orientadas para as mesas. Fogão, geladeira, preparo, apoio de pratos, pia, estante e lixeira com os novos recortes.
- Cozinheira animada em quatro direções, iniciando na cozinha. Alimentos crus, cortados e receitas usam a nova prancha.
- Computador administrativo e recebimento mantêm suas posições de interação. Esta montagem não implementa comércio com NPCs ou fabricação por artesão.

Os PNGs originais ficam em `godot/arte/taverna`. `recortes.json` mede as regiões não uniformes das pranchas; as imagens originais não foram reamostradas. A arte é uma integração dos estudos ampliados com filtro nearest, ainda não um atlas final desenhado em pixels nativos 32×32. A grade lógica permanece 40 px e a planta funcional anterior foi preservada. Rua e NPCs ainda usam arte anterior.

Validação: Regras.cjs; MaosUI (retirada, corte, panela, receita, empratamento e save); MovimentoUI (colisão, direções, pausa e animação); Verificar (cena, TileMap, UI e regras). Todos passaram na Godot 4.6.3 Linux. Captura gráfica em restaurante-jogavel.png. APK .7 exportado e validado quanto à assinatura e alinhamento; não testado em aparelho Android físico.
