# Migração para GDScript — em andamento

Referência funcional: commit 5ae8794, APK 0.21.2-godot.18.

## Implementado

A coordenação de frames antes feita por `snapshot` em `simulacao/sessao.js` passou para `simulacao/nativa/Sessao.gd`. `Restaurante.gd` usa diretamente essa sessão. Seleção das áreas da interface, montagem do pacote de renderização e coleta de gravações e sons são coordenadas em GDScript.

## Dependências ainda presentes

A sessão nativa ainda usa uma ponte temporária para as regras, eventos, composição gráfica e árvore de menus JavaScript. Não é uma conversão completa. QuickJS continua obrigatório. Os testes Node que chamavam `snapshot` precisam ser substituídos por testes Godot; não são mais executáveis contra o novo ponto de entrada.

Próximas unidades: regras e validação de estado/saves; navegação e movimento; cozinha e conservação de itens; serviço e economia; ações de interface; composição gráfica e eliminação do DOM simulado. Só remover a extensão nativa depois que não houver consumidores.

Preservar versão e estrutura dos saves, valores econômicos, velocidades, dimensões e posições dos móveis. Não publicar APK desta etapa como migração concluída.
