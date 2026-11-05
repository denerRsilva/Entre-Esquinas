# 0.18.0 — Câmera, menus e horários

Base inspecionada: 0.17.1. Implementação autorizada pelo usuário em 04/11/2026.

## Diagnóstico e correção
O enquadramento usava zoom fixo de 1,5. Agora inicia em visão ampla, com ajuste de 100% a 200%, mantendo proporções, limites e correspondência dos cliques.
O fechamento chamava finishPeriod e alternava period sem consultar o relógio. Agora fechar apenas encerra as entradas e aguarda as pendências. A seleção almoço/jantar segue os horários configurados; fechar e reabrir não consome um turno nem altera o relógio.

Gestão contém os sistemas do restaurante e os horários. Opções reúne câmera, salvamento, testes e primeiros passos. Equipe continua em Gestão, conforme pedido para manter as demais funções ali. Compras e cardápio permanecem no computador.

## Verificação executada
- service-hours.test.cjs: passou. Regressão abrir/fechar imediatamente; reabertura; limites de início/término; intervalo; jantar na madrugada; clientes pendentes preservados; configuração inválida sem mutação; bloqueio de edição durante atendimento; save/migração em cópia; virada preserva configuração.
- ui.test.cjs: passou. Separação das abas; zoom, limites e botões; formulário de horários; testes anteriores de cozinha, interação, pausa e cliques em três proporções.
- kitchen.test.cjs: 16 cenários passaram.
- patience.test.cjs: 15 cenários passaram.
- calendar-reputation.test.cjs: 12 cenários passaram.
- quality.test.cjs: 15 cenários passaram.
- arrivals.test.cjs: passou.
- Testes de serviço existentes receberam horário de almoço iniciando às 06:00 em seus fixtures; expectativa antiga de avanço automático ao fechar foi corrigida para permanência no mesmo turno.
- Sintaxe JavaScript, git diff --check e build HTML: passaram.
- Chrome na prévia local: inicialização mobiliada e inspeção visual do enquadramento amplo e formulário Gestão → Turnos, com quatro seletores e botão Aplicar horários.

## Limitações
Não testado em celular físico. Inspeção visual de outras proporções e interação nativa dos seletores no Android pendentes. Abertura continua manual; o horário de início define disponibilidade, sem abrir sozinho. Os horários iniciais são parâmetros editáveis, não resultado de balanceamento com jogadores. Formato de save permanece 9 com campo adicional opcional; salvamentos antigos são preservados até o jogador salvar.
