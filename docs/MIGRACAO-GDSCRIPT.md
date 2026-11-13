# Migração para GDScript — em andamento

Referência funcional: commit 5ae8794, APK 0.21.2-godot.18.

## Implementado

A coordenação de frames antes feita por `snapshot` em `simulacao/sessao.js` passou para `simulacao/nativa/Sessao.gd`. `Restaurante.gd` usa diretamente essa sessão. Seleção das áreas da interface, montagem do pacote de renderização e coleta de gravações e sons são coordenadas em GDScript.

## Dependências ainda presentes

A sessão nativa ainda usa uma ponte temporária para as regras, eventos, composição gráfica e árvore de menus JavaScript. Não é uma conversão completa. QuickJS continua obrigatório. Os testes Node que chamavam `snapshot` precisam ser substituídos por testes Godot; não são mais executáveis contra o novo ponto de entrada.

Próximas unidades: regras e validação de estado/saves; navegação e movimento; cozinha e conservação de itens; serviço e economia; ações de interface; composição gráfica e eliminação do DOM simulado. Só remover a extensão nativa depois que não houver consumidores.

Preservar versão e estrutura dos saves, valores econômicos, velocidades, dimensões e posições dos móveis. Não publicar APK desta etapa como migração concluída.

## Progresso: criação de partidas nativa

`Partida.gd` cria partidas vazias e mobiliadas e seus inventários/atores. Configurações iniciais estão em JSON (dados, não código). A inicialização fornece cópias desses estados ao adaptador legado; `fresh` e `furnishedTest` já não implementam a criação em JavaScript. As regras seguintes ainda permanecem no motor antigo.

Referências congeladas em `qa/referencia-migracao/partidas.json`, obtidas antes de remover as implementações, cobrem as três plantas suportadas. `PartidaNativa.gd` compara todos os campos das partidas vazias/mobiliadas e verifica isolamento entre instâncias. A combinação singleRoom=true com compact=false não é um cenário mobiliado válido no original e segue recusada pelo adaptador.

Verificações: PartidaNativa, MaosUI, CatalogoModernoUI e Regras.cjs. O runner Node usa referências congeladas para criação; a equivalência da implementação GDScript é coberta separadamente pelo teste nativo. Migração e validação de saves antigos ainda em JavaScript; não declarar a parte 2 encerrada.

## Bases de mapa e inventário

`Mapa.gd`: geometria rotacionada, paredes, obstáculos e busca de caminhos sem cortar quinas. Paridade de paredes/obstáculos em 4.212 células nas três plantas. Rotas possuem apenas testes básicos; equivalência de desempate ainda não demonstrada. O movimento do jogo continua no legado.

`Inventario.gd`: limites de pilha, contagem, capacidade, adição e remoção. Comparação com 375 casos congelados do legado. A criação nativa de partidas usa o novo inventário para abastecer a geladeira e a geometria para conferir saída e posição inicial. Ações de transferência, preparo e construção continuam no JavaScript; estes módulos não encerram as partes 3 e 4.

## Auditoria de conclusão

Execute `python3 scripts/verificar-migracao.py` na raiz. O código de saída 1 indica dependências JavaScript/QuickJS ainda presentes. Esse verificador não substitui testes de gameplay e não está ligado automaticamente à exportação.

Status auditado: 6 arquivos JavaScript de produção, 2 consumidores GDScript da ponte, 1 GDExtension legada. Partes 5 (simulação/serviço/economia), 6 (interface completa) e 7 (remoção do legado e validação final) **não concluídas**. Partes 2–4 também continuam parciais. A branch é um trabalho em andamento; nenhum APK final da migração foi gerado.

Na auditoria, passaram novamente PartidaNativa, MapaNativo (4.212 células) e InventarioNativo (375 casos). Isso valida apenas os módulos cobertos, não o jogo inteiro em GDScript.

## Entrada nativa integrada

`Entrada.gd` agora decide o encaminhamento de cliques, valores de controles, mouse, teclado e perda de foco. `Sessao.gd` despacha os eventos em ordem antes do frame. A antiga função `input` foi removida de `sessao.js`. As ações finais dos widgets e os ouvintes de movimento ainda são endpoints JavaScript: esta alteração não encerra a parte 6 nem elimina QuickJS.

