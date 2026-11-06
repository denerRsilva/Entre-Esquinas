# 0.20.0 — Modo construção

05/11/2026. Base: 0.19.0, bcf15a3eace33f4df91f576de8230dda4d67b3d6.

## Implementação
- Entrada Gestão → Modo construção. Estado de pausa independente da peça selecionada; relógio, movimento, cozinha, queima e simulação param durante todo o modo.
- HUD operacional e identificações no cenário ocultas. Botão único com catálogo inicialmente recolhido; saldo e saída dentro do painel.
- Catálogo existente preservado, nove sprites, compra ao confirmar posição válida. Cancelar e confirmar mantêm a pausa. Controles de posicionamento aparecem somente durante a instalação.
- Escape cancela posição, recolhe catálogo ou volta ao jogo. Câmera navegável por arraste ou teclado. Retomada reinicia o contador de quadros, sem compensar tempo parado.
- Bloqueios de reforma durante serviço preservados; saves e núcleo da simulação inalterados.

## Validação executada
- node ui.test.cjs: passou, incluindo regressões existentes e cenários novos: pausa com catálogo fechado/aberto, preparo congelado por estado completo, posição inválida sem cobrança, posição válida cobrando uma vez, confirmação repetida sem duplicar, cancelamento sem retomar e retorno sem salto de tempo. Entrada com serviço aberto recusada.
- node --check nos scripts UI e arte: passou.
- python3 build.py ../dist/index.html e git diff --check: passaram.
- Navegador Chrome na prévia: versão 0.20.0, entrada pelo menu, árvore acessível somente com cenário/botão no modo recolhido, catálogo lateral com sprites/preços/saldo/saída. Inspeção visual executada. Sem playtest humano ou celular físico.

## Limitações
Não houve validação de diversão ou sessão completa nesta tarefa. As regras de reposicionamento e venda preexistentes continuam nas ações dos objetos fora do modo. A pausa de construção não é persistida no save, pois é estado de interface.
