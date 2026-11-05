# Entre Esquinas 0.16.0 — arte de comidas

Escopo: aplicar as artes aprovadas dos três ingredientes e três receitas e substituir nomes visuais por artes. Nenhuma mudança nas regras econômicas, receitas ou salvamento.

## Implementação

Atlas transparente original em dist/assets/esquina-food.png, criado a partir da prévia aprovada. Módulo restaurant-food.js compartilha identificação entre textos da interface e sprites no cenário. Tradução visual usa o nome completo das receitas antes dos ingredientes para evitar trocar um prato composto por duas artes de ingredientes. Nomes permanecem nos rótulos acessíveis.

Inventário e armazenamento usam arte com quantidades, sem nomes duplicados. Panelas com comida mostram a arte da receita e marcador de porções. Fornecedor, cardápio, entregas, cartões de receita, ingredientes necessários, pedidos, escolhas da bancada, avisos e progresso trocam nomes por ícones. Mesas, bancada e transporte de comida usam a mesma arte no cenário. Indicadores de paciência deslocados para não cobrir a imagem do pedido.

## Validação executada

- Suíte UI: atendimento, serviço, lavagem, bancada, seleção de receitas, tempo/pausa e direção passaram com o módulo de comidas carregado.
- Identificação de receita versus ingredientes, nomes compostos, panelas parciais e pratos testada.
- Desenho de alimentos testado com canvas simulado, sem constituir verificação visual real.
- Cozinha: 16 cenários passaram; conservação, espaço cheio, cancelamento e migração preservados.
- Chegadas: passou.
- Sintaxe de JS e diff verificados. HTML gerado com atlas incorporado.

## Limitações

Não foi realizada inspeção visual desta versão em navegador nem celular físico; o ambiente de navegador apresentou bloqueio na sessão. A substituição de nomes no DOM mantém intactas funções e dados, mas precisa de playtest para avaliar tamanho de cada ícone em mensagens e telas estreitas. Os utensílios e os verbos de ação continuam identificados por textos/ícones próprios. Não inclui balanceamento ou novas mecânicas de comida.
