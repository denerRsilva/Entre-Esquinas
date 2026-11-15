# Bancadas do Piskel e seções de construção

O PNG enviado no arquivo `bancada_spritesheet.zip` é usado sem alteração de pixels
em `godot/arte/modular/bancadas-piskel.png`. A implementação usa recortes do atlas;
não gera outra arte. O arquivo original tem 1536×1024 pixels e fundo transparente.
SHA256: 44326e2adec2351337c2d3f8449bac3d111f8770bacc8aab1d8b05614a425f61.

Cada família (fina e grossa) tem oito peças compráveis: ponta esquerda,
horizontal central, ponta direita, topo vertical, prolongamento vertical,
base vertical e duas quinas. O catálogo e os salvamentos mantêm esses 16 tipos.

A versão 40 usa os desenhos completos de cada recorte, sem repetir o painel
frontal ou criar outros veios de madeira. O trecho central mede 40 unidades;
as pontas fechadas mantêm largura proporcional ao centro, com margem no lado
externo da célula. A borda aberta permanece alinhada com a célula seguinte.
As quinas medem 26 (fina) ou 33 (grossa), com portas verticais de 23 ou 31.
Os pequenos braços horizontais são os recortes da spritesheet enviada.

Os recortes copiados no Piskel têm deslocamentos diferentes. Os pontos de
referência são a linha dourada e o início do painel frontal, medidos em cada
peça; a montagem alinha essas duas linhas. O painel original é desenhado
inteiro e mantém 30 de altura. As bases e os capitéis usam seus próprios
recortes. Apenas o prolongamento fornecido é cortado na medida necessária
para conectar o topo, a vertical e a quina/base. Não há faixas de madeira
ou contornos inventados. O canal alpha do usuário é preservado.

Os pontos de conexão e limites das imagens são arredondados para a grade de
pixels. A coluna vertical é posicionada sobre a porta da quina correspondente.
**Espelhar ↔** seleciona a ponta/quina oposta fornecida e alinha a coluna ao
outro lado; a câmera e os painéis continuam em pé. As miniaturas usam as mesmas
cenas do mundo. Peças antigas continuam válidas em saves, sem venda alternativa.

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

A base de construção passou pelas 43 suítes da integração inicial. Após a
remontagem da versão 40 passaram `BancadasPiskelUI`, `CatalogoSecoesUI`,
`CenaNativa`, `ApoioPanelasUI` e `DesempenhoGarcomUI`. A captura do renderizador
Compatibility também verifica a cobertura de alpha nas emendas horizontais,
verticais e entradas das quinas, além da montagem com base vertical. O teste
considera a margem natural dos acabamentos fechados e examina as bordas abertas.

Captura atual: `docs/arte/bancadas-piskel-montadas.png`.
A tentativa anterior está em `docs/arte/bancadas-piskel-tentativa39.png`.
Android 0.21.2-godot.40 (21240), ZIP e assinatura v2/v3 verificados.
Sem teste em aparelho Android físico nesta execução.
