# 0.17.0 — Qualidade de ingredientes, pratos e queima

## Requisitos implementados

Origem: seção 22 do GDD, aprovada em 04/11/2026, e autorização posterior de implementação. Base anterior: 0.16.0.

- Escala única 0–3: comum, prata/cinza, ouro/amarela, roxa. Estrelas somente nos itens de ingrediente ou prato pronto. Panelas e seleção/preparo de receitas não mostram estrelas.
- Qualidade escolhida no fornecedor, com arte do ingrediente e preço por unidade atualizados antes de comprar. Entregas e inventários mantêm qualidades separadas.
- Pilhas de qualidades diferentes não se juntam. Ingredientes consumidos na ordem dos slots da mochila. Nível inicial do lote: piso da média ponderada pela quantidade consumida, sem sorteio. Qualidade sobrevive a transporte, armazenamento, retirada, sobras, empratamento e serviço.
- Multiplicadores provisórios de custo por qualidade: 1, 1,25, 1,5 e 2. Custo do preparo considera os ingredientes realmente consumidos.
- Janela segura de 8 s após concluir. Degradação progressiva entre 8 e 20 s até comum; aviso final de 20 a 25 s; queima a partir de 25 s. A estrela do item é uma classificação discreta da qualidade interna, não aparece na panela.
- Retirar panela encerra o processo. Comida queimada permanece fisicamente na panela, bloqueada para empratar. Descarte devolve recipiente e registra porções perdidas.
- Barra única por estado no fogão e aviso compacto: verde no ponto, laranja passando, vermelho perto da queima, símbolo de perda quando queimado. Fumaça e escurecimento no cenário. Avisos sonoros curtos nas transições, após primeiro gesto que habilita áudio.
- Avisos e barras SEM estrelas. Nenhum controle desses avisos altera a câmera. A ideia IP-001 continua fora da implementação.
- Satisfação: 35% atendimento, 35% espera da comida e 30% qualidade. Valores de qualidade normalizados: 0,7 / 0,8 / 0,9 / 1. Preço do pedido preservado. Visitas antigas não são recalculadas.
- Save formato 9 em chave nova entre-restaurante-09, com leitura das chaves anteriores. Migração clona o arquivo e atribui padrão comum a dados antigos; panela pronta antiga recebe uma primeira janela segura ao migrar. Salvar o novo formato não sobrescreve a chave antiga.

## Verificação executada

- quality.test.cjs: 15 cenários passaram. Cobertura: separação/transferência de pilhas; compra e entrega parcial; custos; média ponderada; estados temporais; retirada e empratamento; sobras; queima/descarte; save em preparo/no ponto; migração antiga; garçom e pedido cancelado; satisfação; logística; transferência agregada; mochila cheia; cancelamento.
- ui.test.cjs: passou, incluindo escolha de qualidade no fornecedor, alerta no ponto/queimado, ausência de estrela textual no aviso, câmera preservada e pausa dos contadores durante menu, além das interações já existentes.
- kitchen.test.cjs: 16 cenários passaram.
- patience.test.cjs: 15 cenários passaram; expectativa de qualidade de uma refeição comum atualizada de ausente para zero. Histórico legado continua aceito.
- calendar-reputation.test.cjs: 12 cenários passaram.
- arrivals.test.cjs: passou.
- Sintaxe de JavaScript, git diff --check e empacotamento HTML: executados com sucesso.

## Limitações reais

Testes de UI/canvas usam ambiente simulado. Não foi realizada inspeção visual desta versão no navegador ou celular físico; o ambiente de navegador vinha bloqueando a inspeção. Cores, tamanho de estrelas, efeitos, sons e ritmo precisam de playtest no dispositivo. A disponibilidade do áudio depende da política do navegador e de um gesto do jogador. Fórmulas, preços e tempos são parâmetros de protótipo, documentados para ajuste posterior. Não inclui incêndio, validade de ingredientes, mudanças de câmera, autosave ou correção do limite histórico de pedidos.
