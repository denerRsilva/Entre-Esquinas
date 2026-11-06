# Entre Esquinas — Restaurante 0.21.2

Cozinheira do jogador usa a nova folha de 16 poses, quatro direções e quatro fases de caminhada. A imagem gerada de 1254 × 1254 é recortada em grade 4 × 4 e normalizada uma vez no carregamento para células 64 × 64, sem suavização. Parada usa a segunda pose da direção mantida. Essa normalização não substitui retoque artístico manual dos quadros.

# Entre Esquinas — Restaurante 0.21.1

Tela inicial compacta com botão Tutorial junto às opções de começar. As instruções ficam recolhidas até a escolha do jogador.

# Entre Esquinas — Restaurante 0.21.0

Interface de gestão, opções, inventários, computador e construção com molduras de madeira e abas douradas. A loja e a mochila usam as ilustrações de utensílios da prévia aprovada. O catálogo lateral reúne sprite, preço, setor e posicionamento de cada móvel.

# Entre Esquinas — Restaurante 0.20.2

Mover, girar e guardar/reembolsar móveis ficam exclusivamente no Modo construção. Clique no objeto instalado em qualquer setor do restaurante, sem aproximar o personagem; escolha nova posição e confirme. Cancelar preserva a posição original. Guardar e reembolsar aparece somente para objeto já instalado; continua impedido quando há itens, preparo ou louça que precisam ser retirados. Áreas permitidas, colisão e bloqueio durante serviço preservados. Computador e recebimento continuam infraestruturas fixas.

Validação: `RELATORIO_TESTES_0_20_2.md`.

# Entre Esquinas — Restaurante 0.20.1

Compra de panela, talher e pratos transferida do Modo construção para Computador → Utensílios. Cada cartão tem uma arte em pixels, preço e quantidade na mochila; saldo disponível acima. Panela e prato reutilizam a renderização do cenário; talher segue sua paleta. Custos, capacidade, destino imediato na mochila e funcionamento da cozinha preservados. Construção mostra somente Móveis.

Validação: `RELATORIO_TESTES_0_20_1.md`.

# Entre Esquinas — Restaurante 0.20.0

Gestão → Modo construção pausa a simulação inteira e oculta a HUD operacional. O modo inicia com catálogo recolhido: o botão Construção abre/fecha o painel lateral, com móveis, sprites, preços e saldo. Selecionar um móvel recolhe o painel para posicionamento. A cobrança ocorre ao confirmar uma posição válida; cancelar não compra. Confirmar/cancelar continua no modo pausado. Voltar ao jogo fica no painel; Escape cancela a colocação, recolhe o painel ou sai do modo, nessa ordem. Arrastar o cenário ou WASD/setas move a câmera sem mover o personagem. Serviço em andamento continua impedindo reformas. Receitas, preços, saves e regras físicas preservados.

Validação: `RELATORIO_TESTES_0_20_0.md`.

# Entre Esquinas — Restaurante 0.19.0

- Garçom: a função em Gestão → Equipe agora anota pedidos nas mesas e serve pratos. Pratos disponíveis têm prioridade; sem prato para levar, procura clientes aguardando pedido, priorizando menor paciência restante entre os acessíveis. A anotação exige presença física, respeita a paciência e usa a mesma operação do jogador, impedindo pedidos duplicados. Trocar para Parado interrompe novas tarefas; pratos em trânsito seguem as regras anteriores.
- Zoom: mínimo 70%, com passos de 10% até 200%. Preferência preservada no navegador. A câmera centraliza o cenário quando toda uma dimensão do mapa cabe na tela. O fundo fora do mapa é decorativo e não caminhável.
- Montagem removida do menu inferior. Acesso em Gestão → Montagem, com retorno à Gestão. O catálogo de nove móveis mostra a própria sprite usada no cenário, sem alterar preços, tamanhos ou regras de posicionamento.

Validação desta versão: RELATORIO_TESTES_0_19_0.md. Save formato 9 preservado. Os registros abaixo são históricos.

# Entre Esquinas — Restaurante 0.18.0

