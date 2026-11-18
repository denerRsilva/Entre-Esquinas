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

O pacote [sprites completas para edição](https://github.com/denerRsilva/Entre-Esquinas/blob/090eac49287a956a189323fc700c08dacccd488d/docs/arte/sprites-completas-para-aseprite.zip)
preserva os arquivos atuais e inclui recortes e exportações do renderizador.
Não redimensiona ou redesenha as imagens: o proprietário fará o acabamento no
Aseprite e devolverá os arquivos. Veja o LEIA-ME e os manifestos dentro do ZIP.

A grade lógica do jogo continua em 40 unidades nesta entrega. Não confundir
unidades da simulação, zoom da câmera, tamanho do PNG e tamanho de um frame.
Esta atualização apenas registra a diretriz e exporta a arte. Na integração
dos arquivos editados, atualizar atlas, frames, pivôs e recursos TileSet, e
validar escala/colisões. Não reduzir a grade da simulação ou reescrever
salvamentos automaticamente junto com a troca de imagens.

## Reformulação iniciada em 18/11/2026

O pacote Epic RPG World — Village Interiors V1.3 foi analisado como referência
**de escala e organização**, sem copiar sua arte. 867 dos 869 PNGs estão em
múltiplos de 32. Apenas 301 são 32×32: móveis maiores usam 32×64, 64×64, 64×96 etc.
**32px é a unidade, não o tamanho obrigatório da folha inteira ou de cada móvel.**

Usar o primeiro [kit original nativo](arte/kit-taverna-nativo-32px.zip), com
[cena editável](arte/escala32/kit/project.godot), como base técnica da reformulação.
Desenhar no tamanho final, não criar pranchas de 1500px e reduzi-las depois.
Personagens mantêm o frame 32×32 definido para o projeto; folhas 4×4 terão 128×128.

| Elemento | Canvas de produção inicial |
|---|---|
| Piso, segmento de parede, ícone e ingrediente | 32×32 |
| Parede alta | composição de duas células 32×32 |
| Cadeira e tábua | 32×32 |
| Geladeira | 32×64 |
| Mesa, fogão e pia | 64×64, compostos por células 32px |
| Personagem com 16 quadros | atlas 128×128 de frames 32px |

Planejar pivô, base no chão e área de interação separadamente da parte alta da
arte. Não girar a frente sombreada junto com o tampo: criar vistas apropriadas.
Usar atlas compactos, sem cópias grandes ou áreas transparentes desnecessárias.
Um atlas maior pode ser legítimo se seus elementos tiverem densidade nativa;
o atlas comprado de UI, 1952×1376, é um exemplo válido de células 32px.

Rodar `python3 scripts/verificar-arte.py`. A verificação confere canvases
registrados e exige classificar novos PNGs de produção; não prova sozinha a
qualidade/densidade do desenho. Exceções legadas ficam explícitas no registro
até serem redesenhadas e integradas com validação visual.

Os originais permanecem preservados. A migração artística será por lotes:
base arquitetônica/mobiliário → utensílios/alimentos → personagens/animações →
rua/decoração/interface restante. Conferir encaixes a 1× e em cena antes de
substituir referências, recortes e pivôs. Não alterar o save junto com a arte.
