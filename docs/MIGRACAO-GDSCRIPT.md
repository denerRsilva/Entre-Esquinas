# Migração para GDScript — concluída

Atualização da limpeza: o APK atual é [EntreEsquinas.apk](../build/Android/EntreEsquinas.apk). A cópia idêntica `-gdscript` e seu checksum foram removidos; nomes nas validações abaixo são históricos.

O jogo não executa mais JavaScript. Foram removidos os cinco arquivos de produção, o DOM simulado, os controladores transitórios, a GDExtension RestauranteVM e todas as bibliotecas/fontes QuickJS. Os testes atuais também são GDScript; permanecem fixtures JSON para comparação com o comportamento anterior.

`mundo/Restaurante.gd` inicia diretamente `SessaoCompleta.gd`, mantém a gravação atômica/backup e recebe os controles Godot. A sessão possui a partida e coordena entrada, interação, câmera, pausas, simulação, notificações e sons. `Cena.gd` compõe o cenário; os TileMaps e cenas de móveis/personagens continuam editáveis. `AdministracaoUI`, `PainelJogoNativo`, inventários, catálogo, utensílios, ícones e livro geram os controles diretamente em GDScript.

A integração direta detectou uma diferença entre int/float na comparação de dicionários de ingredientes. O reconhecimento de receitas foi corrigido para comparar quantidades numericamente, preservando as combinações anteriores. O gerador aleatório nativo respeita o mesmo intervalo usado nas regras de clientes. Foram mantidos formato 12 e migração dos saves 4–12, chaves de armazenamento, posições iniciais, velocidades, preços e configurações de exportação.

## Validação final

- Auditoria: zero arquivos JavaScript no projeto Godot, zero consumidores da ponte, zero extensões legadas.
- 22 suítes GDScript: paridade com as fixtures anteriores e integração dos controles, armazenamento, cozinha, atendimento, pagamentos, construção, zoom/arrasto, compras, tarefas, horários e salvamento/backup/importação.
- Composição visual comparada com 51 cenas congeladas do desenho anterior; ícones/textos comparados em 52 casos. Câmera: 3.469 comparações; interações: 1.546. As demais matrizes incluem 2.892 operações de construção, 1.620 casos de cozinha, 202 de simulação e os casos históricos de regras/armazenamento/conservação/saves.
- Editor/importação e jogo testados em Linux/Godot 4.6.3. O editor tentou iniciar o ADB local, bloqueado pela restrição de sockets do ambiente; a exportação Android e a verificação da assinatura concluíram.
- APK separado: `build/Android/EntreEsquinas-gdscript.apk`. A assinatura é válida e usa a mesma chave do APK anterior. O pacote não contém JavaScript, QuickJS ou QA. O APK anterior foi preservado.

Não houve teste em aparelho Android. A exportação Linux independente não foi produzida neste ambiente, que não possui o modelo `linux_debug.x86_64`; os testes Linux usaram o executável Godot. O projeto não depende desse modelo para abrir no editor.

## Histórico da migração

As seções seguintes são registros intermediários. Menções a pendências e à ponte descrevem aquelas etapas; o estado atual é o apresentado acima.

# Migração para GDScript — em andamento

Referência funcional: commit 5ae8794, APK 0.21.2-godot.18.

## Estado atual

Já executam em GDScript: criação de partidas, mapa/navegação, movimento, construção, inventários, conservação/qualidade/receitas, cozinha, atendimento, administração, validação/conversão de saves, logística e coordenação da simulação. Inventários, catálogo e páginas do livro também são gerados nativamente. Câmera, seleção dos alvos por clique e fila de interação também executam em GDScript. Ainda há consultas/adaptadores no núcleo JavaScript e dependências de apresentação; isso não equivale à remoção do JavaScript.

As seções seguintes registram a evolução e a validação de cada etapa; descrições antigas de pendências são substituídas pelas etapas posteriores.

## Implementado

