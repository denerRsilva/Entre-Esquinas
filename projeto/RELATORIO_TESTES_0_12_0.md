# Entre Esquinas — Tempo, calendário e reputação 0.12.0

Data do relatório: 2 de novembro de 2026. Base: 0.11.0.

## Inspeção e decisões de integração

Arquitetura existente: JavaScript sem framework, núcleo de simulação e estado em restaurant-core.js, interface DOM/Canvas em restaurant-ui.js. A simulação já possuía segundos monotônicos, pausa nos menus e aba oculta, ciclo de clientes, satisfação de duas esperas e manifestações individuais. Não existiam calendário nem pontuação de reputação. Os registros de satisfação foram reaproveitados, sem qualidade culinária nova.

Dependência de design sinalizada antes da implementação: o que fazer com pendências às 02:00. O usuário escolheu **Concluir serviço**: interromper chegadas, manter horário em 02:00 enquanto a simulação conclui clientes/preparos; depois iniciar o próximo dia às 06:00. Não há cancelamento forçado, sono ou penalidade nova. Se um preparo estiver pausado por distância, o jogador deve voltar ao fogão. Clientes podem desistir pelas regras de paciência já existentes.

Conflito identificado: na 0.11.0, terminar jantar avançava o dia e fechava o financeiro. Agora a data avança apenas pelo calendário; fechar almoço/jantar alterna o período sem mudar a data. O relatório e a despesa existente de $12/dia passam para a virada do dia, uma vez por dia do calendário. Não foram impostas janelas horárias de abertura nem limite novo de serviços.

Calendário do dia jogável: a meia-noite muda o horário para 00:00, mantendo a data do expediente. A data avança ao iniciar o próximo dia às 06:00. São quatro estações de 28 dias, sete dias da semana, ano 1 iniciando na Primavera, segunda-feira.

O frame contabiliza tempo ativo e processa atrasos em passos curtos. Segundos de simulação permanecem monotônicos através dos dias, preservando ETAs de entrega e prazos. Calendário e demais sistemas usam o mesmo dt; às 02:00, somente o avanço do calendário aguarda a conclusão autorizada, sem congelar as operações pendentes.

## Parâmetros provisórios e configuráveis

| Parâmetro | Inicial |
| --- | --- |
| Início do dia | 06:00 |
| Fim do dia jogável | 02:00 da madrugada seguinte |
| Bloco de relógio | 10 minutos por 7 segundos ativos |
| Calendário | 4 estações × 28 dias, semana de 7 dias |
| Reputação inicial | 0/100 |
| Elogio | +1 |
| Reclamação | −1 |
| Abandono | −1, sem acumular outra penalidade da reclamação da visita |
| Níveis | 0–19 Desconhecido; 20–39 Pouco conhecido; 40–59 Reconhecido; 60–79 Bem avaliado; 80–100 Referência local |
| Influência sobre demanda | Nenhuma nesta versão |
| Despesa diária existente | $12, agora lançada na virada do calendário |

Configurações em TIME_CONFIG e REPUTATION_CONFIG. As faixas/probabilidades de satisfação da 0.11.0 continuam em CUSTOMER_CONFIG. A espera e a cozinha mantêm suas durações em segundos ativos. Um abandono é tratado como resultado da visita, mesmo sem reclamação verbal; se houver reclamação, não soma outro impacto. Visita atendida sem manifestação não altera a pontuação. Histórico e IDs processados impedem replay, inclusive nos limites e em visitas silenciosas.

## Testes executados

