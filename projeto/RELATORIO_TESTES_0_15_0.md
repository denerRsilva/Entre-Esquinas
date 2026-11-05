# 0.15.0 — Esquina de Casa

## Implementação autorizada

Primeira aplicação da direção de arte acolhedora e brasileira aprovada pelo proprietário. Versão anterior: 0.14.1. Não altera núcleo, regras econômicas, formato de salvamento, dimensões do mapa nem colisões. O layout continua livre e não é substituído pela imagem conceitual.

- Atlas PNG transparente original produzido com geração de imagem a partir do conceito aprovado. Fonte em `dist/assets/esquina-atlas.png`; 16 recortes: móveis, personagens e decoração. A imagem original não foi sobrescrita.
- Renderizador separado em `dist/restaurant-art.js`, independente das regras, com cache de fundo e ordenação por profundidade.
- Móveis reposicionáveis, personagens, pisos terracota/claros, paredes creme/verde, janelas, plantas, quadro e filtro decorativos nas paredes.
- Panela, chama/vapor, pratos por receita, pratos limpos instalados, utensílio e louça suja desenhados conforme o estado real.
- Grade aparece na montagem; orientação das cadeiras continua indicada por setas. Preview usa os novos sprites.
- Interface preservada com ajustes de paleta, contraste/foco e escala do texto de orientação.
- Atlas embutido no HTML de distribuição pelo build, sem depender de serviço externo de imagens. Renderização anterior permanece como fallback enquanto o atlas carrega ou em falha de carregamento.

## Evidências

- `node ui.test.cjs`: passou com renderizador novo ativo no ambiente simulado. Inclui atendimento de um clique, cozinha, bancada compacta e seletor sem pausa.
- Novas verificações de desenho: cenário mobiliado não altera o estado; todos os móveis em quatro rotações e preview desenham sem exceção; rua e personagens desenham. São testes funcionais com canvas simulado, não comparações visuais automatizadas.
- `node kitchen.test.cjs`: 16 cenários passaram.
- `node arrivals.test.cjs`: passou.
- `node --check projeto/dist/restaurant-art.js` e `git diff --check`: passaram.
- Build HTML executado com sucesso; atlas incorporado em data URI.
- Navegador desktop: cenário mobiliado inspecionado visualmente, acesso ao fogão, seleção da sopa e início do cozimento observados. Parede vertical ajustada após inspeção para evitar faixas repetidas.

## Limitações e próximos refinamentos de arte

Primeira integração, não reprodução pixel a pixel da ilustração. A escala mantém o mapa existente e por isso o ambiente é mais espaçado. Personagens utilizam sprites frontais com espelhamento e oscilação simples; ciclos direcionais completos não foram produzidos. Móveis reutilizam o sprite conforme a dimensão da pegada; vistas específicas de cada rotação ainda podem ser refinadas. Algumas ações/indicadores da interface mantêm emojis. Sem validação em celular físico, campanha longa ou benchmark de desempenho. As limitações previamente registradas na auditoria permanecem fora do escopo.
