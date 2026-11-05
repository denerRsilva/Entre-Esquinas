# Entre Esquinas — Restaurante 0.19.0

Simulação de restaurante e vida na cidade, em HTML/JavaScript/Canvas.

- Código-fonte, sprites, testes e documentação: `projeto/`.
- Jogo completo para abrir no navegador: `dist/index.html`.
- Gerar o HTML: `cd projeto` e `python3 build.py ../dist/index.html`.
- Testes principais (dentro de `projeto/`): `node waiter-orders.test.cjs`, `node ui.test.cjs`, `node kitchen.test.cjs`, `node quality.test.cjs`, `node patience.test.cjs`, `node service-hours.test.cjs`, `node arrivals.test.cjs`, `node calendar-reputation.test.cjs`.
- Relatório da versão: `projeto/RELATORIO_TESTES_0_19_0.md`.

## Novidades

Garçom anota pedidos e serve; zoom de 70% a 200%; Montagem dentro da Gestão, com sprites dos móveis no catálogo. Inclui horários configuráveis de almoço/jantar, cozinha por ações rápidas, qualidade dos alimentos e risco de queima. Salvamento local no navegador, formato 9.

Snapshot da versão publicada, origem `bcf15a3eace33f4df91f576de8230dda4d67b3d6`. Arquivos históricos em `projeto/legacy/` e relatórios anteriores mantidos para referência. Os testes registrados no relatório foram executados durante a implementação; esta importação não altera as mecânicas do jogo.
