# Reformulação da arte e do peso — .55

18/11/2026. Referência: Epic RPG World — Village Interiors V1.3, enviada pelo
proprietário para estudar escala e organização. A arte comercial não foi copiada
nem adicionada ao repositório. O jogo conserva sua paleta/direção própria.

## O que o pacote ensina

O ZIP tem 869 PNGs, contando atlas, variações, animações e mockups. 867 estão em
múltiplos de 32. Há 301 imagens 32×32, 217 de 64×64 e 83 de 32×64, entre outros
tamanhos. O conjunto de arquivos descompactados soma aproximadamente 1,83MiB.

**32×32 é a unidade de construção, não uma exigência de que todo móvel ou atlas
seja uma imagem 32×32.** Uma geladeira pode usar duas células; uma mesa, quatro.
Um atlas de 2048px também pode ser correto se reunir tiles nativos, sem cada
objeto ser uma pintura ampliada. As folhas de animação multiplicam as células
por quadros e podem incluir margem para efeitos.

No nosso projeto, por exemplo, há uma mesa em 1439×1093 e um prato em 1499×1049,
para elementos exibidos pequenos. Isso aumenta textura carregada, recortes,
importação e dificulta coesão. `nearest` evita suavização, mas não transforma
essas fontes em pixel art nativa. Os originais continuam preservados.

## Diagnóstico medido

[Inventário e APK antes](medicao-antes.json). Os 34 PNGs rastreados de produção
somam 24,69MiB em arquivo. A soma teórica de suas imagens em RGBA8 é 156,30MiB;
não representa o consumo residente simultâneo nem inclui todos os custos da
GPU/engine. Não comparar diretamente quantidade de arquivos com conteúdo único:
o pacote de referência também inclui versões/atlas que duplicam elementos.

O APK .54 tinha 99,52MiB. Suas entradas comprimidas se dividiam em:

| Grupo | MiB aproximados |
|---|---:|
| Motor/bibliotecas ARM64 | 24,03 |
| Motor/bibliotecas ARM32 | 27,47 |
| Motor/bibliotecas x86_64 | 26,86 |
| Texturas | 18,32 |
| Outros | 2,77 |

Portanto, arte é um problema real, mas quase 79% do download vinha de distribuir
três arquiteturas da Godot juntas. Reformular a arte não fará esse motor virar
um APK de 2MiB. Também não é correto afirmar que excluir uma textura já não usada
reduz memória de execução: isso reduz pacote, não uma alocação que não existia.

O histórico Git ainda conserva APKs e revisões antigas. Isso também pesa no clone,
separadamente do jogo. Nenhum histórico foi apagado; para distribuição futura,
Releases podem substituir o acúmulo de binários no Git, preservando acesso fácil.

## Reduções aplicadas agora

1. **Barras com atlas compacto, sem mudança visual.** O jogo carregava a folha
   Modern UI inteira, 1952×1376, para usar somente sete regiões pequenas. Elas
   foram copiadas pixel a pixel para `barras-compactas-32.png`, 128×32. Não houve
   redução, nova interpolação ou redesenho do asset comprado. O original continua
   como fonte. A comparação verifica cada pixel e alpha dos sete recortes.
2. **Exclusão de fontes/estudos completos sem dependências de execução.** Dez
   arquivos permanecem no repositório e saem apenas dos pacotes exportados.
   [Lista exata](excluidos-exportacao.json). O validador reprova referências de
   execução reintroduzidas sem revisar as exclusões.
3. **Preset Android ARM64 adicional.** Destinado a celulares Android ARM64,
   mantém pacote, versão e assinatura. A versão universal continua com ARM32,
   ARM64 e x86_64; o suporte não foi removido silenciosamente.
4. **Registro para impedir a repetição do problema.** O validador distingue
   canvases nativos declarados de exceções históricas. Imagens de produção novas
   precisam de dimensões/grade registradas. Dimensões sozinhas não provam qualidade
   ou densidade; revisar o desenho a 1× continua obrigatório.

### Memória de texturas observada

Em dois processos separados, com dados isolados, mesma janela 1280×720 e campanha
recém-aberta/pausada, o monitor `Performance.RENDER_TEXTURE_MEM_USED` passou de
**147,68MiB para 134,04MiB**, economia de **13,64MiB**. Godot 4.6.3 Compatibility,
Mesa llvmpipe, Linux/Xorg. [Registro](memoria-texturas.json).

Isso é o monitor de alocação de texturas da Godot, não RAM total/RSS do processo
ou medição Android. O tamanho RGBA8 básico da folha das barras passa de 10,25MiB
para 16KiB; o monitor pode incluir custos adicionais da representação gráfica.
O restante das grandes texturas ainda precisa da migração artística.

## Primeiro lote de arte original nativa

[Baixar kit](../kit-taverna-nativo-32px.zip) · [Prévia ampliada](kit/previa-3x.png).

- 16 células originais de piso, parede e detalhes, 32×32 cada.
- Atlas de arquitetura 128×128, com madeira, cozinha, segmentos, canto e janela.
- Mesa de trabalho e jantar com a mesma base; fogão e pia: 64×64.
- Geladeira: 32×64. Cadeiras e tábua: 32×32.
- Ferramenta separada da mesa. Sem comida ou quantidade de pratos embutida.
- Fonte reproduzível que desenha diretamente no canvas final; sem reduzir a
  prancha conceitual gerada na conversa.
- Somente 10.056 bytes de PNGs de produção, incluindo atlas e células individuais
  duplicadas para edição. Para o jogo final, enviar só os atlas/texturas usados.