Validação: EntradaNativa (bloqueio modal, controles inexistentes/desabilitados, ordem abrir/Escape e valores literais), CatalogoModernoUI, MaosUI e MovimentoUI passaram. O teste de entrada revelou retorno `undefined` da ponte para menus fechados; a leitura agora normaliza esse valor para null.

## Apresentação nativa dos alimentos

`Alimentos.gd` centraliza atlas, recortes, cache de texturas e dimensionamento/posicionamento das sprites. `Tracos.gd` e `CatalogoUI.gd` usam esse módulo. O adaptador JavaScript apenas emite comandos de alimento; o cálculo de recorte e ajuste de tamanho foi removido de `comidas.js`. Nomes, decoração de texto e estrelas de qualidade ainda estão no legado.

AlimentosNativos compara 66 comandos com a implementação anterior, incluindo pratos/panelas, tamanhos distintos, espelhamento e coordenadas negativas. Resultado: zero diferenças. MaosUI também passou no fluxo completo de cozinha. Esta é uma etapa parcial da apresentação, não a conclusão da migração.

## Montagem dos menus em GDScript

`Menus.gd` substitui summary/firstArtwork/pack/section: constrói descrições de controles, identifica arte, opções e caminhos dos widgets. A sessão nativa registra os callbacks correspondentes após montar as áreas visíveis. `simulacao/sessao.js` foi removido da produção e do carregador. Um exportador temporário em `apresentacao.js` apenas transporta os nós do modelo legado; criação dos menus e callbacks continuam em JavaScript.

MenusNativos compara a saída com a referência anterior em boas-vindas, gestão, opções, receitas e construção. A comparação identificou labels opcionais que precisavam continuar ausentes; corrigido. Também passaram MaosUI e CatalogoModernoUI. Referência JavaScript de testes em `.txt` não é carregada pelo jogo.

## Obstáculos nativos integrados ao jogo

As decisões de parede e obstáculos fixos foram removidas do motor JavaScript. `Mapa.gd.obstacle_tables()` calcula as quatro combinações dos indicadores de planta e fornece uma grade somente de leitura ao adaptador. Construção, navegação e validação do legado agora consultam essa grade. O Node usa dados de referência congelados; MapaNativo compara os dados produzidos em Godot com essa referência, além das 4.212 células existentes.

Passaram MapaNativo, Regras.cjs e MovimentoUI. A busca de caminhos e a movimentação ainda executam no legado; não declarar o mapa/construção completamente migrados. Fora da grade, a consulta retorna parede, como no domínio inteiro usado pela simulação.

## Regras nativas chamadas durante a simulação

A ponte temporária expõe `NativeRule` para chamadas síncronas a `Regras.gd`. Isso permite retirar implementações executáveis do JavaScript sem trocar o estado inteiro nem perder as referências dos objetos. `Restaurante.gd` mantém viva a instância do dispatcher. A ponte foi recompilada para Linux, Windows e Android (arm64, arm32 e x86_64); execução validada em Linux, demais binários apenas compilados.

Agora passam pelo dispatcher GDScript: geometria de móveis (rect/cells/hit), proximidade, paredes e obstáculos, busca de caminhos, limites/contagem/capacidade/adição/remoção do inventário, horários padrão e sua validação/formatação, calendário, criação do relógio e reputação inicial/limites/faixas. O adaptador de inventário preserva a referência à lista original, inclusive quando chamada por um contêiner temporário. A ordenação do A* mantém desempate por inserção e cálculo em precisão dupla.

Referências anteriores congeladas em `qa/referencia-migracao/regras-legado.cjs` são usadas somente pelo runner Node. Não são carregadas na Godot nem exportadas. `RegrasNativas.gd` compara 904 casos por meio da ponte real. Passaram também MaosUI (incluindo migração do save final), MovimentoUI e CatalogoModernoUI. O teste RuaHorarioUI apresentava 7 falhas também no HEAD anterior: pressupunha jogador na porta, embora o início mobiliado o coloque na cozinha. Seu fixture agora posiciona o jogador na porta antes de testar a saída.

