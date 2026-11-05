# 0.19.0 — Garçom, zoom e catálogo visual

Data: 05/11/2026. Base recuperada do repositório do Site: 0.18.0, commit c386c422b176518069838c9fd6d0dee9b67affdc.

## Implementação
- Operação takeOrder compartilhada entre jogador e garçom. Guardas de estado, proximidade, movimento e paciência impedem anotação distante, duplicada ou após abandono. Garçom mantém transporte/serviço existentes e busca clientes aguardando quando não há prato disponível para entregar. Rotas até clientes e bancada exigem acesso possível.
- Zoom mínimo alterado para 70%, com 80% e 90% e armazenamento da preferência existente. Projeção inversa de cliques preservada. Cenário centralizado quando menor que a área visível; fundo decorativo preenche o entorno. Cliques fora do mapa não geram objetivos de movimento.
- Montagem dentro da Gestão. Catálogo usa recortes do atlas existente, com proporção preservada, nomes acessíveis e desenho após carregamento da imagem. Nove itens com sprite. Botão inferior removido e instruções de acesso atualizadas.

## Testes executados
- waiter-orders.test.cjs: passou. Anotação autônoma junto ao cliente, transição de paciência, retirada/serviço/pagamento, função Parado, dois garçons sem duplicação e rejeição no limite de paciência.
- ui.test.cjs: passou. Fluxo Gestão → Montagem → Gestão; nove sprites; ausência do botão inferior; zoom 90/80/70% em 1536x691, 1366x768 e 390x844; conversão dos cliques; bloqueio fora do mapa; demais regressões da interface.
- kitchen.test.cjs: 16 cenários passaram.
- quality.test.cjs: 15 cenários passaram.
- patience.test.cjs: 15 cenários passaram.
- calendar-reputation.test.cjs: 12 cenários passaram.
- service-hours.test.cjs e arrivals.test.cjs: passaram.
- Sintaxe dos JS alterados, git diff --check e build HTML: passaram.
- Chrome na prévia local: iniciou mobiliado, afastou três passos até 70%, abriu Gestão → Montagem. Inspeção visual confirmou restaurante inteiro no enquadramento e sprites de móveis no catálogo.

## Limitações
Sem teste em celular físico ou playtest humano desta versão. Automação do garçom verificada por simulação real do código; navegador usado para QA visual do zoom/catálogo. A prioridade do garçom ainda precisa de avaliação de ritmo com vários clientes. Área revelada fora do mapa é somente fundo decorativo; não amplia o restaurante nem a cidade. Configuração de acesso do Site preservada, incluindo o visitante autorizado.