O ZIP inclui um **projeto Godot independente**, com `Amostra.tscn` e
`PisosParedes.tres`: piso e paredes são TileMapLayer editáveis no editor, com
célula 32px. Objetos são Sprite2D separados. Manifesto registra canvas, pivô e
base de ocupação. Não é necessário reconstruir a sala por código para pintá-la.

É o primeiro lote técnico/visual para avaliar escala, materiais e encaixes.
**Ainda não é a substituição integral da arte da sala jogável.** Personagens,
Piskel, rua e parte dos objetos atuais permanecem nas fontes antigas. Isso evita
misturar troca de recortes, animação, física e saves numa substituição em massa.
O ganho de memória das barras e a redução dos pacotes já valem no jogo .55.

## Padrão de produção daqui em diante

| Item | Canvas inicial | Observação |
|---|---|---|
| Piso e módulo de parede | 32×32 | Testar repetição e cantos em cena |
| Parede alta | 32×64 | Duas células, mesma densidade |
| Ingrediente/ícone/frame de personagem | 32×32 | Folha 4×4 resulta em 128×128 |
| Geladeira | 32×64 | Pivô nos pés, base no chão separada |
| Mesa/fogão/pia | 64×64 | 2×2 células; ocupação pode ser 2×1 |
| Ferramenta sobre a mesa | 32×32 | Sobreposição separada |
| Atlas | Preferir 256/512px conforme conteúdo | Não duplicar fontes/prévias no build |

Exemplos teóricos: uma mesa 64×64 ocupa 16KiB RGBA8; folha de personagem 128×128,
64KiB. A mesa antiga de 1439×1093 representa cerca de 6MiB RGBA8. O ganho final
depende de integrar arte nova e retirar dependências antigas, não apenas criar
arquivos menores ao lado dos antigos.

A grade lógica do jogo continua 40 unidades para preservar mapas e salvamentos.
Unidade do desenho, escala de exibição, footprint e resolução da janela são
coisas diferentes. Não alterar valores de save para resolver tamanho de textura.

Sequência proposta de integração: arquitetura/mobiliário → utensílios/alimentos
→ personagens/animações → rua/decoração/interface restante. Conferir perspectivas,
conexões, pivôs e leitura a 1× em cada lote. O novo kit e as regras já estão
prontos para essa continuação; o trabalho de redesenhar todo o acervo não está
sendo apresentado como concluído nesta entrega.

## Reprodução e validação

```
python3 scripts/auditar-arte.py --pack /caminho/pacote.zip --out /tmp/medicao.json
python3 scripts/verificar-arte.py
scripts/testar-migracao.sh AtlasCompacto BarrasAnimadasUI ComandasUI AnotarPedidosUI
XDG_DATA_HOME=/tmp/medicao-isolada godot --path godot \
  --rendering-method gl_compatibility --script /caminho/scripts/medir-texturas.gd
```

Foram verificadas as sete suítes específicas: AtlasCompacto, BarrasAnimadasUI,
ComandasUI, AnotarPedidosUI, EquilibrioUI, PlaytestDoZeroUI e CatalogoSecoesUI.
O kit importa, abre e valida seu TileSet 32px, 96 células de piso e dimensões dos
objetos. Original comercial não integra o ZIP. Não houve teste em telefone físico.
Os resultados finais de exportação são registrados junto dos APKs abaixo.


## Exportação .55 concluída

| Pacote | Tamanho | Comparação com .54 universal |
|---|---:|---:|
| .54 universal anterior | 99,52 MiB | referência |
| .55 universal, três arquiteturas | 92,01 MiB | −7,55% |
| .55 ARM64 | 37,68 MiB | −62,14%, também por distribuir só ARM64 |

A redução de 99,52 para 92,01 MiB vem da limpeza de texturas; a diferença
adicional do ARM64 vem das bibliotecas do motor não distribuídas nessa variante.
As entradas comprimidas de texturas caíram de 18,32 para 10,82 MiB.
[Inventário depois](medicao-depois.json) e [hashes/arquiteturas](apks-verificados.json).

Na sala de refúgio recém-iniciada e pausada, janela 1280×720, o monitor de
memória de texturas da Godot caiu de **147,68 para 134,04 MiB**, diferença de
**13,64 MiB**. Medição em processos separados, após 25 quadros, Godot 4.6.3,
Compatibility/Mesa llvmpipe no Linux. Não é RAM total do processo nem uma medição
em telefone. [Registro do ensaio](memoria-texturas.json). O atlas das barras tem
16KiB RGBA8 teóricos; a alocação reportada pelo motor inclui sua representação
importada e custos adicionais.

Os dois APKs passaram na verificação ZIP e de assinatura v2/v3, conservando
exatamente o certificado da .54. Ambos são versão 21255. As três bibliotecas
nativas da universal são idênticas às anteriores; ARM64 contém somente sua
arquitetura. Todos os assets do jogo são idênticos entre as duas variantes.
Dez texturas excluídas foram conferidas pelo nome exato, as demais texturas
anteriores mantêm os hashes e o atlas compacto é a única textura nova no APK.
Não há JavaScript nem QA nos pacotes.

Além dos testes de fonte, os assets reais do APK universal foram extraídos para
um diretório temporário. Somente o harness QA foi acrescentado, sem substituir
scripts compilados, projeto ou texturas do pacote. O PlaytestDoZeroUI passou com
zero falhas: novo jogo, anotação, preparo/empratamento, atendimento, limpeza,
almoço e mercador. CatalogoSecoesUI também passou com zero falhas nos assets
exportados, conferindo o catálogo. Isso verifica as dependências da exportação no Linux; não
substitui instalação e playtest em Android físico.

Downloads: [ARM64](../../../build/Android/EntreEsquinas-arm64.apk),
[universal](../../../build/Android/EntreEsquinas.apk) e
[kit editável de arte](../kit-taverna-nativo-32px.zip).