A migração permanece incompleta. Atualização dos atores, validação/migração geral de saves, construção, preparo/serviço e ações de menus ainda têm implementações JavaScript. A extensão temporária deve ser excluída somente depois de eliminar todos esses consumidores.

## Armazenamento e identificação das receitas nativos

`Armazenamento.gd` substitui as implementações JavaScript de localização/aceitação/capacidade dos móveis, slots de estações, contagem e qualidade de itens, sincronização dos contêineres, colocação e retirada de itens e capacidade/quantidade por setor. `Receitas.gd` identifica ingredientes combinados e calcula qualidade de lote, indicador de calor e custo/qualidade do plano de ingredientes. Os adaptadores do motor chamam esses módulos via a ponte existente. Resultados mutáveis são reconciliados preservando referências de objetos e listas já usadas por outras ações.

Validação: 3.920 casos de armazenamento e 110 de receitas/calor comparados à referência antiga pela ponte real. Apenas o valor visual de progresso do calor aceita tolerância absoluta de 1e-12, pois os serializadores escrevem diferentes quantidades de casas finais; rótulo e estágio continuam exatos. As operações de armazenamento são comparadas exatamente. Também passaram MaosUI, EstantePanelasUI e CatalogoModernoUI, com conservação de itens e migração do save final do fluxo de cozinha.

A investigação da estante confirmou duas falhas também na versão anterior. A ação Guardar recebia um argumento extra (`panel`) na posição de `disabled` e ficava desabilitada mesmo com item nas mãos. Corrigida a chamada e atualizado o teste para o rótulo atual `Guardar Panela`; retirar e devolver pelo mouse agora passa.

Ainda permanecem em JavaScript as ações e os temporizadores de preparo, empratamento e atendimento, movimentação dos atores, construção e validação/migração geral dos saves. Nenhum APK final de migração foi publicado nesta etapa.

## Conservação e qualidade na validação dos saves

`Conservacao.gd` substitui `foodConserved`, `equipmentConserved` e `mealsConserved`, contando ingredientes crus/cortados, entregas pendentes, recuperação, itens nas mãos, panelas, utensílios, pratos, refeições carregadas/servidas, pratos sujos e a panela em preparo. `Qualidade.gd` substitui `validQuality`, verificando faixa e tipo de qualidade, marcação de queimado, distribuições de qualidade do recebimento/pratos e metadados dos lotes prontos.

Os quatro adaptadores do motor passam a chamar essas implementações GDScript, inclusive durante `valid` e `migrateSave`. Não houve mudança de versão do save. A validação geral e a transformação entre versões de saves continuam no JavaScript.

ConservacaoNativa compara 834 estados/regras de conservação e 84 casos de qualidade com a referência congelada (918 comparações no total), incluindo alterações de contadores, itens nas mãos, corte, recuperação, refeições carregadas, clientes comendo, panelas ocupadas, pratos sujos e metadados inválidos de qualidade. MaosUI passou no fluxo completo até empratar, pegar prato e validar/migrar o estado final. Regras.cjs também passou; seu motor de referência permanece restrito a QA.

## Conversão dos dados antigos da cozinha

`MigracaoSave.gd` executa conversão dos inventários antigos de fogão/mesa para encaixes, recolhimento dos antigos inventários de pia/lixeira, recuperação de excedentes, atualização da cozinha física e passagem da mochila/cargas para armazenamento e mãos. Os adaptadores reconciliam as alterações na cópia do estado criada pelo carregador. A escolha da versão de origem, inicialização de históricos v4/v5 e validação geral ainda são coordenadas em `migrateSave` JavaScript; portanto a migração de saves ainda não é inteiramente nativa.

`EstadoCozinha.gd` substitui `validKitchen` e `validPhysicalKitchen`: limites das estações, ingredientes, apoio, mãos, recuperação e coerência dos trabalhos de corte/empratamento. Quantidades, tempos e versão do save (12) foram mantidos. Casos em que o validador antigo lançava erro de tipo são rejeitados como inválidos pelo validador nativo, que retorna false.