## Câmera, menus e horários dos serviços
- Visão inicial mais ampla. Botões −/+ e Opções → Câmera ajustam o zoom entre 100% e 200%. Preferência preservada neste navegador. O limite mais aberto respeita a proporção da tela e evita áreas vazias fora do mapa.
- Gestão: Turnos, Equipe, Fechamento, Clientes, Calendário e Reputação.
- Opções: Câmera, Salvar e carregar, Testes e Primeiros passos.
- Gestão → Turnos define início/término do almoço e jantar, em blocos de 10 minutos entre 06:00 e 02:00. Horários sem sobreposição; alteração bloqueada durante serviço pendente. Padrão inicial: almoço 11:00–15:00 e jantar 18:00–22:00.
- Abertura manual na plaquinha, somente durante o horário. No término, suspendem-se entradas e concluem-se clientes/preparos pendentes. Fechar manualmente não alterna almoço/jantar; reabertura permitida no mesmo período. O turno acompanha o relógio, sem adiantar hora ou data.
- Horários persistidos no salvamento existente (formato 9); saves sem horários recebem o padrão em cópia. Horários inválidos são recusados. Nenhuma alteração no arquivo antigo antes de salvar.

Validação: RELATORIO_TESTES_0_18_0.md. Registros abaixo descrevem versões anteriores.

# Entre Esquinas — Restaurante 0.17.1

## Interface e acesso ao serviço
Turno no canto superior esquerdo; data/hora no canto superior direito, com dinheiro ao lado. Reputação permanece compacta junto do turno. O painel permanente de informações sobre o cenário fica oculto; avisos temporários e ações dos objetos permanecem disponíveis.

A plaquinha junto à porta substitui o botão de serviço do menu inferior. Um clique faz o personagem se aproximar e abrir/encerrar o turno pelas regras existentes. O texto indica Fechado, Aberto ou Encerrando. A placa acompanha sua posição no cenário.

O canvas ocupa a área disponível, preservando a proporção da arte e limitando a câmera às bordas do mapa. Na montagem, arrastar ou usar as setas/WASD permite acessar as partes fora do enquadramento. Save formato 9 e regras de cozinha/clientes preservados.

Validação da versão: RELATORIO_TESTES_0_17_1.md. As seções abaixo são registros históricos, superados pelas versões posteriores.

# Entre Esquinas Restaurante 0.13.0

## Cozinha por ações rápidas
Ingredientes ficam na mochila. Instale uma panela vazia no fogão, escolha a receita e inicie. A barra de cozimento avança sem exigir proximidade. Ao concluir, retire a panela cheia para a mochila. Instale pratos limpos e um talher reutilizável na bancada. Com a panela na mochila, use Empratar; acompanhe a barra por 2 segundos junto da bancada. A panela vazia ou com sobras continua na mochila. Os pratos prontos ficam na bancada para retirada pelo jogador ou garçom.

Fogão e bancada não possuem inventários genéricos nem botões para abrir inventário. Instalação e retirada têm ações com rótulos e confirmação visual; cozimento e empratamento têm barras no cenário e indicador acessível. Guardar/mover preserva os encaixes; guardar exige retirar os itens, e mover equipamento em preparo é bloqueado.

Os tempos de receita e lotes de 4 permanecem; empratamento leva 2 segundos, pratos limpos até 99 e área de retirada até 12 pratos são parâmetros de teste em KITCHEN_CONFIG. Sem espaço, itens permanecem na origem. Empratamento parcial conserva porções. A colher é instalada na bancada, não no fogão. Pia, lixo e armazenamento mantêm suas regras.

## Saves
Formato 7, chave entre-restaurante-07. Carregar oferece fallback 06, 05 e 04 em cópia; nunca apaga o save anterior. Relógio, reputação e visitas da 0.12.0 permanecem. A migração instala uma panela, pratos e talher; demais itens dos antigos inventários vão à mochila. Excedentes permanecem em uma reserva de migração acessível por Inventário → Recolher itens preservados. Isso não é armazenamento de gameplay novo e não é abastecido pela operação normal.

