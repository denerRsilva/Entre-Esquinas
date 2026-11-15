# Pratos reais e tamanho físico consistente

A estação aceita até **20 pratos limpos**, em duas pilhas de dez na borda
esquerda, uma acima da outra, e até **quatro pratos prontos**. Cada sprite
corresponde a um prato real; sem estoque, não há prato decorativo.
A estação de empratamento não tem pano nem pegador: o tampo de madeira fica
livre, mostrando apenas os pratos que existem no estoque. No catálogo, a função
de empratamento é identificada por um ícone de prato.

`Alimentos.gd` centraliza as dimensões do mundo: prato limpo 20×12, prato servido
20×14 e ingrediente em uma caixa de 24×24. Cada ingrediente mantém sua proporção
e o mesmo tamanho entre mão, corte e fogão. Pratos limpos usam a mesma textura,
recorte e dimensões nas mãos e nas pilhas; pratos sujos usam a mesma louça com
marcas de sujeira. A comida pronta mantém a escala entre mãos do jogador/garçom,
estação e mesa do cliente. Ícones de pedidos e menus continuam sendo elementos
de interface. O zoom da câmera afeta toda a cena igualmente.

`Cena.gd` envia o estoque para `Palco.gd` e `MesaTrabalho.gd`. As posições de limpos
e servidos ficam em `LayoutEmpratamento.gd`; as cerâmicas não encolhem para caber
na superfície. Ao girar a mesa, a organização se adapta sem esticar os pratos.
O cache é atualizado por quantidade e orientação, inclusive ao reutilizar nós.

O empratamento exige uma superfície com as dimensões da mesa de preparo: **2×1**
(ou 1×2 após girar). A mesa/bancada de trabalho existente tem esse tamanho.
As peças modulares horizontal, vertical e de quina atuais têm 1×1 e não aceitam
empratamento. As peças antigas permanecem nos salvamentos. As dezesseis peças novas editadas
no Piskel estão disponíveis na seção Bancadas, com apoio de panela quando vazias.
As ferramentas continuam exigindo as mesas compatíveis; os novos módulos
individuais não viram estações de empratamento.
A instalação, o destaque de compatibilidade, as ações de cozinha, o armazenamento
e o validador usam a mesma regra, baseada no tamanho da base física.

A tarefa só começa com espaço para todas as porções. Se outra ação ocupar a
última vaga, ela aguarda a retirada de um prato sem consumir louça ou comida.
O jogo mobiliado começa com 12 pratos limpos reais; uma estação nova começa vazia.

Saves antigos preservam seus itens: acima de vinte pratos limpos ou quatro
pratos prontos, o excedente vai para armazenamento compatível ou recuperação,
com receita e qualidade mantidas. Em bancadas pequenas anteriormente equipadas,
os itens são recolhidos e o valor integral do kit é reembolsado. A peça, sua
posição e uma eventual panela apoiada são preservadas. Um empratamento em curso
nessa peça é cancelado sem consumir a panela nem seu conteúdo. O processo trabalha
por cópia e não repete o reembolso no próximo carregamento.

A base dessas regras passou por 41 suítes de regressão. `TamanhoItensUI` compara as dimensões efetivas
das texturas entre mão, corte, fogão, empratamento e serviço. `BancadasEmpratamentoUI`
cobre recusa sem cobrança em todas as peças pequenas e rotações, corte preservado,
superfície 2×1, migração de estoques/qualidades, recuperação sem espaço, tarefa
antiga, rejeição de dados corrompidos e ausência de reembolso duplicado.
`PratosEstoqueUI` e `SlotsEmpratamentoUI` cobrem contagem real, reposição, consumo,
limites, separação dos pratos, instâncias independentes e reuso de nós.

Captura atual: `docs/arte/empratamento-quatro-pratos.png`, feita com Compatibility.
Android 0.21.2-godot.37 (21237), com ZIP e assinatura v2/v3 verificados.
Sem teste em aparelho Android físico nesta execução.

Após remover o pano e suspender as novas compras de bancadas passaram oito suítes:
`PratosEstoqueUI`, `TamanhoItensUI`, `SlotsEmpratamentoUI`, `MesasModularesUI`,
`NovidadesTavernaUI`, `ConstrucaoCompletaUI`, `EnquadramentoConstrucaoUI` e
`InterfaceLimpaUI`. A captura acima foi atualizada sem o pano.
