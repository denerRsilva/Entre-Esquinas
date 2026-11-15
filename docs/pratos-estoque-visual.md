# Pratos reais na arte da estação

Cada estação de empratamento aceita até **20 pratos limpos**, organizados em
duas pilhas de até 10. A primeira recebe os primeiros dez; os demais vão para
a segunda. Três pratos desenhados correspondem a três unidades de estoque;
zero remove todos os sprites de pratos. Não há pratos decorativos embutidos
no pano ou no pegador. A arte aprovada do kit foi aplicada com esses acessórios
separados do estoque.

`Cena.gd` envia `plates` junto da instância de móvel para `Palco.gd`, que atualiza
a propriedade `pratos_limpos` de `MesaTrabalho.gd`. A geometria é recalculada
somente quando a quantidade muda. Cada unidade gera um sprite independente,
com cache por instância; o reuso de nós não conserva pilhas de outra estação.
As cerâmicas preservam a proporção quando o móvel é girado ou usa uma bancada.

O prato sai da pilha quando é retirado ou consumido no empratamento; volta
quando o jogador o coloca na estação. A compra do kit inclui pano e pegador,
sem pratos fictícios na miniatura ou no cenário. Os pratos prontos com comida
ficam separados dos limpos, com os limites de retirada de comida existentes.
O jogo mobiliado continua começando com 12 pratos reais: uma pilha de 10 e
outra de 2. Uma estação nova começa sem pratos.

O limite de vinte é aplicado na colocação pelas mãos, na API de armazenamento,
nas ações de compatibilidade e no validador de estado. Ao carregar um save
antigo com até 99 pratos por estação, o excedente é enviado a um armazenamento
compatível. Se não houver espaço, fica na recuperação de itens preservados.
O total de pratos não muda; o arquivo de origem é processado por cópia.

Validação: 38 suítes de regressão aprovadas. `PratosEstoqueUI` cobre todas as
quantidades de borda, duas pilhas, retirada do último prato, reposição,
consumo real no empratamento, rejeição do 21º prato, estações independentes,
reuso de nós, save/load, saves antigos com 99 e recuperação sem armazenamento
livre. Após a organização visual dos pratos prontos também passaram
`CenaNativa`, `PratosEstoqueUI`, `DesempenhoGarcomUI` e `FluxoCompletoNativoUI`.

Capturas feitas com o renderizador Compatibility em `docs/arte/pratos-0.png`,
`pratos-3.png`, `pratos-20.png` e `pratos-empratados.png`. Sem teste em aparelho
Android físico nesta execução.

Android 0.21.2-godot.33 (21233), exportado do commit 2556cc9. ZIP, presença dos
novos recursos/scripts e assinatura APK v2/v3 verificados.
