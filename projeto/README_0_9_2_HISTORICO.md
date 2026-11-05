# Entre Esquinas — Restaurante 0.9.2

Foco desta etapa: operação e diversão dentro do restaurante. Nenhum sistema novo de personagens ou narrativa foi acrescentado.

## Jogar
Abra o HTML JOGAR na pasta principal, ou projeto/dist/index.html. Sem dependências externas.
O jogador começa no restaurante. Estoque, computador e recebimento ficam na mesma tela, à direita; não existe porta para outra cena de estoque. A rua permanece acessível pela saída do salão.

## Inventário
Botão entre Gestão e Montar; atalho I no teclado. A mochila pausa a simulação enquanto aberta e possui exatamente 10 espaços, até 99 itens por pilha, incluindo ferramentas.
Panela e utensílio comprados em Montar vão para a mochila; continuam disponíveis para preparo enquanto estiverem nela. Compras de ferramentas com mochila cheia não retiram dinheiro. Pilhas parciais são completadas antes de ocupar espaços vazios.
Ingredientes comprados chegam ao recebimento. Aproxime-se e use Recolher ingredientes: recolhe arroz, legumes e frango até o limite da mochila; o restante permanece no recebimento. O seletor suspenso de ingredientes foi removido.
Abra Inventário, toque na pilha desejada, feche a mochila e aproxime-se de um equipamento para Depositar. O depósito respeita a capacidade do equipamento e preserva o restante na mochila. Também é possível retirar ingredientes dos equipamentos para a mochila. Pratos prontos continuam sendo transportados pela ação de serviço existente, em separado.

## Primeira partida
1. Monte mesa e cadeira no salão, fogão e geladeira na cozinha; prateleira e geladeira de estoque também ficam à direita, na mesma tela.
2. Compre panela e utensílio em Montar.
3. Clique no computador à direita para comprar ingredientes.
4. Recolha-os no recebimento; selecione uma pilha no Inventário e deposite na cozinha. Ou atribua Logística a um funcionário para fazer recebimento → armazenamento → cozinha.
5. Abra almoço, anote os pedidos, prepare no fogão e sirva. Termine almoço e jantar para fechar o dia.

## Salvamento
Formato 2, chave entre-restaurante-02. As versões 0.9.0/0.9.1 e a mercearia permanecem preservadas: nenhum dado anterior é sobrescrito. Devido ao novo mapa e inventário, a 0.9.2 inicia uma nova partida e não importa automaticamente os saves anteriores.

## Validação executada
- node restaurant.test.cjs: ciclo completo almoço/jantar, conservação de ingredientes, logística integrada, montagem, corredores, movimento suave, salvamento, dez espaços, pilhas de 99, transação com inventário cheio e recolhimento parcial.
- node ui.test.cjs: interface com DOM simulado; botão na ordem solicitada, dez espaços, seleção de pilha, ferramentas compradas, recebimento sem seletor e acesso ao computador na mesma cena.
- node test.cjs: regressão da mercearia preservada.
- Sintaxe dos scripts e integridade do ZIP verificadas ao empacotar.
Não foi possível executar navegador real no ambiente (Chromium ausente). Layout visual, toque, fullscreen e conforto em Android real não foram verificados nesta entrega. Testes simulados não validam a sensação de jogar.

## Arquivos alterados
- dist/restaurant-core.js: inventário, ferramentas, transferências, conservação, formato de save e estoque integrado.
- dist/restaurant-ui.js, dist/restaurant.css, dist/index.html: mochila, controles, desenho e interações na mesma cena.
- restaurant.test.cjs e ui.test.cjs: testes funcionais e de interface simulada.
- README.md, LEIA_ME.txt, MIGRACAO_RESTAURANTE.md e HTML único: documentação e distribuição.
O histórico anterior está em README_0_9_1_HISTORICO.md. Valores, receitas e limites operacionais sem alteração fora dos pedidos desta etapa. Permanece um preparo por vez; personagens sociais continuam apenas demonstrativos.
