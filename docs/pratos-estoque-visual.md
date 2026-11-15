# Pratos reais na arte da estação

Cada estação de empratamento aceita até **20 pratos limpos**, organizados em
duas pilhas de até 10 na borda esquerda, uma acima da outra. A pilha superior
recebe os primeiros dez; os demais vão para a inferior. Três pratos desenhados correspondem a três unidades de estoque;
zero remove todos os sprites de pratos. Não há pratos decorativos embutidos
no pano ou no pegador. A arte aprovada do kit foi aplicada com esses acessórios
separados do estoque.

`Cena.gd` envia `plates` junto da instância de móvel para `Palco.gd`, que atualiza
a propriedade `pratos_limpos` de `MesaTrabalho.gd`. A geometria é recalculada
quando a quantidade, a escala ou o tipo de superfície muda. Cada unidade gera um sprite independente,
com cache por instância; o reuso de nós não conserva pilhas de outra estação.
As cerâmicas preservam a proporção quando o móvel é girado ou usa uma bancada.

O prato sai da pilha quando é retirado ou consumido no empratamento; volta
quando o jogador o coloca na estação. A compra do kit inclui pano e pegador,
sem pratos fictícios na miniatura ou no cenário. Os pratos prontos com comida
ocupam quatro posições individuais: direita inferior, direita superior, centro
superior e centro inferior. A estação aceita no máximo **quatro pratos prontos**;
a quantidade de pratos desenhados sempre corresponde ao estoque real.
O jogo mobiliado continua começando com 12 pratos reais: uma pilha de 10 e
outra de 2. Uma estação nova começa sem pratos.

O limite de vinte é aplicado na colocação pelas mãos, na API de armazenamento,
nas ações de compatibilidade e no validador de estado. Ao carregar um save
antigo com até 99 pratos por estação, o excedente é enviado a um armazenamento
compatível. Se não houver espaço, fica na recuperação de itens preservados.
O total de pratos não muda; o arquivo de origem é processado por cópia.

As posições de limpos e servidos usam a mesma geometria em `LayoutEmpratamento.gd`.
Mesas giradas preservam o formato das cerâmicas; bancadas recebem uma versão
compacta dentro de sua área útil. A tarefa de empratamento só começa com espaço
para todas as porções. Se outra ação ocupar a última vaga durante a tarefa,
ela aguarda a retirada de um prato, sem consumir pratos limpos nem comida.

Salvamentos antigos com até doze pratos prontos por estação mantêm quatro no
tampo. O excedente é transferido para armazenamento compatível ou recuperação,
com receita e qualidade preservadas, sem alterar os totais de refeições e pratos.

Validação: 39 suítes de regressão. `SlotsEmpratamentoUI` verifica quatro posições
separadas, pilhas à esquerda, limite de capacidade, espera e retomada da tarefa,
conservação, qualidades e migração com e sem armazenamento livre. `PratosEstoqueUI`
continua cobrindo quantidades reais de zero a vinte, retirada, reposição, consumo,
estoques independentes e reuso dos nós.

Captura do jogo com vinte pratos limpos e quatro pratos prontos:
`docs/arte/empratamento-quatro-pratos.png`. Renderizador Compatibility; sem teste
em aparelho Android físico nesta execução.

Android 0.21.2-godot.34 (21234). ZIP e assinatura APK v2/v3 verificados.
