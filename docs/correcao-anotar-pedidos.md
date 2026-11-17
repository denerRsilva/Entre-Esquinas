# Seleção do cliente e anotação de pedidos

Correção **0.21.2-godot.51**, Android **21251**.

A [.52](playtest-atendimento-direto.md) complementa esta correção com barra de
anotação para o jogador, atendimento sem ícones e playtest por mouse nativo.

## Causa reproduzida

Na .50, clicar no rosto do cliente da cadeira superior deixava o cliente em
`waiting`, sem pedido, e produzia internamente “Passagem bloqueada”. Clicar
mais abaixo, na célula lógica do assento, anotava normalmente. O sprite de 64
unidades de exibição se projeta acima da célula de navegação de 40 unidades;
o rosto estava sobre a célula que o sistema interpretava como parede.
O teste anterior clicava na célula lógica da mesa e não cobria esse ponto visível.

## Correção

A seleção considera o retângulo do personagem desenhado, ancorado nos pés,
antes de resolver móveis e paredes. Em áreas sobrepostas, prioriza o cliente
em primeiro plano e o mais próximo horizontalmente. O clique na célula continua
válido. A seleção encaminha a interação existente: aproximar, anotar ou servir,
sem alterar pedidos, preços, paciência, distância de atendimento ou recursos.
Não foram alteradas sprites, resolução artística, navegação ou salvamentos.
64 unidades de exibição não substituem a diretriz de arte nativa 32 × 32.

## Verificação

As **54 suítes padrão passaram**, incluindo cozinha, atendimento, mercador e
salvamentos. O teste específico foi repetido após verificar os pontos de toque
dentro da tela nos diferentes zooms.

`AnotarPedidosUI` reproduziu o erro antes da mudança e passou depois. Percorre
as oito cadeiras do novo início, clicando no rosto de cada cliente, verifica
comanda do cliente correto, salvamento válido e clique repetido sem duplicação.
Também cobre três moradores próximos sem funcionário, clique no assento e
zooms 0,7/1,5/2,0 em tela compacta. A seleção em área vazia não encontra clientes.

[Captura com pedido anotado](arte/anotar-pedido-corrigido.png), obtida em
Compatibility no Linux. APK compilado e verificado; não houve teste em aparelho
Android físico.
