# Entre Esquinas — HTML 0.8.8

PC é a plataforma principal. Esta versão HTML permite testes no navegador e no celular.
Execute `python -m http.server 8000 --directory dist` e abra http://localhost:8000.
Testes: `node test.cjs`. Sem dependências externas. Arte desenhada por Canvas.

## Mudanças da avaliação de Game Design

1. Arroz, leite e café com estoque individual em unidades, preço e custos próprios.
2. Perfis econômico (arroz/leite, 1 unidade), família (leite/arroz, 2–4) e seletivo
   (café/leite, 1–2), definidos por pesos de preferência e sorteio reproduzível.
3. Aceitação diminui com preço relativo à referência e sensibilidade do perfil.
   Falta de quantidade ou recusa por preço produz saída sem compra. Relatório por
   produto distingue esses motivos, vendas e margem. Sem substituição de produto.
4. Experimento manual/contínuo no caixa. Ambos exigem presença do jogador; manual
   continua padrão. Métricas acumuladas de toques, transações e tempo no balcão não
   equivalem a uma avaliação de diversão. Não há funcionário de caixa autônomo.
5. Ações ficam junto ao mapa; gestão em cinco abas, com pausa no menu. Seleção rápida
   de produto junto às ações. Compra e preço usam o mesmo produto selecionado.
6. Quatro melhorias independentes: carrinho, expositor ampliado, leitor de caixa e
   rotina de abastecimento (atividade adicional que deve ser atribuída ao funcionário).

## Hipóteses de balanceamento para teste

| Produto | Custo por unidade | Referência de preço | Meta no expositor |
| --- | --- | --- | --- |
| Arroz | $1 | $2 | 18 unidades |
| Leite | $1,50 | $3 | 12 unidades |
| Café | $3 | $6 | 6 unidades |

Caixa comprada: 6 unidades. Recebimento: 72 unidades compartilhadas, pallet: 108,
prateleira: 36, expositor: 36 (60 após melhoria). Metas ampliadas: 30/18/12.
Jogador: 6 unidades (18 com carrinho); funcionário: 6. Reposição prioriza menor
proporção da meta e só inicia quando há estoque no depósito. Transportar preserva
prioridade arroz/leite/café; isso ainda pode precisar de balanceamento.
Descarga automática FIFO em unidades, admitindo fração de caixa quando há espaço.
Clientes chegam a cada 5 segundos, até 6 presentes. Sem paciência/desistência na fila.
Caixa: 3 segundos por transação, ou 1,5 com leitor, independentemente da quantidade.
Custos das melhorias: $60/$80/$90/$120. Dispêndio diário: $12. Sem salário, validade,
empréstimos ou resgate financeiro. Receita usa preço reservado na cesta.

## Salvamentos e contabilidade

Chave nova `entre-mobile-08`. Sem ela, Carregar tenta importar `entre-mobile-02`:
produto genérico vira arroz, incluindo itens com jogador, funcionário, cestas e
pedidos. Mantém moeda, localização e despesas; preço antigo fora da faixa nova é
ajustado para referência ($2). Dados antigos permanecem intactos. Importação de
estado incompatível é rejeitada sem substituir a sessão atual. Histórico anterior
não existe; relatórios por produto começam na nova versão.
Compras e investimentos reduzem caixa; apenas CMV e despesa entram no lucro
operacional. Métricas de caixa são acumuladas, não reiniciadas a cada dia.

## Validação

Testes de lógica com DOM simulado cobrem legado e versão atual: conservação por
produto e por cesta, FIFO parcial, preços/demanda, perfis, atendimento sem venda
automática, pausa por afastamento, modo contínuo, melhorias combinadas, rotina,
fechamento, salvamento e migração. UI de abas e compra foi verificada no navegador
de prévia em desktop. Ainda requer playtest humano e avaliação Android real.

Arquivos legados mantêm funções de desenho e navegação e os testes de regressão.
`dist/economy.js` passa a ser a simulação ativa da 0.8 e o modelo por produto;
`dist/management.js` organiza o menu. Evitar executar a simulação legada isolada
como se fosse o estado atual do jogo.

## 0.8.1 — dois funcionários para teste

