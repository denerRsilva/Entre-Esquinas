# Bancadas do Piskel e seções de construção

O PNG enviado no arquivo `bancada_spritesheet.zip` é usado sem alteração de pixels
em `godot/arte/modular/bancadas-piskel.png`. A implementação usa recortes do atlas;
não gera outra arte. O arquivo original tem 1536×1024 pixels e fundo transparente.
SHA256: 44326e2adec2351337c2d3f8449bac3d111f8770bacc8aab1d8b05614a425f61.

Cada uma das duas famílias (fina e grossa) tem oito peças compráveis: ponta
esquerda, horizontal repetível, ponta direita, topo vertical, prolongamento
vertical, base vertical e duas quinas. Cada módulo ocupa uma célula de 40×40,
com frente de 30 de altura. O tampo horizontal tem profundidade 14 na fina e 24
na grossa; os braços verticais têm largura 20 e 32, respectivamente. Os recortes
são ajustados à grade mantendo a frente em pé e separando o plano do tampo.
Margens transparentes de cada recorte são consideradas no alinhamento.

Coloque pontas nas extremidades e peças centrais para alongar. Nas verticais,
o topo inicia o trecho, o prolongamento aumenta o comprimento e a base fecha
a frente. As quinas ligam as duas direções. O botão **Espelhar ↔** inverte a peça
horizontalmente sem girar os painéis de lado; isso permite alinhar uma coluna
vertical ao braço direito ou esquerdo da quina. As miniaturas usam a mesma cena
e o mesmo atlas do mundo. As peças antigas continuam válidas em saves e não
são vendidas como alternativas às novas.

O catálogo agora mostra uma seção por vez, com botões de seleção e duas colunas:

- Bancadas: oito peças finas e oito grossas, em grupos identificados.
- Ferramentas: corte/preparo e empratamento, para instalar nas mesas compatíveis.
- Móveis: mesas, cadeiras, mesa de trabalho e móveis de armazenamento.
- Decorações: vasos de planta e flores, usando a arte já existente.
- Equipamentos: fogão, geladeiras, pia, computador e lixeira.

A seção escolhida continua selecionada depois de posicionar, cancelar ou
reembolsar um objeto. As regras de saldo, colisão, caminhos, setores, pausa
da simulação e salvamento continuam sendo usadas. Novas decorações têm posição,
custo, ocupação e reembolso próprios, sem alterar as plantas fixas do cenário.
Bancadas vazias aceitam apoio de panela; não podem ser guardadas com itens apoiados.
As estações de empratamento continuam limitadas às superfícies do tamanho da mesa
de preparo, com pratos e ingredientes na escala física já aprovada.

Validação: 43 suítes de regressão aprovadas. `BancadasPiskelUI` cobre as 16 compras,
retorno à seção, atlas correto, espelhamento, ocupação, save/load, apoio/retirada
de panela, bloqueio de remoção ocupada e reembolso. `CatalogoSecoesUI` cobre os
botões de seção, filtros, duas colunas, compra de decorações e três proporções
de tela. Os botões de categoria e o painel de posicionamento foram conferidos
novamente após o ajuste visual, e a montagem reta e as duas quinas foram
capturadas com o renderizador Compatibility.

Capturas: `docs/arte/bancadas-piskel-montadas.png` e
`docs/arte/catalogo-construcao-secoes.png`.
Android 0.21.2-godot.38 (21238), ZIP e assinatura v2/v3 verificados.
Sem teste em aparelho Android físico nesta execução.
