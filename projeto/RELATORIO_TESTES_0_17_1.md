# 0.17.1 — HUD, mapa e plaquinha do serviço

Base: 0.17.0. Solicitação aprovada em 04/11/2026, conforme imagem anotada pelo usuário.

## Alterações
- Painel permanente de informações oculto.
- Turno à esquerda; data/hora e dinheiro à direita; reputação compacta preservada.
- Menu inferior sem botão Abrir almoço. Plaquinha Fechado/Aberto/Encerrando junto à porta; clique agenda aproximação antes de alternar serviço. Valida o estado do turno na chegada e impede execução duplicada.
- Canvas preenche a área de jogo sem faixas laterais. Proporção da arte preservada; limites da câmera respeitam o mapa. Conversão de cliques ajustada ao viewport.
- Montagem permite arrastar a câmera ou usar setas/WASD.

## Validação executada
- ui.test.cjs: passou. Inclui plaquinha próxima/distante, execução única, HUD, três proporções (1536x691, 1366x768 e 390x844), limites de câmera e correspondência entre posição na tela e célula do mapa. Suíte usa DOM/Canvas simulados.
- arrivals.test.cjs: passou; chegadas espaçadas, mesa exclusiva e liberação após limpeza.
- node --check restaurant-ui.js e git diff --check: passaram.
- Build HTML: gerado com sucesso.
- Navegador Chrome na prévia local: restaurante mobiliado iniciado; inspeção visual confirmou mapa sem faixas laterais, painel oculto, HUD e plaquinha. Clique na placa confirmou Almoço Aberto e ação Encerrar almoço.

## Limitações
Não executado em celular físico. Formatos de tela adicionais foram verificados por testes simulados, não por inspeção visual em cada aparelho. Arte da plaquinha é desenhada por CSS. Sem alteração de economia, regras de cozinha, chegada de clientes ou formato do save.