Dois funcionários disponíveis desde o início, sem custo de contratação ou salário
neste protótipo. Em Gerir loja → Logística, atribua a atividade de cada um.
Sugestão de teste: funcionário 1 Transportar e funcionário 2 Repor.
Cada funcionário carrega até seis unidades e possui posição, rota, destino e carga
independentes. Ao trocar a atividade, conclui a entrega em trânsito primeiro.
A rotina Abastecer, quando adquirida, fica disponível para ambos. O segundo usa
roupa roxa e identificação 2. Salvamentos 0.8 são atualizados ao carregar, com o
segundo funcionário parado e sem carga. Testes adicionais verificam paralelismo,
disputa pelo mesmo estoque, mudança de tarefa em trânsito e persistência.

## 0.8.2 — primeira rodada de UI/UX

Escopo aprovado: confirmações na gestão, seleções independentes, estoque real no
expositor e feedback de atendimento pausado. `selected` controla somente compras
/preços; `transportSelected` controla retirada e depósito. Consultar um produto na
gestão não muda a carga selecionada. Preferências de seleção são locais à sessão.
Confirmação de compra informa caixas, unidades, custo, saldo, quantidade recebida
e pendente no próprio menu; melhorias também confirmam custo e benefício ali.
Expositor desenha nome e quantidade por produto, cores neutras e Esgotado quando
não há unidades disponíveis (cestas de clientes não contam como estoque à venda).
Estado do caixa fica junto às ações, preservando progresso; modo contínuo exige
reativação após afastamento. Salvamentos 0.8/0.8.1 permanecem compatíveis.
Testes automatizados adicionais verificam as quatro correções e os dois modos de
caixa. No navegador desktop foram conferidos compra de café e seleção de transporte
preservada, além do expositor vazio com os três produtos esgotados. Android real e
playtest de compreensão ainda pendentes. Demais propostas de UX não implementadas.

## 0.8.3 — expositor com visual de prateleira

Móvel de madeira com três níveis, divisórias por produto e caixinhas preenchidas
conforme o estoque real. Cada caixinha representa até seis unidades; uma faixa
indica o preenchimento parcial. Quantidades exatas e Esgotado permanecem visíveis.
Desenho não modifica preços, capacidades, rotas, colisões nem salvamentos.
Verificação automática cobre representações de zero a sessenta unidades.

## 0.8.4 — cenário horizontal e menu no canto inferior esquerdo

Tela de jogo passa a ocupar a viewport, com cenário redimensionado mantendo a
proporção 800:460. O retângulo real do Canvas continua sendo a referência para
cliques/toques. Não há rolagem vertical da página durante a partida.
Botão Menu fixo no canto inferior esquerdo: ações por proximidade, carga, seleção
de transporte, abertura da loja e atalhos para as cinco abas de gestão. O painel
de ações não pausa o jogo; abrir a gestão continua pausando. A fila e mensagens
de atendimento permanecem visíveis mesmo com o menu recolhido. Escape e botão
Fechar recolhem o menu; tocar no cenário o recolhe e preserva a ação de caminhar.

Tela cheia é opcional e tenta bloquear em landscape quando suportado, sempre
por ação do usuário. Browsers que não permitem o bloqueio continuam funcionando
com rotação física do aparelho; há orientação na tela em retrato. Não usa rotação
CSS artificial nem altera o salvamento.

Verificações: suíte de simulação anterior passou. Layout do jogo foi carregado em
iframes com viewports 844×390, 1366×768 e 1920×1080 no navegador. Sem rolagem de
página, proporção preservada e botão de 105×48 px no canto inferior esquerdo nas
três medidas. Em 844×390 foram testados abrir/recolher menu, atalhos de gestão,
compra com confirmação interna e seleção da aba Logística com os dois funcionários.
A gestão cabe na viewport com rolagem interna. Tela cheia/bloqueio de orientação
em aparelho Android real não foram verificados.

## 0.8.5 — rodada 2 de UI/UX (somente apresentação)

Nenhuma regra, valor de economia, rota ou formato de salvamento foi alterado; `node test.cjs`
passa como na 0.8.4. Mudanças:
1. Cenário nítido: o canvas usa resolução interna em múltiplos de 800×460 conforme o tamanho
   da tela e a densidade de pixels, com coordenadas lógicas inalteradas. Texto deixou de ficar borrado.