## Validar e gerar HTML
Execute na pasta projeto:
- node restaurant.test.cjs
- node patience.test.cjs
- node calendar-reputation.test.cjs
- node ui.test.cjs
- python3 build.py ../dist/index.html

O HTML único em ../dist/index.html é o arquivo publicado. Testes de UI usam DOM/Canvas simulados. Testes de comportamento não provam diversão; Android real e playtest humano da nova versão continuam pendentes.

## Histórico anterior
Os requisitos abaixo descrevem as versões anteriores e são superados pelas regras da 0.13.0 acima.

# Entre Esquinas — Restaurante 0.12.0

## Alteração 0.12.0 — tempo, calendário e reputação
Base inspecionada: 0.11.0, JavaScript/Canvas sem framework. Reutilizados o estado global, step/dt, satisfação das visitas, eventos, encerramento e movimentação existentes. Sem dependências novas.

Relógio de 06:00 até 02:00 da madrugada seguinte, em blocos de 10 minutos por 7 segundos ativos. O frame usa o tempo ativo real e subdivide a simulação em passos de até 80 ms; um frame lento não perde o tempo decorrido. Menus, início, montagem e aba oculta congelam toda a simulação. A mesma fonte dt avança segundos de simulação, relógio, cozinha, entregas e paciência. As durações existentes de preparo e paciência permanecem em segundos ativos; não foram multiplicadas pela escala do calendário.

Calendário: 28 dias por estação, Primavera/Verão/Outono/Inverno, sete dias da semana, ano iniciando no dia 1 de Primavera, segunda-feira. A data representa o dia jogável: 23:50 → 00:00 mantém a mesma data, e a virada ocorre quando o próximo dia começa às 06:00. O número acumulado de dias continua em state.day; mês/estação/ano/semana são derivados para não divergir.

Regra das 02:00 definida pelo usuário: concluir o serviço. Novas chegadas param; horário fica em 02:00, mas o mesmo tempo de simulação continua movendo personagens, preparos, entregas e paciência até concluir o serviço ou os clientes desistirem pelas regras existentes. Preparo pausado por distância continua exigindo aproximação do jogador. A virada preserva objetos, inventários, louça, ingredientes, cargos, posições e entregas. Não há penalidade de sono nem cancelamento forçado. Sem pendências, a virada é imediata.

Conflito resolvido: fechar o jantar deixava avançar a data na 0.11.0. Agora almoço/jantar apenas alternam o serviço manual, sem avançar a data. O calendário é a única autoridade sobre o dia. O fechamento financeiro e a despesa existente de $12/dia são lançados uma vez na virada do calendário, inclusive se o dia tiver terminado sem abrir o restaurante; não há cobranças adicionais por sono. Abertura continua livre, sem novas janelas de horário. Não foi imposta restrição adicional para repetir serviços dentro do mesmo dia.

Reputação: 0–100, cinco níveis da especificação, início provisório em 0. Elogio +1, reclamação −1, abandono −1. Uma visita gera no máximo um impacto: abandono tem prioridade sobre a reclamação da mesma visita. O abandono sem manifestação verbal também registra o resultado negativo; as probabilidades anteriores de manifestação continuam iguais. Visitas concluídas sem elogio/reclamação não mudam a pontuação. O histórico armazena valor anterior, solicitado, aplicado e posterior; nos limites 0/100, o impacto aplicado pode ser zero. IDs processados impedem replay mesmo quando não houve manifestação ou o impacto foi zero. O score fica disponível ao futuro sistema de demanda, mas nenhum multiplicador/intervalo de chegada/preço foi alterado.

TIME_CONFIG e REPUTATION_CONFIG, no início de dist/restaurant-core.js, centralizam parâmetros. HUD mostra horário, dia da semana, dia da estação, estação, ano e reputação/nível. Gestão → Calendário/Reputação traz detalhes e os últimos 20 impactos. O save conserva o histórico completo.

Save formato 6, chave entre-restaurante-06, com fallback para 05/04. Migração em cópia preserva o dia acumulado, objetos e a satisfação/paciência da 0.11.0. O dia migrado começa às 06:00 e a reputação em 0; registros antigos são marcados processados sem reaplicar pontuação. O save original permanece preservado. A limpeza provisória conserva data/horário, reputação e históricos.