| Verificação solicitada | Evidência | Resultado |
| --- | --- | --- |
| Minutos e horas | 6,9 + 0,1 segundo; 7 segundos; passagem para 07:00; passos divididos equivalentes | Passou |
| Pausa e retomada | Frame real da UI em menus/início/aba oculta, DOM/Canvas simulados; relógio incluído no snapshot | Passou |
| Tempo ativo com frame atrasado | Frame com 7 segundos de intervalo produz um bloco, processado em passos curtos | Passou |
| 23:50 → 00:00 | Mudança de horário sem troca prematura do dia jogável | Passou |
| 01:50 → 02:00 | Cliente pendente, entrada fechada, horário retido; paciência segue em simulação | Passou |
| Dia seguinte | Conclusão/abandono e saída existentes, início às 06:00 | Passou |
| Estações e anos | Dias acumulados 28, 56, 84 e 112 atravessando a virada | Passou |
| Dias da semana | Domingo/segunda e início de nova estação/ano | Passou |
| Almoço e jantar | Encerramento manual alterna períodos sem trocar a data; financeiro uma vez na virada | Passou |
| Preparo e entregas pendentes | Distância pausa preparo; retomada preserva ingredientes, panela, objetos e entrega | Passou |
| Recebimento de avaliações | Visita real servida e paga gera elogio; abandonos com/sem manifestação | Passou |
| Ausência de duplicação | Um impacto por visita, save/load, migração e tentativa de replay | Passou |
| Limites 0 e 100 | 150 elogios, 150 reclamações, validação do histórico e dos cinco níveis | Passou |
| Balanceamento configurável | Variação fracionária de 0,25 em teste; configuração restaurada | Passou |
| Demanda preservada | Duas simulações com reputações diferentes e o mesmo RNG produzem o mesmo fluxo | Passou |
| Regressão | Cozinha, inventários, satisfação, movimento, louça, abertura livre e ferramentas de teste | Passou nas suítes existentes |

Comandos:

- `node restaurant.test.cjs`: aprovado. As expectativas antigas de avanço imediato após o jantar foram atualizadas para a nova autoridade do calendário; o ciclo real de cozinha, serviço, pagamento e louça permanece testado.
- `node patience.test.cjs`: aprovado, 15 grupos do sistema de paciência/satisfação.
- `node calendar-reputation.test.cjs`: aprovado, 12 grupos novos com as verificações acima.
- `node ui.test.cjs`: aprovado; inclui HUD, painéis, pausa do relógio, aviso das 02:00 e frame atrasado.
- `node --check dist/restaurant-core.js` e `node --check dist/restaurant-ui.js`: aprovados.
- Integridade do HTML único/ZIP e correspondência dos arquivos publicados verificadas no empacotamento.

Conferência no Chrome da prévia: versão inicial 0.12.0, cenário mobiliado, HUD com 06:00/data/estação/ano/reputação, painel Calendário com explicação da transição e painel Reputação com nível/configuração/histórico. Essa conferência não substitui playtest humano nem representa uma sessão natural de um ano inteiro; as viradas foram verificadas por simulação automatizada.

## Arquivos alterados

| Arquivo | Responsabilidade |
| --- | --- |
| dist/restaurant-core.js | Configuração, relógio, calendário derivado, virada segura, financeiro diário, reputação, deduplicação, validação e migração |
| dist/restaurant-ui.js | HUD, painéis Calendário/Reputação, avisos, salvamento e tempo ativo em passos curtos |
| dist/restaurant.css | Ajuste do cabeçalho para relógio/data/reputação |
| dist/index.html | Versão 0.12.0 e instruções iniciais |
| calendar-reputation.test.cjs | Testes dos novos sistemas |
| restaurant.test.cjs | Expectativas dos ciclos adaptadas à mudança de data pelo calendário |
| ui.test.cjs | Pausa do relógio, HUD, painéis e tempo ativo |
| README.md | Integração, configurações, conflitos resolvidos e compatibilidade |
| RELATORIO_TESTES_0_12_0.md | Evidências e pendências |

## Compatibilidade e limitações

Formato de save 6, chave entre-restaurante-06, fallback 05/04. Migração copia e valida o save anterior sem sobrescrevê-lo. O dia acumulado e a satisfação/paciência existente da 0.11.0 são preservados. Por não existir relógio antigo, o dia carregado começa às 06:00; a reputação começa em 0 e avaliações históricas são marcadas processadas sem pontuação retroativa. A limpeza de testes preserva horário, reputação e históricos, cancelando as operações ativas como antes.

Pendências de Game Design: validar ganhos/perdas e reputação inicial; definir multiplicadores futuros de demanda; qualquer nova restrição de almoço/jantar por horário ou quantidade; qualidade culinária; qualquer alteração futura da regra aprovada de conclusão às 02:00. Esses sistemas/restrições não foram acrescentados.

Android real, desempenho em dispositivos lentos, telas pequenas e um playtest humano completo ainda não foram executados. A fonte do tempo ativo é compartilhada; uma queda prolongada de desempenho pode exigir processar vários passos de recuperação antes do próximo desenho. Não há novo sistema de velocidade, clima, sono, eventos sazonais ou penalidades de sono. A despesa de $12 é a regra econômica já existente, agora vinculada ao dia do calendário.
