# Diretriz obrigatória: pixel art 32 × 32

Confirmada pelo proprietário em 16/11/2026. Esta é a regra de produção da arte
do projeto, incluindo personagens, alimentos, objetos, pisos, paredes e ícones.

- Unidade base: **32 × 32 pixels reais**. Cada quadro de personagem usa essa
  célula; uma folha com quatro direções e quatro quadros terá 128 × 128 pixels.
- Itens pequenos podem ocupar menos pixels dentro do canvas 32 × 32. Manter o
  mesmo tamanho aparente entre mão, mesa, fogão e outras superfícies.
- Estruturas maiores devem ser compostas por células de 32 × 32, preservando
  densidade de pixels, paleta e perspectiva. Não acrescentar detalhes de maior
  resolução e escondê-los reduzindo a textura na Godot.
- Usar pixels nítidos, transparência limpa e perspectiva superior com a frente
  visível. Preservar a paleta de madeira das mesas e a direção aprovada.
- Validar conexões e repetição de pisos/paredes na grade; alinhar pés, pivôs e
  silhueta dos personagens entre animações. Não usar suavização na ampliação.

## Estado atual e edição

Várias imagens em uso ainda são estudos ampliados com recortes em resoluções
como 1254 × 1254 e 1536 × 1024. São provisórias e **não cumprem** a resolução de
produção só por serem exibidas pequenas com filtro nearest.

O pacote [sprites completas para edição](arte/sprites-completas-para-aseprite.zip)
preserva os arquivos atuais e inclui recortes e exportações do renderizador.
Não redimensiona ou redesenha as imagens: o proprietário fará o acabamento no
Aseprite e devolverá os arquivos. Veja o LEIA-ME e os manifestos dentro do ZIP.

A grade lógica do jogo continua em 40 unidades nesta entrega. Não confundir
unidades da simulação, zoom da câmera, tamanho do PNG e tamanho de um frame.
Esta atualização apenas registra a diretriz e exporta a arte. Na integração
dos arquivos editados, atualizar atlas, frames, pivôs e recursos TileSet, e
validar escala/colisões. Não reduzir a grade da simulação ou reescrever
salvamentos automaticamente junto com a troca de imagens.
