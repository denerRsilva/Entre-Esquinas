# Prato vazio e proposta para o kit de empratamento

O prato limpo carregado nas mãos usa agora um sprite de cerâmica oval, com
borda clara, centro rebaixado e contorno escuro. A arte é desenhada em 20×12
unidades de jogo, com filtro nearest, usando a mesma posição de mão já adotada
nas quatro direções. Substitui apenas o desenho do prato limpo nas mãos;
a transferência, a lavagem, os pratos servidos e as quantidades não mudam.

A imagem original gerada está em `godot/arte/modular/prato-vazio.png`; a região
(125,166,1249,736) seleciona a silhueta útil sem reamostrar o PNG original.
A conferência visual das quatro direções foi feita no renderizador Godot
Compatibility, retirando um prato da mesa e devolvendo-o pela interação real.
Captura de referência em `docs/arte/prato-vazio-nas-maos.png`.

A proposta para substituir a arte do kit, em
`docs/arte/proposta-kit-empratamento.png`, reúne uma pilha pequena de pratos,
um pano dobrado com uma faixa verde discreta e um pegador de servir curto.
O conjunto ficaria centralizado, ocupando aproximadamente um terço da largura
da mesa, deixando a madeira visível. A paleta creme/madeira e a perspectiva
seguem os móveis existentes.

O kit é uma proposta para avaliação do usuário: o sprite do kit no jogo e
no catálogo de construção ainda não foi trocado. A implementação solicitada
neste pedido abrange o prato carregado pelo jogador.

Verificação: `CenaNativa`, `FluxoCompletoNativoUI`, `InterfaceLimpaUI` e
`SalvamentoDiscoNativoUI` aprovados. O comparador de snapshots históricos
normaliza apenas o novo sprite de prato carregado para a geometria antiga;
a arte atual foi conferida visualmente na própria cena do jogo.

Android 0.21.2-godot.32 (21232), exportado do commit ddee7f5. ZIP e assinatura
APK v2/v3 verificados; novo sprite incluído, proposta do kit fora dos recursos
do jogo. Sem teste em aparelho Android físico nesta execução.
