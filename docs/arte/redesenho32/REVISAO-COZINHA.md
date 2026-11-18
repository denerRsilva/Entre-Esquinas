# Revisão 2 — fogão, pia e geladeira

O primeiro redesenho foi rejeitado pelo proprietário: excessivamente genérico,
com o fogão quase frontal enquanto a pia mostrava seu plano superior. Esta
revisão trabalha os três aparelhos juntos e conserva os originais anteriores
como referência de acabamento. É um estudo separado; o jogo e o APK não mudaram.

[Prévia dos PNGs reais a 500%](previas/previa-cozinha-revisao2-5x.png).
[Composição em tamanho nativo](previas/cozinha-revisao2-nativa.png).
A referência gerada na conversa é um estudo visual ampliado; não foi reduzida
para produzir estes PNGs.

| Peça | Canvas real | Arquivo |
|---|---|---|
| Fogão apagado | 64×64 | [PNG](png/moveis/fogao_apagado.png) |
| Fogão aceso | 64×64 | [PNG](png/moveis/fogao_aceso.png) |
| Pia | 64×64 | [PNG](png/moveis/pia.png) |
| Geladeira fechada | 32×64 | [PNG](png/moveis/geladeira_fechada.png) |
| Geladeira aberta | 64×64 | [PNG](png/moveis/geladeira_aberta.png) |

O fogão mostra um tampo de aproximadamente 20px de profundidade, com duas bocas
elípticas, anéis, rebites e borda biselada. A frente fica sob esse plano e ocupa
menos altura que na primeira tentativa. A abertura elíptica da chaminé reforça
a vista elevada. A panela continua sendo uma peça separada.

A pia usa uma profundidade de tampo semelhante, com cuba vazia, parede interna,
fundo e ralo, além de esmalte lascado, válvulas e torneira de latão. Os painéis
de madeira têm relevos e pequenas marcas em grupos de pixels. A geladeira tem
um plano superior arredondado visível, vedação, puxador metálico e manchas de
ferrugem desenhadas como lascas de esmalte.

As frentes seguem apontadas para baixo, sem inclinar uma peça para uma vista
isométrica. Os PNGs foram desenhados nos canvases finais. O ganho de volume vem
das formas, áreas de luz/sombra e pequenos clusters de pixels, sem aumentar a
resolução nem aplicar suavização. A perspectiva deve continuar sendo julgada
visualmente lado a lado, não presumida a partir de uma dimensão válida.

A amostra `Amostra.tscn` e suas prévias usam esses cinco arquivos revisados. Os
outros 130 PNGs de produção ficaram byte a byte iguais à revisão anterior.
O ZIP geral foi atualizado; [pacote somente dos aparelhos](../cozinha32-revisao2.zip).
Ainda é necessário avaliar a nova linguagem visual antes de espalhá-la pelo
restante do acervo. Nenhuma integração na sala jogável foi feita.