Relatório atual: RELATORIO_TESTES_0_12_0.md. Quatro suítes: restaurant.test.cjs, patience.test.cjs, calendar-reputation.test.cjs e ui.test.cjs.

## Alteração 0.11.0 — paciência e satisfação v1.0
Integra a especificação do Game Designer sobre a base 0.10.4. Cada cliente recebe perfil sorteado e limites individuais de atendimento/comida. O atendimento começa ao chegar ao assento; a espera da comida começa ao registrar o pedido. Somente uma etapa fica ativa. O tempo usa exclusivamente `step(state, dt)`, respeitando as pausas já existentes da UI. No instante exato de esgotamento, a desistência precede qualquer entrega do mesmo passo lógico.

Indicadores acima dos clientes: ⏳ acima de 50%, ❗ acima de 20% até 50%, 😠 acima de zero até 20%, 🤬 ao desistir, 😊 para satisfação positiva após a entrega. O HUD mostra os segundos restantes, e Gestão → Clientes mostra perfis, etapas e últimas 20 visitas. O histórico completo continua no save. Os botões de ação próximos aos clientes foram elevados para reduzir sobreposição com emojis.

Não existe qualidade culinária: as duas esperas recebem peso efetivo 50% cada. A pontuação de 0–100 usa a fração de paciência restante em cada etapa. Classificações provisórias: muito satisfeito ≥85, satisfeito ≥65, neutro ≥40, insatisfeito abaixo de 40. Distribuição inicial provisória dos perfis: pesos 1:1:1. Os parâmetros ficam em `CUSTOMER_CONFIG`, no início de `dist/restaurant-core.js`: faixas, pesos relativos, limiares, pesos de satisfação, classes, probabilidades, emojis, tamanho e duração. 😊 dura 8 segundos de simulação após a entrega; 🤬 permanece até a saída por padrão. Os demais ícones acompanham a fase ativa.

Elogios/reclamações são registros isolados, sem efeitos sobre demanda, preços, economia ou quantidade de clientes. As probabilidades são as da especificação. Cada visita faz uma única tentativa de avaliação: nenhuma manifestação também marca a avaliação como resolvida. Abandono registra a visita imediatamente; visita atendida registra após concluir a refeição. A satisfação é calculada na entrega e os tempos não continuam ao comer/sair.

Desistência cancela o pedido e a prioridade, impede pagamento e novas entregas ao cliente, e usa a rota de saída existente. Ingredientes consumidos e panelas em preparo continuam no ciclo físico; não há estorno. Um prato já na mão permanece conservado e ligado ao pedido cancelado: o garçom o devolve fisicamente à bancada; o jogador usa o mesmo botão 🛎️ na bancada para devolvê-lo, ou a ação existente de servir para outro pedido da mesma receita. Bancada cheia mantém o prato na mão, sem perda. Pedidos cancelados não aparecem como ativos no HUD nem bloqueiam o fechamento. A conclusão do preparo em andamento continua sendo necessária no fechamento, conforme a lógica anterior.

Formato de save 5, chave `entre-restaurante-05`. Carregar tenta essa chave e, quando ausente, a chave anterior `entre-restaurante-04`. Migração copia e valida o estado sem sobrescrever o original: clientes da partida antiga recebem novos limites e o contador da etapa atual começa em zero. Visitas já iniciadas na versão anterior não geram notas ou avaliações inventadas; novos clientes usam o sistema completo. Saves com dados inválidos são recusados preservando a partida atual. A ferramenta provisória de limpeza mantém históricos e registros, mas cancela as visitas ativas junto do serviço, sem criar reclamações por limpeza de teste.

Consulte `RELATORIO_TESTES_0_11_0.md` para cenários, resultados e limites de verificação.