MigracaoSaveNativa: 152 comparações, incluindo fases isoladas de migração, validação da cozinha e saves completos v9/v11, excedentes com armazenamento cheio, preservação de qualidade/porções, estados inválidos e igualdade do arquivo de entrada antes/depois. Casos v6 exercitam as fases de conversão dos inventários de estações, mas não constituem uma matriz completa de carregamento de todas as versões. MaosUI e Regras.cjs passaram. A comparação detectou a necessidade de tratar explicitamente a semântica de valores vazios, sem chamar o construtor bool com null.

## Sistema de movimento em GDScript

`Movimento.gd` passa a executar movimento contínuo do jogador, interpolação por clique, velocidades, reservas físicas, acesso aos móveis, escolha de destino, portais, ocupação, esperas e desvio recursivo dos NPCs. As implementações anteriores foram removidas de `restaurant-core.js`; restam adaptadores para chamar o módulo e reconciliar os atores mantendo suas referências. O WeakMap JavaScript conserva somente o transporte transitório da entrada enquanto a interface/motor geral ainda usa a ponte. Ele não calcula o movimento. Velocidades mantidas: jogador 3,3 células/s e NPCs 2,5 células/s.

MovimentoNativo compara nove sequências completas com o motor anterior: clique longo, diagonal/parada, parede, portas manual/automática, NPCs, offsets de destino, troca teclado/clique e corredor estreito com desvio. Coordenadas/interpolação aceitam erro absoluto de 1e-8; estrutura, reservas e contadores continuam comparados. A serialização da ponte foi alterada para precisão completa: o arredondamento anterior antecipava o limiar de espera no corredor. Com a correção, a sequência e o contador flowWaits coincidem.

Passaram MovimentoUI, MovimentoNativo, RuaHorarioUI, MaosUI, CatalogoModernoUI, Regras.cjs e os 904 casos de RegrasNativas. Não foi gerado APK desta etapa. O sistema ainda integra com a simulação por adaptadores temporários; remover QuickJS depende da migração dos demais sistemas.

## Regras de construção em GDScript

`Construcao.gd` executa bloqueio de edição durante serviço, geometria e orientação dos assentos, compatibilidade com cadeiras antigas, validação dos setores, paredes/portas, pessoas e reservas físicas, ocupação, conectividade até a saída e acesso a cada móvel. Executa também compra/posicionamento/rotação/mudança/remoção/reembolso, proteção de preparos e itens instalados, louça suja e entregas pendentes. Lista de assentos utilizáveis e equipamentos mínimos também migrou.

O motor JavaScript mantém adaptadores de transporte e resolução das referências retornadas. Móveis não envolvidos na mudança preservam suas referências; o objeto reposicionado é substituído como no motor anterior. Os comandos de abertura/fechamento do catálogo e a apresentação do modo construção continuam na camada de interface ainda em JavaScript; regras e transações passam pelo módulo nativo.

ConstrucaoNativa compara 2.892 operações com o motor anterior, em plantas vazia/mobiliada/antiga e estados sem dinheiro, com serviço aberto, louça suja, preparo e recebimento pendente. Compara mensagens, objetos, dinheiro, investimento, serial e contêineres; toda operação recusada também precisa preservar exatamente o estado anterior. Passaram ConstrucaoUI, CadeirasUI, CatalogoModernoUI, MaosUI e Regras.cjs. Nenhum APK final foi gerado nesta etapa.

## Atendimento em GDScript

`Atendimento.gd` executa anotação de pedidos, acesso ao cliente e à retirada, coleta de pratos, serviço manual/garçom, prioridade por paciência, retorno de pratos cancelados, consumo, pagamento, louça suja e saída do cliente. Inclui criação do perfil de paciência, indicadores/esperas, satisfação, desistência e registro da avaliação/reputação da visita. `clientes.json` mantém os parâmetros existentes. O ramo de logística de `workerStep` continua no sistema legado de entregas; o ramo do garçom usa o módulo nativo. A agenda de chegada/spawn e o relógio geral ainda são coordenados pelo motor antigo.

