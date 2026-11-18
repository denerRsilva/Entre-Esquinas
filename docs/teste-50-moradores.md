# Experimento .56 — população inicial de 50 moradores

Pedido de 18/11/2026: começar com cinquenta moradores para avaliação pelo
proprietário, sem recalibrar o restante do jogo. A recomendação anterior de
começar com doze não foi aplicada. As artes ficaram fora deste trabalho.

Escolha **Novo jogo** para testar a população inicial de cinquenta. Confira em
**Gestão → Cidade**. Carregar uma partida anterior mantém sua população e seu
progresso; não injeta novos habitantes nem reinicia a economia. O slot único e
seus backups continuam funcionando como antes.

São cinquenta identidades na população do refúgio, disponíveis para o fluxo
normal de visitas. Os três NPCs permanentes da rua continuam os mesmos; não
foram colocados cinquenta atores simultâneos no mapa. As sprites existentes
são reutilizadas. Os seis primeiros nomes foram mantidos; os demais recebem
identificadores provisórios, de “Morador 07” a “Morador 50”.

## Mudança técnica necessária

A população inicial fica registrada em `refuge.initialPopulation`, sem mudar a
versão externa12 do salvamento nem a versão2 dos status coletivos. A ausência
desse campo identifica os saves anteriores, de base três. A validação aceita
as bases3 e50 e mantém a relação população = base + nível de reconstrução.

O código anterior só tinha seis nomes, validava IDs até seis e aceitava até
12 registros de visita. Esses limites foram adaptados para os cinquenta
moradores e até duas visitas por pessoa/dia. A contratação continua validando
que a pessoa escolhida existe, inclusive quando o ID supera seis.

A recompensa de crescimento continua sendo um novo morador nas primeiras três
vitórias, até o terceiro nível: 50→51→52→53 na campanha nova, e 3→4→5→6 nas antigas.
Salvar e carregar preserva a base e a quantidade, incluindo durante a horda.

## Regras mantidas

Dinheiro200, duas mesas/oito cadeiras, duas panelas/oito pratos, estoque inicial,
estoque limitado do mercador, receitas e seus tempos/custos/rendimento, velocidades,
preços e orçamentos, horário e duração dos turnos, fórmulas de alimentação e moral,
status iniciais, primeira horda no dia3 e regras de vitória/derrota não mudaram.
O intervalo de chegada continua usando a fórmula existente e sua faixa28–50s.

A população maior produz os efeitos naturais dessas regras. Por exemplo, a
mesma fórmula de intervalo passa a resultar em28s, e o ganho de alimentação
por caldo consumido passa a 8/50. A contratação continua liberada com quatro
moradores e custo100; portanto, uma nova campanha de cinquenta já atende ao
requisito e oferece candidatos. Ninguém é contratado automaticamente.

## Verificação

`Populacao50UI` percorre o novo jogo real, a Cidade e a lista rolável de
contratação, inclusive contratar o morador50. Verifica chegada e anotação do
morador50, persistência de IDs altos e de cem registros de visita, compatibilidade
com a campanha anterior e crescimento até o limite dos três níveis.

Os cenários antigos de contratação inicialmente bloqueada e de almoço com três
clientes continuam usando explicitamente uma campanha de base três. Eles são
regressões históricas de interação; não representam um playtest de equilíbrio
da nova população. O teste específico cobre a base50 sem mudar suas regras.

Os APKs universal e ARM64 da .56 são destinados ao teste solicitado. Assinatura,
versão e checksums são conferidos na exportação. Não houve teste em aparelho
Android físico; a avaliação de ritmo fica com o proprietário.

Validação em Linux/Godot 4.6.3: passaram Populacao50UI, EquilibrioNativo,
CidadeUI, ContratacaoUI, InicioUI, MenuInicialUI, RefugioUI, EquilibrioUI,
PlaytestDoZeroUI, SalvamentoDiscoNativoUI e AuditoriaRegressoes. Verificadores
de migração e arte também passaram. Não é uma declaração de equilíbrio final.

## APKs publicados

Versão0.21.2-godot.56, Android21256. [Universal](../build/Android/EntreEsquinas.apk)
(92,01 MiB) e [ARM64](../build/Android/EntreEsquinas-arm64.apk) (37,68 MiB),
com a mesma assinatura anterior. [Metadados e hashes](teste-50-moradores-apks.json).
A integridade ZIP, assinatura e versão foram verificadas; as texturas e bibliotecas
do motor são idênticas às da .55, sem JavaScript nem QA nos pacotes. Os assets
de execução são idênticos entre as variantes.

`Populacao50UI` também passou com zero falhas sobre os assets extraídos do APK
universal, acrescentando apenas os quatro scripts do harness de teste ao
diretório temporário. Nenhum script compilado ou textura do pacote foi trocado.
Esse ensaio confirma o conteúdo exportado no Linux, sem substituir teste em
Android físico ou a avaliação de dificuldade pelo proprietário.