## Alteração 0.10.4 — ferramentas de teste
Na janela inicial, escolha Começar mobiliado (teste) ou Começar vazio. Cenário gratuito com 3 mesas e 12 cadeiras voltadas às mesas, fogão, geladeira de cozinha, mesa de preparo, pia, lixo, prateleira e geladeira no estoque. Fogão recebe 30 de cada ingrediente, 3 panelas e 1 colher; bancada recebe 12 pratos e outra colher. Caixa inicial permanece $1500. Sem mudança nas receitas, custos ou regras da partida vazia.
Em Gestão → Testes, o botão provisório Excluir todos os móveis e limpar inventários remove objetos e todos os itens, inclusive mochila, recebimento e cargas em trânsito. Cancela o serviço, clientes, pedidos, entregas pendentes e preparos; reinicia as posições de personagens. Preserva dinheiro, dia, preços, cardápio, vínculos e relatórios, sem reembolso. Contadores de conservação de recursos são reiniciados junto dos itens, mantendo o estado salvável. Não sobrescreve o salvamento automaticamente. Formato 4 e chave de salvamento mantidos.
Arquivos desta alteração: dist/restaurant-core.js, dist/restaurant-ui.js, dist/index.html, restaurant.test.cjs, ui.test.cjs e README.md.

## Alteração 0.10.3 — janela inicial e contraste
Retirado o link para a mercearia da janela inicial. A janela informa explicitamente a versão 0.10.3. A quantidade dos itens nos espaços de inventário passa a ser preta, tanto na mochila quanto nos móveis. Salvamento mantido.

## Alteração 0.10.2 — abertura por decisão do jogador
O jogador pode abrir o restaurante vazio ou com qualquer configuração. Não há exigência de móveis, cozinha, utensílios, ingredientes ou pratos prontos para abrir almoço/jantar. O cardápio pode ficar completamente vazio. O aviso de montagem incompleta foi retirado do HUD.
As tarefas físicas mantêm seus requisitos: cozinhar precisa dos itens no fogão, servir precisa de comida e clientes precisam de assentos. Sem lugar ou cardápio, a tentativa de chegada é contabilizada como perda, sem criar clientes/pedidos inválidos. O fechamento mantém a conclusão dos clientes já presentes.
Formato/chave de salvamento da 0.10.0/0.10.1 preservados. Testes cobrem abertura vazia, ausência de equipamentos/utensílios/comida, cardápio vazio, dois serviços e clientes com mesas mas sem cozinha.

## Alteração 0.10.1 — seleção por clique
Ícones só aparecem para o objeto clicado/tocado, depois que o personagem estiver próximo. Aproximação sem seleção não exibe ações. Clicar no chão cancela a seleção; clicar em outro objeto substitui o alvo. Computador, recebimento e ações de atendimento seguem a mesma regra. Várias ações do mesmo alvo permanecem na mesma fileira.
Salvamentos da 0.10.0 continuam compatíveis; não é necessário começar uma partida nova.

## Novo ciclo aprovado
1. Instale fogão, mesa de preparo, pia e lixo pela opção Montar. Mesa/cadeira e geladeira da cozinha continuam presentes no protótipo.
2. Compre panelas, colheres e pratos limpos em Montar → Panela e utensílio. Sugestão: 1 panela, 2 colheres, 4 pratos.
3. Compre ingredientes no computador e recolha-os no recebimento.
4. Coloque todos os ingredientes do lote, uma panela vazia e uma colher DENTRO do fogão. Geladeira e mochila não abastecem receitas automaticamente.
5. No ícone de fogo acima do fogão, escolha a receita. Cada lote produz quatro porções e consome quatro vezes os ingredientes da porção anterior, para manter o custo por prato. O painel mostra as quantidades exatas.
6. Volte ao jogo e permaneça perto do fogão até concluir. A panela vira um item de comida com quatro porções. Enquanto cozinha, não pode ser retirada; uma panela com comida não pode cozinhar outro lote.
7. Leve a panela cheia à mesa de preparo, junto de pratos limpos e uma colher. Use Empratar. O comando produz até quatro pratos conforme a quantidade de pratos disponíveis. Sobras ficam na panela; a última porção devolve uma panela vazia.
8. Retire os pratos prontos para a mochila, anote pedidos e sirva próximo ao cliente. Ou retire um pedido na mão pela mesa de preparo; o garçom também serve pratos compatíveis dessa mesa.
9. Depois de comer, o cliente deixa um prato sujo na mesa. Recolha-o pelo ícone de limpeza, coloque na pia e lave. O prato limpo pode voltar à mesa de preparo.
10. Para esvaziar uma panela sem empratar, coloque-a no inventário da pia ou do lixo e use Descartar. Isso elimina as porções restantes e devolve a panela vazia. Descartar comida de um prato devolve um prato sujo; descarte de prato é feito no lixo.

