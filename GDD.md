# Entre Esquinas — Game Design Document

**Revisão:** consolidado Godot — 7 de novembro de 2026

**Base do jogo:** 0.21.2 e revisões posteriores da versão Godot

**Última implementação considerada:** [f0fd4e9](https://github.com/denerRsilva/Entre-Esquinas/commit/f0fd4e9)

Este documento reúne as decisões aprovadas para o jogo e o funcionamento atual
verificado no projeto. O GDD original não está versionado neste repositório;
os arquivos históricos mencionam um GDD Restaurante v1.3. Este consolidado não
reconstitui capítulos ausentes nem transforma ideias futuras em funcionalidades
implementadas. O escopo abaixo é o da versão Godot; o HTML permanece preservado
como versão anterior e não recebe automaticamente as mesmas mudanças.

## 1. Visão do jogo

Entre Esquinas é uma simulação de restaurante e vida de bairro com apresentação
em pixel art e ambientação brasileira acolhedora. O jogador atua diretamente no
salão e na cozinha, organiza o espaço, compra ingredientes, atende clientes e
acompanha o resultado do negócio ao longo dos dias.

A referência para o **controle do personagem** é a liberdade de deslocamento de
Stardew Valley: movimento contínuo e responsivo, sem obrigar o jogador a terminar
um passo na grade. Isso não implica reproduzir os demais sistemas desse jogo.

A experiência atual concentra-se na operação do restaurante. A cidade e os
moradores oferecem um espaço de demonstração; narrativa extensa, relações sociais
completas e estabelecimentos adicionais ainda não estão implementados.

## 2. Ciclo principal

1. Preparar o restaurante: organizar móveis, obter utensílios e comprar insumos.
2. Recolher as entregas e manter na mochila os ingredientes necessários.
3. Escolher o horário de serviço e abrir o restaurante pela placa da entrada.
4. Receber os clientes, aproximar-se e anotar os pedidos.
5. Cozinhar os lotes, retirar a panela e empratar na bancada.
6. Retirar e servir os pratos; o garçom pode auxiliar no atendimento.
7. Recolher a louça, lavar e preparar o próximo atendimento.
8. Encerrar as novas entradas, concluir as pendências e acompanhar o fechamento diário.

O jogador pode abrir o restaurante sem estrutura mínima, insumos ou cardápio
preenchido. Essa liberdade não elimina os requisitos de cada tarefa: receber
clientes exige assentos e opções de cardápio; cozinhar e servir exigem os recursos
correspondentes. Não há montagem gratuita obrigatória para iniciar uma partida.

## 3. Espaços e circulação

### Restaurante

- Salão com mesas e cadeiras orientadas para as mesas.
- Cozinha com fogão, bancada de preparo, pia, lixeira e geladeira.
- Área de estoque e armazenamento no cenário atual.
- Computador para fornecedor, utensílios, cardápio, preços e entregas.
- Ponto de recebimento para recolher os pedidos de ingredientes.

### Rua e fachada

Ao atravessar a porta, o jogador encontra a Rua das Esquinas, com fachada do
restaurante, toldo, calçada, jardins laterais, árvores, bancos e faixa de pedestres.
As fachadas vizinhas são decorativas; não representam lojas já acessíveis.

A entrada funciona por clique ou movimento livre. O ponto de chegada deve estar
livre; uma transição não pode colocar dois personagens no mesmo lugar. Sair e
entrar não deve provocar um retorno automático em loop.

Na rua, a fachada informa se o restaurante está aberto e oferece **Abrir
restaurante** ou **Encerrar restaurante**. A ação aproxima o jogador da entrada
e respeita os horários e as pendências do serviço. A placa interna continua
funcionando. A operação do salão e a chegada de clientes continuam sendo
simuladas enquanto o jogador está na rua.

## 4. Movimento, câmera e interação

- WASD/setas controlam o jogador continuamente, permitindo parar entre células.
- Soltar as teclas interrompe o movimento imediatamente, sem concluir um passo.
- Inverter a direção responde imediatamente; diagonais não aumentam a velocidade.
- Paredes e móveis bloqueiam o corpo. Numa diagonal contra um obstáculo, o eixo
  livre continua avançando, permitindo deslizar sem ficar preso.
- Quadros lentos não podem permitir atravessar obstáculos.
- Clique no chão continua disponível para navegar até um destino. Clicar em
  móveis ou clientes permite aproximar-se para a interação correspondente.
- A troca entre teclado e clique preserva a posição visual, sem teletransporte.
- NPCs e posicionamento dos móveis continuam utilizando a grade lógica.
- Animação e direção acompanham o movimento; pressionar uma parede sem sair do
  lugar não mantém a animação de caminhada.
- Menus, construção e perda de foco pausam a simulação. Ao perder foco, as teclas
  são liberadas para evitar movimento preso ao retornar.

A câmera acompanha o jogador quando o enquadramento exige deslocamento. O zoom
vai de **70% a 200%**, em passos de 10%. Os controles −/+ continuam disponíveis;
a alternância entre janela e tela cheia fica em **Opções → Câmera**.

## 5. Construção e organização

O acesso é **Gestão → Modo construção**. A simulação pausa e a HUD operacional
fica oculta. O catálogo lateral pode ser aberto e recolhido para liberar o mapa.

O jogador pode comprar, posicionar, girar e mover os nove tipos de móveis atuais:
mesa, cadeira, fogão, geladeira de cozinha, bancada, pia, lixeira, prateleira seca
e geladeira de estoque. Os setores permitidos e as áreas de circulação devem ser
respeitados. A prévia mostra se a posição é válida e a compra só é cobrada ao
confirmar uma posição válida.

Mover preserva a identidade, os itens e o conteúdo do móvel, sem nova cobrança.
Guardar exige retirar os itens instalados e respeitar os bloqueios de preparo e
louça; a implementação atual devolve o valor integral do móvel. Alterações de
layout exigem serviço concluído, sem clientes ou pedidos ativos. Corredores,
portas, personagens e acesso aos equipamentos não podem ser bloqueados.

A prévia deve responder ao cursor sem travar o jogo. Otimizações e cache não
podem dispensar a validação definitiva ao confirmar.

## 6. Clientes, descoberta do pedido e atendimento

### Informação revelada ao jogador

**O prato desejado só aparece depois que o pedido é anotado**, pelo jogador ou
por um garçom. Antes disso:

- O cliente pode sinalizar que aguarda atendimento e mostrar sua paciência.
- Não aparece o ícone nem o nome do prato sobre o cliente.
- A ação mostra apenas **Anotar pedido**, sem revelar a receita.
- O painel de pedidos informa que há uma mesa aguardando atendimento, sem antecipar o prato.

Depois de anotar, o prato fica visível e o pedido aparece na fila de atendimento.
A regra vale mesmo quando a escolha da receita já existe internamente na simulação.

### Fluxo do atendimento

Os clientes chegam individualmente e reservam uma mesa inteira até a saída e a
retirada da louça. Grupos ainda não estão implementados. O pedido exige presença
física e não pode ser duplicado pelo jogador ou por dois garçons.

O atendimento e a espera pela comida têm contadores de paciência separados.
Anotar encerra a primeira etapa e inicia a segunda. Ao esgotar a paciência, o
cliente desiste, o pedido é cancelado e não há pagamento. No instante exato do
limite, a desistência tem prioridade sobre a entrega.

Depois de receber o prato, o cliente come, paga e sai. A louça permanece para
recolhimento. Ingredientes consumidos não são estornados após um abandono; pratos
em trânsito e recipientes continuam sujeitos às regras de conservação.

A satisfação considera atendimento, espera da comida e qualidade do prato.
Indicadores de estado, elogios, reclamações e histórico ajudam a acompanhar o
resultado do serviço. As probabilidades e tempos atuais são parâmetros de teste.

## 7. Cozinha e louça

### Preparar um lote

1. Manter os ingredientes na mochila.
2. Instalar uma panela vazia no fogão.
3. Escolher a receita e iniciar o lote de quatro porções.
4. Fazer outras tarefas enquanto a barra de cozimento avança.
5. Retirar a panela cheia para a mochila antes de perder qualidade ou queimar.

O fogão não possui inventário genérico. Geladeiras e prateleiras não abastecem
receitas automaticamente. Na implementação atual há um preparo no fogão por vez.

### Empratar e servir

A bancada exige pratos limpos e um talher instalado. Com uma panela de comida na
mochila, o jogador usa **Empratar** e permanece próximo durante a barra de preparo.
A panela volta vazia ou conserva as porções restantes; pratos prontos ficam na
bancada para retirada pelo jogador ou garçom.

As ações principais da bancada são **Empratar** e **Retirar prato**. Escolhas
adicionais aparecem quando há mais de uma receita; manutenção fica em **Mais
opções**. Ausência de espaço não pode apagar comida, louça ou utensílios.

Depois do consumo, a louça suja é recolhida e lavada na pia. Pia e lixeira usam os
itens da mochila por ações específicas. Descartar comida respeita o retorno ou
consumo dos recipientes conforme o item, sem gerar recursos indevidos.

### Qualidade

Ingredientes e pratos usam quatro qualidades: Comum, Prata, Ouro e Roxa. A
qualidade do lote deriva dos ingredientes efetivamente consumidos. Transferências,
transporte e salvamento preservam a qualidade dos itens.
Deixar a panela pronta no fogão reduz a qualidade e pode queimar a comida;
retirá-la interrompe a degradação pelo calor. Comida queimada deve ser descartada.

## 8. Compras, inventários e equipe

A mochila possui dez espaços. Pilhas compatíveis respeitam os limites do item;
panelas com comida são unitárias. Geladeiras e prateleiras têm inventários de
armazenamento e critérios próprios de aceitação. Transferências permitem ajustar
quantidades e preservam os excedentes na origem quando falta espaço.

Compras no computador geram entregas, que chegam ao recebimento e precisam ser
recolhidas. Panelas, colheres e pratos limpos são comprados na seção Utensílios.

Há dois funcionários gratuitos para testes, com funções configuráveis:

- **Parado:** não assume novas tarefas.
- **Logística:** transporte entre recebimento e armazenamento/equipamentos compatíveis.
- **Garçom:** anota pedidos nas mesas e transporta/serve pratos prontos, sem cozinhar.

Trocar de função interrompe novas tarefas; cargas em trânsito mantêm as regras
existentes. Contratação, salários e progressão de equipe ainda não estão definidos
como sistemas completos de jogo.

## 9. Relógio, turnos, calendário e reputação

O dia jogável começa às **06:00** e termina às **02:00 da madrugada seguinte**.
Meia-noite não avança a data jogável. O relógio só avança com a simulação ativa.

Os horários padrão são almoço **11:00–15:00** e jantar **18:00–22:00**. Em
**Gestão → Turnos**, podem ser alterados em blocos de dez minutos, sem
sobreposição e com serviço concluído.

Abrir depende de estar no horário permitido. Encerrar manualmente ou chegar ao
fim do turno suspende novas entradas, mantendo os clientes e preparos pendentes.
Fechar almoço ou jantar não adianta a data. Às 02:00, o relógio aguarda a conclusão
das pendências antes da virada; não há cancelamento automático para forçar o fim.

O calendário possui quatro estações, com 28 dias cada e sete dias da semana.
O fechamento financeiro e a despesa diária ocorrem uma vez por virada de dia.

A reputação vai de 0 a 100. Elogio, reclamação e abandono geram registros;
uma visita não pode aplicar o mesmo efeito duas vezes. Na versão atual,
reputação não multiplica demanda nem altera os preços automaticamente.

## 10. Parâmetros atuais — provisórios para balanceamento

Os números abaixo descrevem o protótipo; não representam balanceamento final.

| Parâmetro | Valor atual |
| --- | --- |
| Caixa inicial | $1.500 |
| Despesa diária | $12 |
| Avanço do relógio | 10 minutos a cada 7 segundos ativos |
| Primeira chegada após abrir | 8 segundos ativos |
| Intervalo entre chegadas | 25 segundos ativos |
| Tamanho dos lotes | 4 porções |
| Tempo para empratar | 2 segundos |
| Capacidade de pratos prontos na bancada | 12 |
| Pratos limpos instalados na bancada | Até 99 |
| Janela da panela pronta no ponto | 8 segundos |
| Alerta de perigo de queima | A partir de 20 segundos |
| Queima da panela pronta no fogão | 25 segundos |
| Peso na satisfação: atendimento/comida/qualidade | 35% / 35% / 30% |
| Reputação inicial | 0 |
| Elogio | +1 de reputação |
| Reclamação ou abandono | −1 de reputação por visita, sem acumular os dois |

| Receita | Ingredientes por porção | Preparo do lote | Preço inicial do prato |
| --- | --- | --- | --- |
| Arroz com legumes | 1 arroz + 1 legumes | 6 segundos | $14 |
| Sopa de legumes | 2 legumes | 5 segundos | $12 |
| Frango com arroz | 1 arroz + 1 frango | 8 segundos | $20 |

O lote consome quatro vezes os ingredientes por porção. Os preços do cardápio
podem ser alterados no computador. Ingredientes comuns custam arroz $2,
legumes $2 e frango $4 por unidade; as qualidades superiores usam multiplicadores
1,25, 1,5 e 2. A entrega atual leva 5 segundos ativos e o recebimento comporta
60 unidades.

| Móvel ou utensílio | Preço atual |
| --- | ---: |
| Mesa / cadeira | $45 / $15 |
| Fogão / bancada de preparo | $150 / $90 |
| Pia / lixeira | $70 / $25 |
| Geladeira de cozinha / geladeira de estoque | $120 / $140 |
| Prateleira seca | $65 |
| Panela vazia / colher / prato limpo | $25 / $15 / $5 |

## 11. Interface e ferramentas de teste

- **Gestão:** turnos, construção, equipe, fechamento, clientes, calendário e reputação.
- **Opções:** câmera/tela cheia, salvar e carregar, testes e primeiros passos.
- **Inventário:** mochila e seleção dos itens.
- Tutorial inicial recolhível, sem obrigar a leitura antes de começar.
- O início não exibe o aviso “Teste pronto…” nem a faixa permanente de informações
  do personagem. Avisos de ações e erros continuam disponíveis.

### Cenários iniciais

**Começar vazio** inicia a montagem do zero. **Começar mobiliado (teste)** oferece
estrutura e recursos gratuitos para validar os sistemas; não define as condições
de uma futura campanha. A geração e a prévia de móveis devem permanecer responsivas.

### Manipular horário

Em **Opções → Testes**, o jogador escolhe um horário e usa **Avançar horário**.
O intervalo é 06:00–02:00, em blocos de dez minutos, somente para a frente no dia
jogável atual. Escolher 11:00 permite abrir o almoço sem aguardar o relógio normal.

O salto altera o relógio sem simular o intervalo: não consome paciência nem
avança cozinha ou entregas. Ainda aplica encerramento dos turnos e virada de dia
pelas regras normais. Não abre o restaurante automaticamente. É preciso voltar
ao jogo e abrir o serviço para começar a receber clientes.

A opção de limpar móveis e inventários é uma ferramenta separada de teste;
não reembolsa os itens apagados e só afeta o save após salvar a partida.

## 12. Salvamento e requisitos de qualidade

A Godot usa salvamento local em formato 9, com posição subcélula do jogador,
inventários, receitas em andamento, relógio, calendário e reputação. Teclas
pressionadas não persistem no save. Há validação, cópia de segurança e importação
de JSON compatível; arquivo inválido não deve substituir uma partida válida.

O progresso do HTML e o da Godot são independentes. Migrar uma partida usa a
importação do JSON compatível, não a leitura direta do armazenamento do navegador.

Critérios essenciais de aceitação:

- Movimento sem passos obrigatórios, travamento em paredes ou velocidade diagonal extra.
- Portas transitáveis e destinos livres, sem retorno em loop.
- Prato oculto antes da anotação em todos os elementos da interface.
- Nenhuma duplicação de pedido, prato, panela, utensílio ou pagamento.
- Construção conserva conteúdo e caixa, mantendo acesso a portas e móveis.
- Menus e perda de foco pausam corretamente; não há teclas presas ao retornar.
- Salvar/carregar conserva os dados e mantém um backup válido após recuperação.
- Pular horário para testes não simula abandono, queima ou entrega durante o salto.

As verificações e os limites de validação estão em [qa/LEIA-ME.md](godot/qa/LEIA-ME.md)
e no [registro de revisão](godot/REVISAO.md). Testes automatizados não substituem
avaliação humana de diversão, ritmo e clareza; Windows, exportação e áudio físico
não devem ser considerados validados apenas pelos testes em Linux.

## 13. Base técnica e limites de escopo

O projeto atual usa **Godot 4.6.3 Standard**, com apresentação e controles nativos
Godot e simulação JavaScript embarcada via QuickJS/GDExtension. A migração é
híbrida; não está integralmente convertida para GDScript.

O pacote tem bibliotecas e perfis para Windows e Linux x86-64. A validação
registrada foi feita em Linux. Web, Android e macOS exigem trabalho adicional na
extensão e não são plataformas de exportação prontas da versão Godot.

Permanecem fora do escopo implementado: grupos de clientes, contratação e salários
completos, progressão social/narrativa ampla, estabelecimentos vizinhos jogáveis,
sistema de tráfego e influência da reputação sobre demanda. O protótipo histórico
da mercearia está arquivado e não equivale a uma loja integrada à rua atual. Isso não cancela
possíveis diretrizes do GDD original; significa apenas que não há base para
documentá-las aqui como recursos já entregues.

## 14. Rastreabilidade das revisões recentes

| Decisão / entrega | Referência |
| --- | --- |
| Projeto Godot preservando a versão HTML | [fdf90c1](https://github.com/denerRsilva/Entre-Esquinas/commit/fdf90c1) |
| Interação com cozinha, recuperação de saves e tela cheia nas opções | [348b77f](https://github.com/denerRsilva/Entre-Esquinas/commit/348b77f) |
| Otimização do início mobiliado e da prévia de construção | [7f346c1](https://github.com/denerRsilva/Entre-Esquinas/commit/7f346c1) |
| Movimento livre e deslizamento nas paredes | [8d6ab48](https://github.com/denerRsilva/Entre-Esquinas/commit/8d6ab48) |
| Remoção das mensagens de início | [592924f](https://github.com/denerRsilva/Entre-Esquinas/commit/592924f) |
| Rua, serviço externo e controle de horário para testes | [62787fe](https://github.com/denerRsilva/Entre-Esquinas/commit/62787fe) |
| Revelação do prato somente após anotar o pedido | [f0fd4e9](https://github.com/denerRsilva/Entre-Esquinas/commit/f0fd4e9) |

Fontes complementares: [guia Godot](godot/LEIA-ME.md),
[histórico do projeto HTML](projeto/README.md) e
[registro de migração histórico](projeto/MIGRACAO_RESTAURANTE.md).
