# Apenas o fogão — estudo 3

Um único desenho de fogão aceso, em **64×64 pixels reais**, composto por quatro
blocos de 32×32: dois em cima e dois embaixo. Nenhum outro móvel foi redesenhado
ou substituído nesta revisão. Este estudo não está instalado na sala jogável.

- `fogao-64.png`: sprite completa, com fundo transparente e sem grade.
- `bloco-1.png` e `bloco-2.png`: superior esquerdo e superior direito.
- `bloco-3.png` e `bloco-4.png`: inferior esquerdo e inferior direito.
- `previas/fogao-grade-32-8x.png`: ampliação a 800% com linhas dividindo os blocos.
- `previas/fogao-ampliado-8x.png`: mesma ampliação sem a grade.
- `desenhar.gd`: fonte do desenho, com clusters de pixels nas posições finais.
- `manifesto.json`: canvas, coordenadas dos blocos, cores e transparência.

O topo esquerdo tem espaço vazio; não é preciso preencher o canvas todo. A
chaminé fica na parte de cima à direita. O tampo visto de cima tem duas bocas
elípticas de tamanhos diferentes; a frente contém a porta do forno, grelha,
dobradiças, puxador e porta de cinzas. A panela permanece um objeto separado.

Os quatro PNGs recompõem os 4096 pixels da sprite exatamente, sem diferença nas
junções. O desenho tem transparência binária e 17 cores. O PNG completo ocupa
1904 bytes. As prévias são apenas ampliações nearest, não texturas de produção.
A imagem conceitual apresentada na conversa serviu de referência; não foi
reduzida para gerar a sprite. Os pixels foram desenhados em um canvas vazio64.

Para reproduzir a partir da raiz do repositório:

```sh
godot --headless --path godot --script "$PWD/docs/arte/fogao-64-r3/desenhar.gd"
```

O pedido vigente é refinar poucas sprites por vez. Esta versão continua um
estudo visual para exame; dimensão válida e recortes corretos não significam
aprovação artística. Os originais e propostas anteriores foram preservados.
