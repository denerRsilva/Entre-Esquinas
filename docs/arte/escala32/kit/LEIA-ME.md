# Primeiro lote nativo — taverna em grade 32px

Abra `project.godot` desta pasta na Godot 4.6.3. A cena `Amostra.tscn` contém
**Piso32 e Paredes32 como TileMapLayer**, com TileSet real de 32×32, editáveis
pelo pincel no editor. Os móveis são Sprite2D separados.

Arte original do projeto; não contém arquivos do pacote comercial de referência.
A prancha conceitual gerada na conversa não foi reduzida para produzir estes PNGs:
`fonte.gd` desenha diretamente nas dimensões finais, com paleta compartilhada.

- `tileset.png`: 128×128, 16 células de 32×32. Madeira, cerâmica, parede superior
  e inferior, corte lateral/frontal, canto, soleira, janela e tijolos.
- `tile_00.png` a `tile_15.png`: células individuais para edição no Aseprite.
- Mesas de trabalho/jantar, fogão e pia: 64×64, compostos por 2×2 células.
- Geladeira: 32×64, uma coluna e duas células.
- Cadeiras e tábua: 32×32.
- `amostra.png`: composição em 448×320 pixels reais.
- `previa-3x.png`: somente ampliação nearest a 300%, não textura de produção.
- `manifesto.json`: tamanhos e posições.

As duas mesas usam a mesma base. A tábua é uma peça separada; nada é embutido
como receita, estoque ou prato. Escala nativa 1:1, sem suavização, mipmaps ou
textura ampliada escondida em Sprite2D pequeno. O TileSet reutiliza a mesma
textura para todas as células.

Este é o **primeiro lote técnico/visual para reformulação**, em cena separada.
Não substitui de uma vez os personagens, bancadas do Piskel ou a sala jogável.
A grade de simulação de 40 unidades e os salvamentos do jogo permanecem iguais;
a demonstração mostra a nova arte em unidades visuais de 32px.

Para reproduzir:

```
godot --headless --path /caminho/kit --script fonte.gd
godot --headless --path /caminho/kit --editor --import --quit
godot --headless --path /caminho/kit --script montar.gd
```

As imagens de produção somam cerca de 10KiB, incluindo atlas e cópias individuais.
Para integrar, enviar somente atlas/texturas efetivamente usados, não também
cópias soltas e prévias. Os arquivos `.godot/` são cache local e ficam fora do ZIP.
