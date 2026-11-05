# Validação 0.14.0 — 04/11/2026

## Alterações

Clique em cliente/mesa para anotar ou servir, pia com louça para lavar e mesa suja para recolher. Caminhada seguida de uma única execução; novo alvo, movimento manual ou abertura de menu cancela a intenção. Sem alteração dos tempos de lavagem/limpeza existentes.

Chegadas: primeiro cliente após 8 segundos ativos; intervalo de 25 segundos. Cada cliente reserva uma mesa inteira; nova chegada só usa a mesa após saída e recolhimento da louça. Grupos ainda não implementados. Saves existentes mantêm clientes já sentados.

## Testes executados

- node --check: núcleo e interface, sem erros de sintaxe.
- node ui.test.cjs: callbacks reais de clique com simulação de caminhada para atendimento, serviço, limpeza e lavagem; execução única e cancelamento no chão; demais verificações de cozinha, inventários e pausa aprovadas.
- node arrivals.test.cjs: tempos de primeira chegada/intervalo, mesas distintas, capacidade e bloqueio por louça aprovados.
- node kitchen.test.cjs: 16 cenários aprovados.
- node patience.test.cjs: 15 cenários aprovados.
- node calendar-reputation.test.cjs: 12 cenários aprovados.
- python3 build.py ../dist/index.html: HTML publicado gerado com sucesso.

## Limites

Validação automatizada com simulação e harness de DOM/Canvas. Não realizado playtest humano nem teste físico em Android nesta entrega. O intervalo de chegadas é uma hipótese de balanceamento para o próximo playtest.
