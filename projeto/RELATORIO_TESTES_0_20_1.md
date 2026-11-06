# 0.20.1 — Utensílios no computador

05/11/2026. Base 0.20.0, a10cf4c701624a79e44f5c3811474e451ffbef13.

- Aba Utensílios adicionada ao computador; removida da construção. Panela, colher/talher e prato mantêm preços $25/$15/$5, compra imediata para a mochila e limites existentes.
- Cartões com artes Canvas em pixels e identificação acessível. Panela/prato reutilizam a arte do cenário, colher usa paleta equivalente. Nenhuma alteração no núcleo da simulação ou save.
- node ui.test.cjs: passou. Novos cenários verificam ausência da aba na construção, presença no computador, três artes, aquisição de cada item, débito exato, bloqueio por saldo e mochila cheia e acesso presencial. Regressões da cozinha, câmera e modo construção da suíte também passaram.
- Sintaxe dos scripts UI/arte e build HTML: passaram.
- Chrome na prévia local: iniciou mobiliado, caminhou ao computador, abriu Utensílios; inspeção visual dos três cartões com arte, preço e quantidades executada.
- Sem playtest humano ou teste em dispositivo físico.