## Ícones e inventários
Botões contextuais ficam em fileiras acima do objeto selecionado, quando próximo. Ícones com descrição acessível e tooltip: inventário, cozinhar, empratar, retirar pedido, lavar, descartar, mover, guardar. Recebimento e computador também têm suas ações sobre o ponto correspondente.
Inventários continuam com dez espaços, até 99 unidades por pilha. Panelas cheias e em preparo são unitárias para preservar a quantidade exata de porções. Na janela dividida, ajuste Quantidade por transferência para 1 quando precisar separar colheres ou panelas de uma pilha. A quantidade padrão é 99 (até a pilha toda).
Geladeiras aceitam alimentos refrigerados; prateleiras aceitam ingredientes secos. Fogão aceita todos os ingredientes e os itens de preparo. Mesa de preparo aceita panela, comida, pratos limpos e colher. Pia recebe louça e panelas; lixo recebe comida para descarte e devolve recipientes.

## Parâmetros de protótipo
Mesa de preparo $90, pia $70, lixo $25, prato limpo $5, panela $25, colher $15. Mesmos preços das receitas e tempos de 5–8 segundos por lote. Um lote de cada vez; cozinhar pausa quando o jogador sai do fogão ou retira a colher. Empratar/lavar são ações imediatas nesta versão. Panelas vazias e colheres não exigem lavagem nesta etapa.
Funcionários de logística continuam transportando ingredientes; garçom retira pratos já empratados, sem cozinhar ou lavar automaticamente. Nenhum conteúdo narrativo ou personagem novo.

## Salvamentos
Formato atual 6, chave entre-restaurante-06. Salvamentos válidos da 0.11.0 (formato 5, chave 05) e 0.10.x (formato 4, chave 04) são migrados em cópia, mantendo os anteriores preservados. Os salvamentos 0.9.3/0.9.4 permanecem preservados em sua chave anterior, sem conversão automática.

## Verificações executadas
- node restaurant.test.cjs: ingredientes fora do fogão rejeitados; panela/colher obrigatórias; bloqueio da panela em preparo; pausa por distância; quatro porções; empratamento parcial e completo; almoço/jantar com serviço presencial; coleta e lavagem de pratos; descarte de panela na pia e lixo; garçom retirando na bancada; separação de colheres; inventário cheio sem perda; conservação de ingredientes, panelas, colheres, pratos e porções; salvamento inclusive durante preparo.
- node ui.test.cjs: seleção exclusiva por clique, ausência de ícones só por proximidade, ocultação ao clicar no chão e seleção separada de computador/recebimento; UI com DOM/Canvas simulados; ícones e agrupamento acima dos móveis; seleção da receita e requisitos; janela dividida; quantidade por transferência; início e conclusão do preparo via interface; prévias dos novos objetos.
- Sintaxe dos scripts e integridade do HTML único/ZIP verificadas no empacotamento.
Android real e playtest humano permanecem pendentes. A prévia em navegador pode verificar visualmente a interface, mas não substitui testar a sensação de jogar.

## Arquivos alterados
- dist/restaurant-core.js: objetos e itens novos, estados de panelas/pratos, cozinha, empratamento, limpeza, descarte, serviço/garçom, validação e contabilidade de itens.
- dist/restaurant-ui.js, dist/restaurant.css, dist/index.html: ações sobre o cenário, menus operacionais, ícones e instruções.
- restaurant.test.cjs, ui.test.cjs: verificações do novo ciclo.
- README.md, LEIA_ME.txt e MIGRACAO_RESTAURANTE.md: regras e transferência.
A base de mercearia preservada não sofreu alterações.