2. Rótulos legíveis: nomes em etiquetas com fundo; "Pedestre" removido; títulos de sala
   removidos do cenário (já aparecem na barra superior); avisos não cobrem mais o cenário.
3. Barra superior: Dia, estado da loja (cor por estado), caixa em destaque e fila do caixa.
4. Dock inferior esquerda: Menu, Gerir e Abrir/Fechar loja (antes escondidos no menu).
5. Ações de jogo (porta, Retirar, Depositar, Atender) e carga atual ficam na tela, à direita;
   o jogo continua mostrando apenas as ações relevantes. Rótulo de porta no cenário some
   quando o jogador está perto (o botão assume).
6. Produto escolhido por botões (Arroz/Leite/Café) em vez de lista suspensa.
7. Gestão: abas com estado visível (Compras, Equipe, Melhorias, Caixa, Jogo), duas colunas
   em tela larga e botão Comprar fixo no rodapé; menu rápido em duas colunas.
8. Avisos com cor por tipo (erro em vermelho-terroso) e desaparecem sozinhos.
Limitações: não verificado em Android real; sem playtest humano; a fila de clientes
desenhada no canto direito pode ficar parcialmente atrás dos botões de ação.
Build do HTML único: `python3 build.py <saida.html>` (dentro de projeto).

## 0.8.6 — caixa contínuo por padrão

Um toque em Iniciar atendimento contínuo atende a fila e os próximos clientes,
inclusive após a fila esvaziar, enquanto o jogador permanecer no balcão.
Pausar ou sair do caixa interrompe o atendimento sem perder o progresso; ao
voltar, é necessário ativar novamente. Encerrar a entrada da loja preserva o
atendimento ativo até concluir os clientes presentes. O fim do dia desativa-o.
O seletor experimental de modos foi retirado da interface. Salvamentos anteriores
continuam válidos e passam ao modo contínuo ao carregar, aguardando ativação.
As métricas históricas de ambos os modos são preservadas.

Alterações: `dist/economy.js`, `dist/index.html`, `test.cjs` e este documento.
Suíte automatizada aprovada, incluindo fila com um toque, novas chegadas após
fila vazia, pausa por afastamento, retomada, pausa pelo botão, fechamento e
carregamento de um salvamento manual. Não verificado em aparelho Android real.

## 0.8.7 — atalho de tela cheia

Botão Fullscreen sempre visível no canto inferior direito, acima das ações de
porta, inclusive Entrar na loja. Reutiliza o fluxo de tela cheia e orientação do
menu. O rótulo acompanha a entrada/saída de tela cheia; o aviso aparece no jogo.
Alterados `dist/index.html`, `dist/landscape.js`, identificação em
`dist/economy.js` e este documento. Sem mudanças nas regras ou nos salvamentos.


## 0.8.8 — computador no estoque

Mesa com computador no canto inferior esquerdo do estoque. Toque no computador
para caminhar até ele e use Usar computador. O terminal abre Compras e preços e
Pedidos ao fornecedor, com tabela de unidades encomendadas, recebidas, pendentes
e custo de cada pedido. Compra, ajuste de preços e consulta de pedidos saem do
menu geral. A gestão comum continua oferecendo equipe, melhorias, caixa e jogo.
O terminal pausa a simulação enquanto aberto, como a gestão anterior.
Não há cancelamento nem alteração retroativa de pedidos já pagos.

A compra e a alteração de preços exigem sessão aberta junto ao computador.
Descarga automática, dinheiro, capacidades e formato dos salvamentos permanecem
iguais. Ao carregar alguém dentro da nova mesa, ele é colocado à frente dela.
Testes incluem acesso por sala/proximidade, isolamento dos menus, compra, preço,
consulta, conservação, navegação e transporte/reposição com os dois funcionários.
Arquivos: `dist/computer.js`, `dist/management.js`, `dist/index.html`,
`dist/landscape.css`, identificação em `dist/economy.js`, `test.cjs` e README.
Verificação no navegador: percurso rua → loja → estoque → computador, ausência de
compras no menu geral, pedido de 5 caixas de arroz (30 unidades), confirmação no
terminal, tabela de recebimento e ajuste de preço de $2 para $2,25. Não testado
em aparelho Android real.
