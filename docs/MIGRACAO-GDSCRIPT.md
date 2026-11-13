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
