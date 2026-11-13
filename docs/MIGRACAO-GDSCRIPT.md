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
