# Entre Esquinas — Relatório técnico e testes 0.11.0

Data: 2 de novembro de 2026. Base inspecionada: 0.10.4. Requisito: Sistema de Paciência e Satisfação v1.0 do Game Designer.

## Inspeção e integração

Arquitetura existente: JavaScript sem framework, núcleo de estado em restaurant-core.js, interface DOM e renderização Canvas em restaurant-ui.js. Sem novas dependências.

- `spawn`: cria cliente com ID derivado do serial e sorteia perfil/limites individuais.
- Movimento existente até a cadeira: `step` reconhece chegada e inicia atendimento. Caminhar até o assento não consome essa espera.
- `interact`: registra pedido, guarda resultado do atendimento e inicia contador independente da comida.
- `startCook`/`kitchenStep`/`plateFood`: ciclo de cozinha mantido. Cancelar pedido não devolve ingredientes nem desfaz preparos.
- `serve`: verifica proximidade, pedido ativo e ausência de desistência; encerra espera e calcula satisfação. Entrega no limite exato é recusada.
- `step`: avança uma única vez os contadores já ativos no começo do passo; esgotamento é processado antes das entregas do garçom. Não usa setTimeout/setInterval ou relógio externo.
- Refeição concluída: pagamento existente e finalização única da visita. Abandono: pedido perdido, sem receita, registro único e saída pela movimentação existente.
- Fechamento: clientes ainda saem pela porta; pedidos cancelados e pratos de pedidos cancelados na mão não bloqueiam a conclusão. Preparo físico em andamento conserva o comportamento anterior.
- Sistemas ausentes: qualidade de refeições e reputação com consequências comerciais. Aplicada a alternativa expressamente autorizada: pesos das esperas normalizados e manifestações isoladas.

## Parâmetros provisórios

Perfis e faixas em segundos seguem a especificação. Distribuição inicial com pesos relativos 1:1:1, configurável. Pontuação = 100 × média ponderada das frações restantes ao encerrar cada espera; peso de qualidade excluído enquanto não houver esse sistema. Pesos efetivos 50%/50%. Limiares provisórios de classificação: 85/65/40/0. Probabilidades de elogio/reclamação: 60%/20%/5%/35%/75%, conforme classificação/abandono da especificação. Indicador positivo: 8 segundos de simulação; indicador de abandono: até sair. A precedência do abandono no empate lógico evita cobrar ou servir depois da paciência esgotada.

Todos esses valores ficam em CUSTOMER_CONFIG. Não há desconto, benefício ou alteração da demanda.

## Casos obrigatórios

| Caso | Método | Resultado |
| --- | --- | --- |
| 1. Atendimento rápido | Pedido real, preparo, empratamento, entrega e pagamento | Passou; etapas isoladas, satisfação positiva e uma visita |
| 2. Atendimento quase no limite | Impaciente, 39 dos 40 segundos antes do pedido | Passou; resultado de atendimento preservado, comida com limite novo |
| 3. Abandono antes de pedir | Esgotamento de 40 segundos | Passou; sem pedido, venda ou cobrança; saída existente |
| 4. Abandono esperando comida | Esgotamento após registro e início do preparo | Passou; pedido perdido, ingredientes sem estorno |
| 5. Entrega antes do limite | Entrega a 59,999 dos 60 segundos | Passou; contador para, refeição pode ser paga |
| 6. Vários perfis | Clientes impaciente, normal e paciente; pesos alterados no teste e restaurados | Passou; limites/objetos isolados e faixas corretas |
| 7. Jogo pausado | Função frame da UI com menu/início/aba oculta, DOM/Canvas simulados | Passou; nenhum avanço da paciência ou do tempo |
| 8. Fechamento com pendências | Entrada encerrada, pedido expira e cliente sai | Passou; serviço conclui sem novas chegadas ou venda |
| 9. Entrega e desistência simultâneas | Garçom com prato pronto e proximidade; avanço até o limite exato | Passou; desistência vence, prato conservado e devolvido |
| 10. Avaliações duplicadas | Passos adicionais, salvar/carregar e cinco probabilidades em ambos os lados dos limiares | Passou; no máximo uma manifestação por visita |

## Testes adicionais

`node patience.test.cjs`: 15 grupos de cenários aprovados, incluindo os casos acima, bancada cheia mantendo prato cancelado, fechamento sem bloqueio, recusa de entrega manual tardia, reutilização de prato em pedido compatível, limiares ⏳/❗/😠, duração de 😊, pesos/classes, migração e rejeição de históricos duplicados. RNG injetável no núcleo torna os casos de probabilidade reproduzíveis. Asserções de validade e conservação de ingredientes, equipamentos e porções durante a simulação.

`node restaurant.test.cjs`: suíte anterior aprovada, cobrindo cozinha física, 4 porções, empratamento parcial/total, serviço manual, garçom, pagamentos, louça, descarte, inventários, abertura livre e cenário mobiliado/limpeza.

`node ui.test.cjs`: suíte aprovada com DOM/Canvas simulados. Verifica ações existentes, seleção por clique, inventários divididos, preparo pela UI, início mobiliado, limpeza, desenho de ⏳ no Canvas, segundos de paciência no HUD, painel Clientes e pausa do frame real da UI.

Prévia no Chrome: tela inicial 0.11.0, opção mobiliada e painel Clientes conferidos. Uma fixture local controlada, com o mesmo núcleo e renderizador, mostrou simultaneamente ⏳, ❗, 😠, 🤬 e 😊 sobre os personagens, segundos restantes no HUD e histórico de abandono/reclamação no painel. A fixture preparou estados específicos para inspeção visual e não foi incluída no jogo publicado. Isso não equivale a um playtest natural completo.

Sintaxe dos scripts, diferenças de arquivos e HTML único/ZIP verificados no empacotamento.

## Arquivos modificados

| Arquivo | Alteração |
| --- | --- |
| dist/restaurant-core.js | Configuração, dados de visita, duas esperas, satisfação, cancelamento seguro, registros, validação e migração |
| dist/restaurant-ui.js | Emojis sobre personagens, tempo restante, painel Clientes, tratamento visual de pedidos cancelados e save atualizado |
| dist/index.html | Versão 0.11.0, instrução dos indicadores e atualização de cache dos scripts |
| patience.test.cjs | Casos novos com simulação e RNG controlado |
| ui.test.cjs | Pausa do frame e apresentação da paciência |
| README.md | Decisões de integração, parâmetros, compatibilidade e dependências ausentes |
| RELATORIO_TESTES_0_11_0.md | Evidências, cenários e limitações |

## Limitações e pendências

- Parâmetros provisórios precisam de playtest humano; os testes não demonstram que a dificuldade ou a diversão estejam balanceadas.
- Qualidade culinária não implementada, conforme restrição. Reputação somente registra elogios/reclamações; integração comercial futura depende de design aprovado.
- Android real, variedade de fontes de emoji, telas pequenas e acessibilidade com leitores de tela no Canvas ainda exigem testes específicos. O HUD textual e a tabela ajudam a consultar as informações.
- Migração não reconstrói tempos inexistentes da versão anterior. Visitas antigas recebem os contadores novos da etapa atual, sem avaliações retroativas.
- Histórico de visitas e manifestações permanece no salvamento local, sem sincronização entre dispositivos.
- Se o estoque de pratos da bancada estiver cheio, um prato de pedido cancelado continua na mão até liberar espaço ou servir pedido compatível. Não é descartado nem transferido à distância.