A coordenação de frames antes feita por `snapshot` em `simulacao/sessao.js` passou para `simulacao/nativa/Sessao.gd`. `Restaurante.gd` usa diretamente essa sessão. Seleção das áreas da interface, montagem do pacote de renderização e coleta de gravações e sons são coordenadas em GDScript.

## Dependências ainda presentes

A sessão nativa ainda usa uma ponte temporária para as regras, eventos, composição gráfica e árvore de menus JavaScript. Não é uma conversão completa. QuickJS continua obrigatório. Os testes Node que chamavam `snapshot` precisam ser substituídos por testes Godot; não são mais executáveis contra o novo ponto de entrada.

Unidades ainda necessárias: consultas/adaptadores residuais, demais ações de interface e painéis/HUD, composição gráfica e eliminação do DOM simulado. Só remover a extensão nativa depois que não houver consumidores.

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

## Interface nativa: inventários e catálogo

`InventariosNativos.gd` passa a gerar conteúdo, imagens, rótulos, slots e ações dos inventários de móveis, incluindo guardar/retirar itens e recuperar excedentes. `ComprasConstrucaoNativas.gd` gera as duas colunas do catálogo usando as cenas atuais dos móveis, nomes, preços e disponibilidade. Os dois blocos correspondentes foram removidos de `acoes.js`; `Sessao.gd` aplica os painéis nativos à estrutura visual existente.

Os controles nativos usam registro próprio de ações em GDScript, sem `Host.widgets`/DOM para os botões desses painéis. `Entrada.gd` encaminha os eventos; ações inexistentes/desabilitadas são descartadas e a visibilidade do menu é conferida novamente antes de chamar o sistema. Ações de cozinha e início de posicionamento ainda alcançam endpoints da simulação legada enquanto esses blocos terminam de migrar. Cabeçalhos, janelas, HUD e demais menus ainda dependem parcialmente do modelo antigo: **esta etapa não conclui a interface final**.

Passaram InventariosNativosUI (sem conteúdo DOM, registro nativo, retirada/guardar, evento antigo, controle desabilitado e conservação/save), EstantePanelasUI, MaosUI, CatalogoModernoUI (duas colunas, cenas atuais e registro nativo), ConstrucaoUI e Regras.cjs. BancadasUI/TavernaUnicaUI foram atualizados para consultar os controles realmente exibidos em vez do painel DOM removido.

## Cozinha, logística e coordenação da simulação

`Cozinha.gd` executa retirada/devolução nas mãos, recuperação de excedentes, corte/cancelamento, instalação/retirada de panelas e pratos, composição e correção dos ingredientes, reconhecimento/início do preparo, término, calor/queima, apoio/empratamento, lavagem, louça suja e descarte. As antigas funções de cozinha foram substituídas por adaptadores; os botões nativos de inventário já alcançam as regras GDScript. Os caminhos antigos de mochila permanecem compatíveis enquanto ainda existem endpoints legados.

`Logistica.gd` executa seleção de armazenamento, separação por qualidade, retirada/depósito, recebimento manual, transferências e transporte pelos funcionários. `Simulacao.gd` coordena movimento, atendimento, logística, cozinha, entregas, chegada dos clientes, escolha de assentos/receitas, turnos e transição diária. O passo completo executa os sistemas diretamente em GDScript. Os sorteios transacionais e a precisão numérica foram preservados; o adaptador também preserva o vínculo do último relatório e a entrada transitória do teclado.

`CicloInterface.gd` passa a controlar o relógio de apresentação, política de pausa, subdivisão do avanço, atualização periódica dos painéis e duração das notificações. Ainda chama endpoints antigos para a fila de interação, câmera, sons e atualização visual. O laço `frame` foi removido de `acoes.js`. A conversão trata explicitamente flags ausentes do modelo antigo como falsas.

