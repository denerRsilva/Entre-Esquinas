# Limpeza de arquivos — 18/11/2026

Base: `090eac49287a956a189323fc700c08dacccd488d`. A limpeza conserva a arte
utilizada, cenas, scripts de execução, partidas, fixtures de testes e APKs atuais.
O [manifesto](limpeza-arquivos.json) registra cada arquivo retirado ou movido,
seus tamanhos, SHA-256 e a fonte preservada ou commit de recuperação.

## Arquivos retirados da revisão atual

- **APK duplicado:** `EntreEsquinas-gdscript.apk` era byte a byte igual a
  `EntreEsquinas.apk`: 92,01 MiB. Mantidos o universal e o ARM64 com seus checksums.
  README, instruções e links atuais agora apontam para os dois arquivos únicos.
- **ZIP gerado de sprites:** 51,50 MiB. Todas as 37 fontes do pacote anterior
  foram conferidas contra seus arquivos originais antes da retirada. O ZIP e
  seu checksum saíram da revisão atual; a entrega anterior permanece acessível
  pelo histórico. Os scripts foram atualizados e o pacote foi recriado com
  sucesso após a reorganização: 39 fontes e 722 recortes/renderizações.
- **Nove cópias de arte e três capturas duplicadas:** removidas após comparação
  SHA-256 com as fontes mantidas. Nenhuma imagem única foi excluída. Links e
  ferramentas usam a fonte única; cópias pequenas com funções distintas no
  TileSet foram mantidas, mesmo quando têm pixels iguais.
- **Assinaturas auxiliares e caches órfãos:** 9,29 MiB locais. Removidos apenas
  `.idsig` regeneráveis e as texturas importadas/checksums das dez fontes movidas.

Os arquivos redundantes e gerados somavam **154,84 MiB**, aproximadamente
**42,15%** dos 367,33 MiB rastreados antes. A revisão resultante fica em cerca
de **212,5 MiB**, incluindo os dois APKs. Esses números não incluem o histórico
Git nem caches locais. Remover arquivos da revisão não apaga versões antigas.

## Fontes fora de `res://`

As dez pranchas que a .55 já excluía das exportações foram movidas para
[fontes-preservadas](arte/fontes-preservadas/LEIA-ME.md): **9,79 MiB**. Os bytes
dos originais foram conferidos antes e depois. A Godot deixa de importá-los;
as ferramentas de extração e o teste do atlas compacto usam o caminho externo.
As regras de exclusão dos caminhos antigos continuam protegendo as exportações.

Mover esses originais não reduz por si só o tamanho total das fontes, pois
continuam preservados. Reduz o conteúdo da pasta Godot de cerca de 48,17 para
38,36 MiB rastreados, além de evitar os caches dessas imagens.

## Proteção contra novo acúmulo

O `.gitignore` da raiz ignora assinaturas `.idsig`, o antigo alias de APK e
o ZIP completo gerado na localização antiga. A exportação de sprites passa a
gravar em uma pasta temporária por padrão, com destino opcional.
[Como gerar o pacote](arte/EXPORTAR-SPRITES.md).

Os APKs universal e ARM64 ainda somam aproximadamente 129,68 MiB; são produtos
disponíveis para download. As fixtures de migração e imagens únicas de referência
foram mantidas porque têm função de validação ou documentam decisões de arte.
Não foram removidos variantes de arte locais sem rastreamento, saves, SDKs,
outros worktrees ou referências históricas do proprietário.

## Validação

- Importação do editor Godot 4.6.3 concluída após retirar os caches antigos.
- `AtlasCompacto`, `BarrasAnimadasUI` e `CatalogoSecoesUI`: zero falhas.
- Exportação gráfica de sprites e empacotamento ZIP concluídos; integridade e
  correspondência das fontes verificadas pelo empacotador.
- Verificadores de arte e migração passaram. Os SHA-256 de todas as fontes
  preservadas e imagens mantidas no lugar das duplicatas foram conferidos.
- Nenhum script de execução, cena ou imagem usada foi alterado. A única mudança
  em QA adapta a comparação à fonte PNG externa, sem a correção RGB aplicada
  pela importação da Godot em pixels transparentes.

Os dois APKs .55 continuam byte a byte iguais aos publicados: esta limpeza não
muda o jogo instalado e não exige nova compilação. A redução desta revisão é
do projeto e de arquivos locais; não se apresenta como novo ganho de FPS/RAM ou
redução adicional do APK. Não houve teste em Android físico nesta limpeza.

## Compactação local do Git

Dezesseis objetos grandes soltos ocupavam 998,49 MiB. Foram armazenados em um
pack de 158,39 MiB, liberando **840,11 MiB** no armazenamento local.
`git verify-pack` validou o conteúdo antes de remover apenas as cópias soltas;
`git cat-file` confirmou o acesso depois. Branches e referências foram
comparadas e preservadas. Não houve reescrita de histórico nem force push.

Essa manutenção compacta o Git local compartilhado pelos worktrees. As exclusões
da revisão atual reduzem o checkout e downloads do código dessa revisão; clones
com todo o histórico ainda trazem versões antigas. Migrar os APKs futuros para
Releases pode evitar novo acúmulo, mas não foi feito nesta limpeza.
