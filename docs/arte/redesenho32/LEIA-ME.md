# Redesenho em pixels de 32px

Este é o **novo acervo desenhado no tamanho final**, usando a direção aprovada e
as artes existentes como referência visual. Contém **135 PNGs individuais**,
incluindo nove folhas de personagens com 144 quadros no total. As artes antigas
não foram reduzidas para produzir estes arquivos.

**Amostra separada: ainda não substitui as referências da sala jogável nem o APK.**
A integração precisa acompanhar recortes, SpriteFrames, pivôs e escala; não se
resolve sobrescrevendo as antigas folhas ampliadas.

## Abrir e editar

Abra `project.godot` desta pasta com Godot 4.6.3 e execute `Amostra.tscn`.
`Piso32` e `Paredes32` são **TileMapLayer reais**, com o TileSet `Taverna32.tres`,
19 módulos e células 32×32. Móveis e utensílios são Sprite2D independentes;
cozinheira, garçom e cliente usam AnimatedSprite2D com SpriteFrames reais.
A cena demonstra a arte e não implementa a simulação do restaurante.

Os PNGs individuais estão em `png/`, separados por categoria, e abrem no
Aseprite/Piskel. Não existem arquivos `.aseprite` anteriores: as fontes desta
entrega são os PNGs, a paleta e o desenho reproduzível em `fonte.gd`.

| Categoria | Arquivos |
|---|---:|
| Móveis | 17 |
| Utensílios | 13 |
| Ingredientes inteiros e cortados | 9 |
| Receitas | 6 |
| Ícones | 14 |
| Interface | 2 |
| Decorações | 15 |
| Porta/janela | 2 |
| Exterior | 12 |
| Tiles | 19 |
| Peças de bancada | 16 |
| Personagens | 9 folhas |
| Objeto legado | 1 |

## Unidade, conteúdo e escala

- Prato, panela, alimento, ferramenta e cadeira: **canvas 32×32**. O desenho pode
  ocupar menos pixels dentro dele; a margem não é parte física do objeto.
- Geladeira fechada e porta/janela: **32×64**, duas células.
- Fogão, pia e mesas: **64×64**, quatro células. Geladeira aberta usa 64×64 para
  acomodar a porta aberta sem achatar a forma.
- Personagens: folha **128×128**, quatro direções e quatro quadros por direção,
  todos **32×32**. Ordem das linhas: baixo, esquerda, direita, cima. Os pés
  permanecem na mesma linha durante a caminhada.
- Árvore: 64×96; tapete: 96×64; outros objetos seguem múltiplos de 32.
- A grade lógica dos saves do jogo continua em 40 unidades. Ela não foi alterada.

`manifesto.json` traz tamanho, recorte opaco, pivô, categoria e base no chão de
cada peça. A pegada ali é uma indicação artística para integração, não uma
migração de colisões/saves. Pratos na mão e sobre superfícies devem compartilhar
escala e tamanho físico; o canvas transparente não deve esticar a louça.

A mesa vazia é a base comum de preparo/empratamento. A tábua e a faca são um kit
separado; não há pano nem pratos fixos na base do empratamento. Pratos limpos,
receitas e panelas são camadas independentes. Repetir o prato limpo conforme o
estoque real, não usar uma imagem que invente três pratos. A estante vem vazia.
As panelas e pratos da amostra são sobreposições explícitas da demonstração.

## Bancadas

Duas famílias, fina e grossa, cada uma com oito peças: esquerda, meio horizontal,
direita, topo vertical, meio vertical, base, quina esquerda e quina direita.
Os encontros compartilham portas na mesma grade. Topo/meio vertical usam 32×32;
as peças com frente usam 32×64. `previas/conexoes-nativas.png` demonstra junções
em L sem frestas. As peças do Piskel anteriores permanecem intactas no jogo.

## Peso e procedência

Os **135 PNGs individuais somam 65.555 bytes, aproximadamente 64 KiB**. A soma
teórica de seus canvases RGBA8 é 1.409.024 bytes (1,34 MiB); isso não é uma
medição de RAM em execução. O TileSet usa o pequeno `tileset-32.png` montado
com os tiles individuais. Nenhum arquivo comercial do pacote de referência
foi copiado. O computador é uma arte de compatibilidade identificada como legado,
sem reintroduzir tecnologia ou mecânica na campanha atual.

`fonte.gd` desenha os novos pixels em canvases vazios usando coordenadas inteiras
e paleta limitada, sem carregar nem amostrar os PNGs antigos. A imagem gerada
na conversa serviu de referência visual; não foi reduzida para compor este kit.
A ampliação nearest aparece apenas em `previas/`, que tem `.gdignore` para não
ser importada como textura de produção pela Godot. Os originais do jogo seguem
preservados nos seus caminhos atuais/arquivo de fontes.

## Reproduzir e conferir

Dentro desta pasta:

```sh
godot --headless --path . --script fonte.gd
godot --headless --path . --editor --import --quit
godot --headless --path . --script montar.gd
godot --headless --path . --script verificar.gd
```

A verificação confere dimensões, transparência binária, paleta por peça, silhueta
comum dos pratos, encontros das bancadas, 144 frames e seus pés alinhados, TileSet
e cena editável. Houve também renderização da amostra no Linux com Compatibility.
Não é um playtest da campanha nem teste de desempenho do Android.

O mapa de tamanhos em `../escala32/tamanhos-planejados.json` relaciona os 68
recortes/grupos inicialmente inventariados às novas peças, com estado explícito
**redesenhado disponível, ainda não integrado**. O conjunto é uma primeira revisão
visual completa dessas categorias; a comparação e integração no jogo ainda
precisam respeitar as animações, superfícies e conexões em uso.