`LivroReceitasNativo.gd` gera as três páginas diretamente em GDScript, usando arte da comida pronta, ingredientes, indicação de corte e três passos curtos. O conteúdo do livro foi removido de `acoes.js`; sua janela externa ainda usa o modelo transitório.

Validação: `CozinhaNativa` compara 1.620 ações/temporizadores contra a referência congelada, incluindo mãos, receitas, qualidades, cozimento, queima, corte e apoio/empratamento. `SimulacaoNativa` compara 202 cenários de simulação, chegadas, teclado, turnos, transporte/recebimento e estoques. Os geradores de fixtures ficam somente em `qa/referencia-migracao`; não são parte do jogo. AtendimentoNativo e AdministracaoNativa voltaram a coincidir nos fluxos completos e fechamentos. O livro tem teste de integração próprio verificando páginas, arte disponível, ausência do conteúdo DOM antigo e retorno ao jogo.

O script `scripts/testar-migracao.sh` reprova erros GDScript registrados no log, além de resultados de teste e códigos de saída, evitando considerar uma cena aprovada quando uma chamada falha antes das asserções.

**A migração total ainda não está concluída.** Permanecem a apresentação do cenário, câmera/interações de interface, outros painéis/HUD, dados/adaptadores JavaScript e a extensão QuickJS. Não foi removida a ponte nem gerado um APK final desta branch. A branch principal e o APK anterior continuam preservados.


## Câmera e interação por clique em GDScript

`Camera.gd` calcula enquadramento das três plantas e ambientes, acompanhamento da posição interpolada do jogador, limites do mapa, aproximação de 70% a 200%, conversão entre coordenadas da tela/mundo, posição/visibilidade da placa de serviço, dimensões do viewport, arrasto e deslocamento da câmera por teclado na construção. Os cálculos anteriores foram removidos de `acoes.js`; os adaptadores mantêm a aplicação aos controles e a persistência da preferência de zoom.

`Interacoes.gd` escolhe a ação principal de cada equipamento e mesa, seleciona clientes/prioridades, calcula a aproximação, cria/valida a fila com prazo e identidade de partida e executa uma única ação quando o alvo é alcançado. Trata cancelamento por troca de partida, expiração, alvo removido/mudança de fase, construção e movimento. O clique no mapa decide alvos, portas, funcionários/moradores, estações antigas, células livres e offsets de caminhada diretamente em GDScript. Seleção de móveis e confirmação inicial do ponto de construção também passam por esse módulo.

Os comandos nativos produzem efeitos de apresentação (notificação, abrir janela/inventário, atualizar prévia/catálogo) aplicados pela interface transitória. A referência da partida e o transporte do item pendente ainda ficam no adaptador; as decisões e a execução da fila não ficam em JavaScript. A entrada transitória do teclado é liberada quando um destino por clique é aceito, preservando o comportamento anterior.

`CameraNativa` compara 3.469 casos, incluindo enquadramento, coordenadas, placa, zoom e dimensões de tela. `InteracoesNativas` compara 1.546 operações/células nas três plantas e na rua/estoque com funções de apresentação congeladas antes da migração. Inclui mãos/estações, receitas, clientes, fila expirada/antiga, construção, movimento, portas e caminhos bloqueados. Referências e geradores JavaScript ficam exclusivamente em `qa/referencia-migracao`.

`CameraInteracoesUI` verifica botões de zoom, restauração, arrasto, teclado, liberação do arrasto e pausa da construção. `AtendimentoPorCliqueUI` verifica anotação e serviço pelo clique na mesa, pagamento único, recolhimento, lavagem e conservação final. MaosUI, ConstrucaoUI, RuaHorarioUI, MovimentoUI, MenusUI, CatalogoModernoUI e InventariosNativosUI verificam a integração com os controles existentes.

Esta etapa não remove QuickJS. O cenário desenhado, criação de outros painéis/HUD, controles da janela e adaptadores restantes ainda precisam de conversão. Não foi gerado APK desta etapa.
