# Entre Esquinas — Restaurante HTML 0.9.1

Adaptação jogável inicial do GDD Restaurante v1.3, incluindo as atualizações 1.2 e 1.3 que prevalecem sobre o texto-base 1.1. PC continua sendo a plataforma principal; HTML permite testes no celular. Referências de direção: Stardew Valley, Travellers Rest e Chef RPG.

## Executar e verificar

Abra `dist/index.html` ou execute `python3 -m http.server 8000 --directory dist`.
Testes do restaurante: `node restaurant.test.cjs`.
Regressão da mercearia preservada: `node test.cjs`.
Sem dependências externas. Arte esquemática por Canvas.

## O que esta versão permite testar

- Restaurante inicialmente vazio, separado em salão e cozinha; estoque em outra sala; rua com três moradores de demonstração.
- Montagem livre em grade lógica de 24 × 16 células. Célula-base de 40 pixels, ajustada à tela. Rotação, prévia válida/inválida, confirmação, movimento e reembolso de móveis fora do serviço.
- Mesa, cadeira orientada para a mesa, fogão, geladeira de cozinha, prateleira seca e geladeira de estoque. Panela e utensílio adquiridos separadamente.
- Personagens ocupam células exclusivas. Rotas cardinais contornam móveis; NPCs aguardam/recuam em passagem estreita. O jogador parado não é empurrado automaticamente.
- Três ingredientes e três pratos. Recebimento limitado, armazenamento seco/refrigerado, transporte físico até a cozinha, consumo rastreado por receita.
- Pedidos nas mesas, prioridade de preparo, fogão presencial contínuo, retirada/serviço, consumo, pagamento e saída.
- Almoço → intervalo → jantar → relatório diário. O fechamento interrompe novas entradas e espera os clientes presentes.
- Dois funcionários gratuitos de teste, inicialmente parados; funções contínuas de logística ou serviço. A carga em trânsito é entregue antes da troca de função.
- Computador no estoque para fornecedor, entregas, cardápio e preços. Gestão e construção pausam a simulação.
- Toque/clique no mapa, WASD/setas no PC e E para primeira ação próxima. Atalho Fullscreen; orientação horizontal recomendada.
- Salvamento próprio: `entre-restaurante-01`. Validação antes de salvar/carregar; estado inválido preserva a sessão atual.

## Como montar e jogar

1. Entre no restaurante. Em Montar, escolha Mesa e coloque no salão (lado esquerdo). Coloque uma Cadeira encostada na mesa e gire a seta para apontar para ela. Deixe acesso pelo outro lado da cadeira.
2. Coloque Fogão e Geladeira na cozinha (lado direito). Em Panela e utensílio, compre os dois.
3. Atravesse a porta para o estoque. Instale Prateleira seca e Geladeira do estoque.
4. Use o computador: compre arroz, legumes e frango. A entrega avança ao voltar ao jogo. O recebimento fica junto do computador.
5. Transporte em cargas de quatro unidades: recebimento → armazenamento adequado → cozinha. Na cozinha, arroz fica no abastecimento do fogão; legumes/frango na geladeira. Ou atribua Logística a um funcionário.
6. Abra o almoço. Aproxime-se de cada cliente sentado e anote o pedido. Vá ao fogão e ative Cozinhar continuamente; permaneça perto para avançar.
7. Retire o prato e sirva à mesa correspondente. Um funcionário em Garçom pode retirar e servir os pratos prontos. O cliente paga após comer.
8. Encerre a entrada, conclua os presentes, prepare o intervalo e abra o jantar. O relatório diário sai depois do jantar.

## Parâmetros provisórios e limites

As opções necessárias para testar pontos ainda abertos do GDD não se tornam decisões definitivas:

- Células lógicas de 40 px; rotas cardinais/diagonais com posições contínuas durante a caminhada; uma pessoa por passagem. NPCs usam espera/replanejamento/recuo; ainda requer testes de multidões e layouts extremos.
- Construção apenas sem serviço/clientes/pedidos ativos e com tempo pausado. Mover é gratuito, guardar reembolsa integralmente. Equipamentos com ingredientes precisam ser esvaziados antes de guardar.
- Mesas 2 × 1, cadeiras 1 × 1; cada cadeira orientada e acessível conta um assento. Mesas maiores, grupos e reserva de mesas não foram implementados.
- Capital inicial $1.500. Mesa $45, cadeira $15, fogão $150, geladeira de cozinha $120, prateleira $65, geladeira de estoque $140, panela $25, utensílio $15.
- Arroz $2/un., legumes $2/un., frango $4/un. Entrega em 5 segundos de jogo, com descarga parcial e limite de 60 unidades no recebimento.
- Cada prateleira/geladeira de estoque soma 40 unidades do tipo adequado. Cada geladeira de cozinha soma 20 refrigeradas; cada fogão permite abastecer 20 secas. Utensílios não são itens de transporte.
- Arroz com legumes: 1 arroz + 1 legumes, 6 s, $14. Sopa: 2 legumes, 5 s, $12. Frango com arroz: 1 arroz + 1 frango, 8 s, $20. Um pedido é preparado por vez; pedidos disputam esse recurso.
- Clientes chegam a cada 12 s enquanto aberto. Sem lugar, a chegada conta como perda de capacidade. Não há fila externa nem abandono por paciência. Sem efeito de preço na demanda nesta adaptação.
- Pagamento após consumo é automático; não há caixa de mercearia no restaurante.
- Dois serviços encerrados manualmente, sem relógio/horários oficiais. Despesa de teste de $12 após o jantar; sem falência, salários ou contratação paga.
- Conversas de Lia, Beto e Nina são textos fictícios de demonstração e contador simples de vínculo diário. Não desbloqueiam receitas/fornecedores e ainda não alteram a economia. Não há rotinas urbanas, eventos, concorrência ou narrativa implementada.
- Validade, desperdício, freezer, câmara fria, múltiplas técnicas/estações, progressão detalhada, qualidade, satisfação e arte final continuam pendentes. Comprar mais fogões não adiciona preparo paralelo nesta versão.