Os sorteios são transacionais: se faltam números aleatórios, a execução nativa descarta o estado intermediário e solicita um número ao gerador original; a ação é reaplicada à mesma entrada até concluir. Isso preserva ordem e quantidade dos sorteios sem efeitos duplicados. O estado só é reconciliado na conclusão. Consultas sem efeitos não substituem as referências do estado.

AtendimentoNativo compara 240 ações (anotação, serviço, interação, garçom e devolução, em estados esperando/pedido/cancelado/comendo, distâncias, carga e expiração) e dois ciclos completos de 800 passos cada, um manual e um automático. Ambos resultam nos mesmos três pagamentos e 12 sorteios que a referência, com conservação e save válidos. Passaram também RuaHorarioUI e Regras.cjs; MaosUI verifica a integração com a cozinha. Ainda existem adaptadores JavaScript e a coordenação global da simulação; a migração total não foi encerrada nem foi gerado APK desta etapa.

## Administração em GDScript

`Administracao.gd` executa sincronização/edição dos turnos, abertura e encerramento, detecção de serviço pendente, avanço do relógio, salto de horário de teste, fechamento diário e relatórios, compras de ingredientes/utensílios, entregas ao recebimento, distribuição de qualidade recebida e aplicação/validação da reputação. O atendimento reutiliza a mesma aplicação de reputação, evitando regras divergentes. Foram preservados preços, multiplicadores, limite de recebimento, horários e despesa diária de $12.

Os adaptadores mantêm o vínculo entre `lastReport` e o relatório correspondente sem modificar o relatório anterior ao fechar outro dia. A coordenação de `step/simulate`, a agenda de novas chegadas, os comandos dos menus e a movimentação logística entre estoques ainda integram sistemas que usam JavaScript; as regras administrativas listadas não executam mais suas implementações antigas.

AdministracaoNativa compara 519 operações com o motor anterior, abrangendo horários, serviço aberto/pendente, madrugada, compras inválidas/qualidade, entregas, relógios inválidos e reputação. Também verifica dois fechamentos consecutivos e duas simulações completas de dois dias contra a referência antiga. Passaram AtendimentoNativo (incluindo 240 ações e dois fluxos completos), RuaHorarioUI e Regras.cjs. Sem novo APK nesta etapa.

## Salvamentos nativos

`Salvamentos.gd` passa a coordenar a leitura JSON, conversão dos formatos 4–12, criação de dados legados de paciência/relógio/reputação, transformações da cozinha/mochila e validação final. `ValidadorSave.gd` substitui `valid` e `validExperience`, usando os validadores nativos já existentes de cozinha, qualidade, relógio, reputação e conservação. `serializeSave` e `parseSave` são adaptadores dos botões antigos; não implementam leitura/escrita JSON nem migração em JavaScript na execução Godot. `Restaurante.gd.import_save` agora valida diretamente em GDScript. A gravação temporária, backup e recuperação de disco permanecem nativos e passam a preservar a precisão completa dos números.

A versão do formato continua 12 e as chaves de armazenamento antigas continuam disponíveis. A matriz inclui entradas representativas aceitas dos formatos 4 a 12, v4 com cliente ativo e sorteios preservados, fixtures históricos v9/v11, panelas com qualidade/porções, armazenamento cheio, campos ausentes e tipos inválidos. São 216 comparações, incluindo as fases e validações anteriores. A entrada original permanece inalterada. A comparação detectou uma diferença entre int e float em listas de versões; o teste da versão foi corrigido explicitamente.

SalvarCarregarNativo testa os botões Salvar/Carregar, JSON gravado, restauração da partida, recusa de arquivo corrompido/importação inválida, importação válida, gravação atômica e recuperação do backup. A preservação após erro compara o progresso, permitindo somente a mensagem de notificação já existente. Passaram também MaosUI, MovimentoUI (posição fracionária e entrada transitória), AtendimentoNativo (pagamentos, avaliações e save final) e Regras.cjs. O teste não substitui uma matriz de todas as combinações históricas possíveis nem validação no dispositivo Android. Sem novo APK nesta etapa.
