# Novos alimentos — proposta em 32 × 32

Cada PNG individual tem **32 × 32 pixels reais**, RGBA e fundo transparente.
Os pixels são opacos ou transparentes, sem suavização. Desenhos construídos
na grade de 32px; não são reduções dos atlas ampliados do jogo.

A prancha gerada na conversa serviu como referência. Esta versão foi finalizada
em células reais de 32px, com paleta compartilhada de até 28 cores e contornos
de um pixel, para manter a leitura nessa resolução.

## Arquivos

- `batata.png`: inteira.
- `batata_cut.png`: pedaços cortados.
- `cenoura.png`: inteira.
- `cenoura_cut.png`: rodelas.
- `caldoBatata.png`: caldo de batata.
- `arrozCenoura.png`: arroz com cenoura.
- `canja.png`: canja de frango com arroz e cenoura.
- `prato_vazio.png`: base extra para manter a louça consistente.
- `spritesheet.png`: 128 × 64, quatro colunas e duas linhas, sem espaçamento.
- `previa-8x.png`: ampliação exata a 800%, somente para visualizar.
- `manifesto.json`: IDs e retângulos de cada célula.
- `fonte.gd`: fonte reproduzível; pinta diretamente em imagens 32 × 32.

Ordem do atlas, da esquerda para a direita:

| Linha | Coluna 1 | Coluna 2 | Coluna 3 | Coluna 4 |
|---|---|---|---|---|
| Superior | Batata | Batata cortada | Cenoura | Cenoura cortada |
| Inferior | Caldo de batata | Arroz com cenoura | Canja | Prato vazio |

No Aseprite/Piskel, abra o PNG ou importe a spritesheet com células de 32 × 32.
Use filtro nearest ao ampliar. PNGs não possuem camadas; `fonte.gd` mantém a
construção e a paleta editáveis por código.

Para reproduzir com Godot 4.6.3:

```
godot --headless --script /caminho/fonte.gd -- /pasta/de/saida
```

A fonte grava os PNGs no próprio diretório quando não recebe uma pasta de saída.
As sprites estão separadas dos atlas atuais; sua criação não substitui os
arquivos originais do jogo nem altera recortes, cenas ou salvamentos.
