# Entre Esquinas 0.14.1 — Bancada simplificada

## Escopo autorizado

Implementar a melhoria da mesa de preparo proposta na auditoria: ações principais destacadas, itens instalados visíveis e manutenção secundária. Mantidos núcleo, economia, duração do preparo, formato de save e regras de funcionários. Não inclui as demais recomendações da auditoria nem revisão integral do GDD.

## Alterações

- Painel compacto junto à interação da bancada, sem modal e sem pausa da simulação.
- Empratar e Retirar prato em destaque; seleção inline somente quando existem várias receitas elegíveis.
- Slots ilustrados de pratos e talher; reposição diretamente no slot.
- Quantidade de comida pronta discriminada por receita, capacidade e orientação contextual.
- Mover, guardar, retirar utensílio/pratos e retirar pedido na mão em Mais opções.
- Devolução de pedido cancelado e cancelamento de empratamento aparecem conforme a situação.
- Atalho E prioriza operação da bancada, em vez do botão Fechar.
- Guia interno e identificação de versão atualizados.

## Testes executados

- `node ui.test.cjs`: passou; inclui suíte de um clique, cozinha e novos cenários de painel, manutenção recolhida, ações desabilitadas, dois tipos de panela, empratamento e retirada por receita sem abrir modal.
- `node kitchen.test.cjs`: 16 cenários passaram, incluindo falta de espaço, conservação, migração, cancelamento e garçom.
- `node arrivals.test.cjs`: passou; chegadas espaçadas, mesa exclusiva e liberação após limpeza.
- `node --check projeto/dist/restaurant-ui.js` e `git diff --check`: passaram a partir da raiz.
- `python3 build.py ../dist/index.html`: empacotamento concluído a partir de projeto/.
- Navegador desktop: painel inspecionado visualmente; Mais opções expandiu; retirada de 12 pratos exibiu falta de pratos; clique no slot reinstalou os 12; relógio continuou avançando com o painel aberto.

## Limitações

Sem validação em celular físico. CSS contempla telas estreitas e baixas, mas precisa de playtest de toque. As suítes de paciência/calendário não foram reexecutadas nesta alteração restrita de interface. Defeitos e limitações identificados na auditoria, incluindo limite de histórico e economia provisória, não foram alterados.