## Reaproveitamento e preservação

Reutilizados os princípios técnicos do protótipo: Canvas sem assets externos, navegação por toque, ações por proximidade, computador administrativo, entrega limitada, contabilidade/conservação, tarefas contínuas, fullscreen e gestão pausada. O núcleo foi separado em `restaurant-core.js` porque a ocupação dinâmica e a construção livre exigem uma grade consistente.

A mercearia 0.8.8 foi copiada integralmente para `dist/mercearia-0.8.8/`; seus scripts originais e testes permanecem. O histórico técnico está em `legacy/README.md`. Os salvamentos antigos não são apagados nem convertidos. A economia e os funcionários anteriores não são regras definitivas do restaurante.

## Arquivos novos e alterados

- `dist/index.html`: entrada do restaurante, orientação e controles.
- `dist/restaurant-core.js`: grade, montagem, circulação, ingredientes, receitas, clientes, serviços, contabilidade e validação.
- `dist/restaurant-ui.js` e `dist/restaurant.css`: desenho, ações, menus, construção e salvamento.
- `restaurant.test.cjs`: testes do novo ciclo e da circulação.
- `MIGRACAO_RESTAURANTE.md`: rastreabilidade, decisões abertas e transferência a Game Design/QA.
- `dist/mercearia-0.8.8/` e `legacy/`: cópia preservada do protótipo anterior.

## Verificação

Passaram os testes automatizados do restaurante e da mercearia. O teste do restaurante completa almoço e jantar com ações presenciais, consumo conservado, garçom, pagamento e resultado diário; também cobre construção, rejeição sem cobrança, rotação de cadeira, transporte e salvamento inválido. O teste de corredor força passagem única com NPCs em sentidos opostos, sem sobreposição nem impasse nesse cenário.

Verificação de navegador em desktop: orientação inicial, navegação rua/restaurante, catálogo, prévia e compra/posição de mesa, cadeira girada reconhecida como assento e salvar/carregar o layout. O ciclo completo foi verificado em simulação automatizada, não em playtest humano. Android real, conforto em telas pequenas, balanceamento e estresse de multidões não foram verificados.


## 0.9.1 — movimento fluido

Pedido aprovado: remover a sensação de caminhar num tabuleiro. A grade não é mais
traçada durante a partida: aparece apenas no modo de montagem. Móveis continuam
alinhados à grade e conservam sua área de colisão.

O caminho aceita diagonais, bloqueando cortes pelas quinas de paredes/móveis.
O deslocamento é atualizado a cada quadro com posições fracionárias e velocidade
constante em distância, incluindo a diagonal. Jogador, clientes e funcionários
compartilham esse movimento; recuos também são animados. O teclado aceita teclas
mantidas e combinações de direção. Ao soltar, conclui o pequeno trecho em andamento
(até cerca de 0,25 s) sem continuar até um destino antigo.

O clique/toque pode terminar fora do centro da célula, com margem de segurança de
até 10 px em cada eixo. A navegação continua apoiada na grade interna; esta mudança
não é uma física analógica de ângulo ilimitado. Origens, destinos e quinas da
travessia diagonal são reservados enquanto o personagem passa. Isso mantém a
regra de uma pessoa por corredor. Entradas/saídas trocam a sala sem interpolar entre mapas.

Salvamentos 0.9.0 continuam aceitos, e os novos podem guardar um deslocamento em
andamento. A estrutura principal do save permanece na versão 1. Mantidos o kit,
preços, ingredientes, preparo, dois serviços, arte por código e a mercearia preservada.

Arquivos: `dist/restaurant-core.js`, `dist/restaurant-ui.js`, `dist/index.html`,
`restaurant.test.cjs` e README. Testes incluem avanço fracionário por quadro,
velocidade diagonal, destino fora do centro, bloqueio de quinas, salvamento em
trânsito e o ciclo anterior completo. Android real permanece pendente.
Verificação desta versão no navegador: entrada por toque, caminho rua/restaurante,
piso sem linhas na partida e abertura do modo de montagem. A suavidade foi
verificada por testes de avanço por quadro; a sensação no celular depende de
avaliação no aparelho. O cenário de corredor também passou em passos de 16 ms.
