# Entre Esquinas — Game Design Document

**Revisão:** consolidação do GDD v1.4 com a versão Godot — 7 de novembro de 2026

**Editor usado pelo proprietário:** Godot **4.7.2**, informado por Dener nesta revisão.

**Fonte de design:** `GDD_Entre_Esquinas_Restaurante_v1_4.pdf`, revisão de 03/11/2026 e adendos de 04/11/2026, fornecido pelo proprietário.

**Base do jogo:** 0.21.2 e revisões posteriores da versão Godot

**Última implementação considerada:** [f0fd4e9](https://github.com/denerRsilva/Entre-Esquinas/commit/f0fd4e9)

Este documento integra a visão e as decisões do PDF v1.4 às evoluções já
registradas no repositório. O PDF descreve historicamente a base 0.10.3; suas
menções a funcionalidades ausentes e ao save formato 4 não descrevem
automaticamente a versão Godot atual. As seções 1–14 preservam o registro técnico
anterior, com os ajustes desta revisão; as seções 15–23 integram o design do PDF,
as divergências e as pendências.

### Como interpretar o documento

| Marcador | Significado |
| --- | --- |
| CONFIRMADO / APROVADO | Decisão de design registrada; pode ainda depender de implementação. |
| ATUAL DOCUMENTADO | Comportamento descrito no GDD e nos registros anteriores do repositório; esta revisão documental não o revalidou executando o jogo. |
| PROPOSTO | Sugestão para discussão ou parâmetro provisório, sem aprovação final de balanceamento. |
| EM ABERTO / PENDENTE | Exige especificação, decisão ou validação. |
| EXEMPLO | Situação ilustrativa; não fixa conteúdo, números ou compromisso de produção. |
| NÃO APROVADO | Ideia preservada para consulta, fora do escopo autorizado de implementação. |

Decisões expressas mais recentes do proprietário prevalecem sobre decisões
anteriores. Código e documentação técnica registram o comportamento existente;
não convertem automaticamente uma diferença em aprovação de design. Onde PDF e
registro atual diferem sem decisão rastreada, a diferença é explicitada na seção
21, sem alterar o jogo nesta revisão. O HTML preservado não recebe
automaticamente as mudanças da Godot.

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
- Construção, perda de foco e menus de gestão/mochila pausam a simulação. Inventários de geladeiras e prateleiras mantêm o tempo avançando. Ao perder foco, as teclas
  são liberadas para evitar movimento preso ao retornar.

A câmera acompanha o jogador quando o enquadramento exige deslocamento. O zoom
vai de **70% a 200%**, em passos de 10%. Os controles −/+ continuam disponíveis;
a alternância entre janela e tela cheia fica em **Opções → Câmera**.

## 5. Construção e organização

O acesso é **Gestão → Modo construção**. A simulação pausa e a HUD operacional
fica oculta. O catálogo lateral pode ser aberto e recolhido para liberar o mapa.

O jogador pode comprar, posicionar, girar e mover os dez tipos de móveis atuais:
mesa, cadeira, fogão, geladeira de cozinha, mesa de preparo para corte, mesa de cozinha para empratamento, pia, lixeira, prateleira seca
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

### Cozinha física — reformulação aprovada

O fluxo atual é **ingredientes → cortar → adicionar à panela → cozinhar →
transportar nas mãos → apoiar na mesa de cozinha → empratar uma porção → servir**.
A mesa de preparo corta uma unidade de frango ou legumes em dois segundos; o
resultado vai à mochila. Arroz dispensa corte. A panela recebe ingredientes
individualmente e reconhece uma receita exata, sem janela de escolha. Ingredientes
extras/incompatíveis não são consumidos; a última adição pode ser retirada antes
de cozinhar.

Cada novo cozimento rende **uma porção**, usando as quantidades por porção da
seção 10. O jogador pode fazer outras tarefas durante o cozimento. Retirar a
panela libera o fogão, ocupa as mãos e encerra a exposição ao fogo.

A nova **mesa de cozinha** recebe pratos limpos e a panela apoiada. Empratar
produz **um prato por ação**, em dois segundos junto à mesa, **sem talher**.
A panela fica vazia no apoio e pode voltar ao fogão. Panelas antigas conservam
todas as porções e as entregam individualmente. O prato retirado ocupa as mãos;
clique em mesa/cliente compatível aproxima e serve. O garçom busca refeições na
mesa de cozinha. Louça, pagamentos, satisfação, qualidade e descarte permanecem.

Corte/empratamento cancelados preservam entradas. Sem espaço, não há perda ou
duplicação. Mãos ocupadas bloqueiam novas cargas e trabalho manual. Objetos em
uso não podem ser removidos apagando conteúdo. Consulte o
[guia da cozinha física](godot/COZINHA-FISICA.md) para controles e migração.

### Qualidade

Ingredientes e pratos usam quatro qualidades: Comum, Prata, Ouro e Roxa. A
qualidade do lote deriva dos ingredientes efetivamente consumidos. Transferências,
transporte e salvamento preservam a qualidade dos itens.
Deixar a panela pronta no fogão reduz a qualidade e pode queimar a comida;
retirá-la interrompe a degradação pelo calor. Comida queimada deve ser descartada.

## 8. Compras, inventários e equipe

O inventário do jogador possui cinco espaços, apresentados numa barra permanente no centro inferior da tela. Pilhas compatíveis respeitam os limites do item;
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
| Tamanho dos lotes novos | 1 porção |
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

O lote novo consome os ingredientes de uma porção. Os preços do cardápio
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

A Godot usa salvamento local em formato 11, com posição subcélula do jogador,
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

O proprietário usa **Godot 4.7.2** como editor de trabalho, conforme informação
expressa de 07/11/2026. A migração e as validações históricas foram documentadas
em **Godot 4.6.3 Standard**. A compatibilidade da extensão nativa, a importação,
a execução e a exportação em 4.7.2 ainda precisam de validação específica; esta
atualização não declara esses testes realizados nem altera configurações do projeto.

A apresentação e os controles são nativos Godot, com simulação JavaScript
embarcada via QuickJS/GDExtension. A migração é híbrida; não está integralmente
convertida para GDScript.

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

## 15. Visão completa, referências e pilares

**CONFIRMADO —** Restaurante e vida na cidade em equilíbrio. A promessa é cuidar
de um pequeno restaurante, conhecer moradores e transformar a gastronomia e a
vida da cidade, equilibrando trabalho, relacionamentos e crescimento. A prioridade
de produção é consolidar a diversão dentro do restaurante e desenvolver cidade
e narrativa progressivamente. Essa ordem não elimina a dimensão social da visão.

| Referência confirmada | Inspiração desejada | Cuidado |
| --- | --- | --- |
| Stardew Valley | Cidade, rotinas, vínculos, passagem dos dias e liberdade de movimento | Não reproduzir agricultura ou sistemas sem relação com a proposta. |
| Travellers Rest | Operação prática, produção e melhorias do estabelecimento | Evitar serviço repetitivo sem escolhas. |
| Chef RPG | Receitas, estética gastronômica e conexão com o entorno | Preservar identidade própria e escopo viável. |

Big Ambitions não integra as referências deste conceito.

| Pilar | Atividade | Relação com os demais |
| --- | --- | --- |
| Operação | Preparar, organizar estações, atender e priorizar pedidos | Capacidade e qualidade afetam satisfação e resultado. |
| Cidade | Explorar, conhecer moradores e participar de eventos | Relações podem revelar fornecedores, receitas e oportunidades. |
| Gestão | Comprar, definir cardápio e preços, calcular margens e coordenar equipe | Recursos e escolhas sustentam operação e crescimento. |
| Progressão | Reformar, melhorar equipamentos, desenvolver receitas e reputação | Novas possibilidades mudam decisões e liberam tempo para a cidade. |

Cada pilar deve afetar ao menos outro. A fantasia é começar pequeno, dominar a
operação, delegar tarefas e construir identidade gastronômica e vínculos locais.
**EM ABERTO —** Origem do protagonista e acesso ao restaurante: herança, compra
ou outra forma. Quase falência e quatro mesas são premissas ilustrativas.
O tópico 7 de um brainstorm anterior consta como excluído no PDF; seu conteúdo
não foi fornecido e não é reconstituído aqui.

## 16. Operação significativa, economia e autonomia

### Cozinha e receitas

A cozinha deve oferecer escolhas de sequência, lotes, recursos e tempo, evitando
microcliques repetidos sem decisão. Pedidos que disputam uma estação, ingredientes
insuficientes e garçom ocupado devem gerar consequências compreensíveis.
Sugerir outra receita ao cliente permanece **PROPOSTO**.

**PROPOSTO —** Cada receita deve declarar nome, ingredientes e quantidades,
estações, ordem das etapas, tempos, capacidade, custo por porção, preço, margem,
critérios de qualidade, desperdício e requisitos de desbloqueio. O exemplo de
hambúrguer e batatas com chapa e fritadeira paralelas é ilustrativo; não acrescenta
receita, equipamento nem produção paralela ao protótipo.

### Compras e perdas

**PROPOSTO —** Fornecedores diferenciados por preço, prazo, qualidade,
disponibilidade e relacionamento. Quantidade inicial de fornecedores, validade,
temperatura, congelamento e intensidade das perdas seguem **EM ABERTO**.
Queima aprovada no adendo não significa aprovação de deterioração dos ingredientes.

Recebimento físico e armazenamento por categoria são o funcionamento documentado.
Pallets, carrinhos e fila de entregas da mercearia histórica não são automaticamente
regras aprovadas para o restaurante.

### Economia compreensível

O fechamento deve explicar as causas do ganho ou perda de dinheiro. A visão de
economia completa é uma **PROPOSTA**, não uma declaração de implementação de
salários, aluguel e todos os indicadores abaixo.

| Indicador | Interpretação |
| --- | --- |
| Receita de vendas | Total recebido pelos pratos vendidos. |
| Custos variáveis | Ingredientes consumidos e demais despesas por prato. |
| Margem de contribuição | Receita menos custos variáveis. |
| Resultado operacional | Margem menos salários, aluguel e outras despesas fixas. |
| Caixa disponível | Dinheiro para despesas e investimentos. |

**EXEMPLO —** Venda de 30 e ingredientes de 12 deixam 18 antes das demais
despesas; esses valores não substituem preços ou custos atuais.

### Equipe e autonomia

**CONFIRMADO —** Funcionários mantêm tarefas atribuídas, com intervenção do
jogador nas prioridades. A evolução desejada vai de executar tarefas a coordenar
gargalos e decidir capacidade, cardápio e investimentos. Deve continuar havendo
escolhas relevantes mesmo com uma equipe desenvolvida.

**PROPOSTO —** Mostrar falta de ingredientes, estação ocupada ou caminho
bloqueado. Funcionário sem demanda aguarda na função. Cozinha e lavagem
automáticas, contratação comercial, salários e progressão de equipe não são
acrescentados por esta revisão.

## 17. Cidade, relações, ecossistema e progressão

A cidade é parte da visão de jogo: moradores com rotinas e preferências
observáveis, vínculos que abrem oportunidades e acontecimentos com efeitos
compreensíveis no restaurante. Esses sistemas amplos ainda são **PROPOSTOS**,
além do espaço de demonstração atual.

| Exemplo de relação ou acontecimento | Efeito possível, ainda proposto |
| --- | --- |
| Amizade com agricultor | Ingrediente sazonal e receita exclusiva. |
| Moradora vegetariana | Preferências refletidas na procura e nos comentários. |
| Evento em praça próxima | Mais visitantes em horários e pratos específicos. |
| Escassez de fornecedor | Mudança de preço, oferta ou prazo. |

Começar com poucos NPCs de função clara. Romances, diálogos extensos e histórias
longas aguardam a validação do ciclo principal.

O **Ecossistema Vivo da Cidade** é uma hipótese de diferencial: notícia de
festival dá tempo para planejar; demanda e oferta mudam; o jogador decide comprar
antes, adaptar o cardápio ou manter operação enxuta; vendas, perdas e relações
expressam o resultado. As causas devem ser visíveis, sem variações arbitrárias e
ocultas. A reputação atual não altera demanda automaticamente.

| Fase proposta | Conteúdo | Experiência desejada |
| --- | --- | --- |
| Início | Poucos pratos e mesas, trabalho direto, primeiros vínculos | Conseguir fazer o restaurante funcionar. |
| Intermediária | Equipe, especialização, novas estações e eventos | Perceber o efeito da organização. |
| Avançada | Reputação, novas clientelas, reformas e eventos complexos | Construir um negócio com identidade. |

Concorrência e um segundo estabelecimento são hipóteses de maior escopo. Uma
segunda unidade fica fora do primeiro planejamento de produção até validar o
jogo principal.

## 18. Espaço, inventários, circulação e upgrades

### Diretrizes do PDF

**APROVADO —** A partida regular começa vazia; o cenário mobiliado é ferramenta
de teste. Abrir não exige estrutura mínima. Salão, cozinha e estoque têm funções
distintas, e o estoque equipado é opcional para abrir.

Cozinha e estoque integram a mesma cena; parede separa o estoque e o acesso se dá
pela cozinha, sem porta externa própria. Computador e recebimento integram esse
espaço. A prateleira pode ficar na cozinha ou no estoque. Esses requisitos de
layout devem ser confrontados com o cenário atual antes de qualquer alteração.

A mochila tem dez espaços e pilhas de até 99 conforme compatibilidade do item;
panelas com conteúdo são exceções unitárias. Armazenamentos têm inventários
próprios por categoria. A direção aprovada é tela dividida, mochila à esquerda
e objeto à direita; compras de utensílios e panelas entram na mochila.

Ações contextuais pertencem ao alvo selecionado, exigem proximidade e ficam
agrupadas acima dele. Clicar no chão cancela e outro alvo substitui a seleção.
Aproximar-se sem selecionar não deve abrir ações ou a lista de recebimento.
O PDF posicionava Inventário entre Gestão e Montar; o acesso atual à construção
por Gestão é registrado na seção 5 e essa posição antiga não é restaurada aqui.

**CONFIRMADO —** Grade para organização, colocação livre nas áreas autorizadas,
ocupação e colisão física; movimento visual livre e fluido. O controle contínuo
posterior da Godot permanece documentado na seção 4. Grade 24 × 16 e células de
40 px pertencem ao registro histórico da 0.10.3, sem fixar dimensões comerciais.

Corredores de largura de uma pessoa devem produzir espera ou desvio e tornar
perceptível a diferença entre lotação e eficiência. Prioridade entre personagens,
cruzamento diagonal, tempo máximo de espera e resolução de impasses continuam
**PENDENTES** onde não houver especificação ou teste atual. Não se declara
comprovada a ausência de deadlocks nesta revisão documental.

### Melhorias por setor

**APROVADO COMO DIREÇÃO —** Cada setor terá upgrades com efeitos perceptíveis.
Catálogo final, preços e disponibilidade por fase permanecem pendentes.

| Proposta de melhoria | Benefício a avaliar |
| --- | --- |
| Panela adicional ou fogão com mais bocas | Alternância ou paralelismo, conforme capacidade a definir. |
| Frigideira, chapa e utensílios especializados | Técnicas e receitas novas. |
| Geladeira maior ou freezer | Capacidade e conservação, quando esses sistemas forem definidos. |
| Câmara fria | Expansão futura com investimento, espaço e custo; sem armazenamento infinito. |

Antes da compra, mostrar preço, espaço, instalação e consequência prática.
Melhoria cosmética deve ser identificada como personalização. Recepção, retirada
para viagem, decoração com efeito de reputação, plantas e divisórias são propostas,
sem constituir requisitos de abertura.

Os detalhes de freezer, validade, compartilhamento entre geladeiras, custo
definitivo de reorganização/revenda e upgrades do MVP seguem **EM ABERTO**.
Reembolso integral e restrições atuais de setores descrevem o protótipo, não
balanceamento comercial definitivo.

## 19. Qualidade e ponto de cozimento — adendo de 04/11

Esta seção incorpora o adendo aprovado do PDF, que substitui a antiga exclusão
de queima. É requisito de design; detalhes visuais e sonoros abaixo não são
declarados testados ou integralmente implementados nesta atualização.

### Escala e apresentação

**APROVADO —** Ingredientes e pratos usam a mesma escala: Comum sem estrela,
Prata com estrela cinza/prateada, Ouro com estrela amarela e Roxa com estrela
roxa. O nome do nível roxo não depende de “Irídio”.

A qualidade do lote deve derivar da média ponderada pelas quantidades de
ingredientes efetivamente consumidas, sem sorteio oculto, e ser preservada no
empratamento. Fórmula, limiares e seleção das pilhas precisam de especificação
rastreável; o simples fato de existirem no protótipo não aprova seu balanceamento.

**Regra obrigatória:** estrelas somente nos itens de ingredientes e pratos
prontos, inclusive em inventários, armazenamento, compras e serviço.
Não mostrar estrelas no preparo da receita, barra, fogão/panela ou alertas de
cozimento, nem antecipar qualidade atual, prevista ou potencial durante o preparo.
A degradação continua internamente e é comunicada pelos estados de cozimento.

### Estados e feedback aprovado

Tempos contados após concluir a receita, em segundos ativos; são parâmetros
provisórios para teste.

| Estado | Intervalo de referência | Barra e sinais | Panela e som |
| --- | --- | --- | --- |
| Cozinhando | Até concluir a receita | Barra preenche com símbolo de chama | Fogo e vapor leve. |
| No ponto | 0 até 8 s | Verde cheia com confirmação; esvazia na janela segura | Breve brilho e som curto de conclusão. |
| Passando do ponto | 8 até 20 s | Laranja preenchendo com alerta | Vapor intenso, início de fumaça e novo aviso sonoro. |
| Perto de queimar | 20 até 25 s | Vermelha quase cheia e alerta evidente | Fumaça escura e conteúdo escurecendo. |
| Queimado | A partir de 25 s | Símbolo próprio substitui a barra | Conteúdo escuro e orientação para retirar e descartar. |

Uma única barra muda de função. Usar símbolos além das cores, evitar piscadas e
alarmes constantes e reservar a maior urgência para perto da queima. Nenhuma
etapa mostra estrelas. Os instantes exatos das transições exigem teste de limite.

Retirar a panela cheia encerra cozimento e perda por calor. Empratar conserva o
resultado. Menus que pausam a simulação também pausam esses contadores.
Queimado é estado de perda separado das quatro qualidades; não pode ser servido
e deve ser descartado. Incêndio não integra esta primeira versão.

O aviso compacto fora da câmera pode mostrar arte da receita e símbolos de
pronto/alerta, sem estrela e sem mover a câmera. A qualidade participa da
satisfação juntamente com as esperas. O cliente paga o preço combinado ao
registrar o pedido; não há preço automático por qualidade aprovado neste adendo.

### Aceitação e conservação

- Preservar qualidade em compras, entregas, transporte, armazenamento, retirada,
  sobras, pratos e salvamento; especificar separação de pilhas diferentes.
- Testar pausa, limites de tempo, retirada no instante da queima, mochila cheia,
  empratamento parcial, descarte e serviço por funcionário.
- Confirmar ausência de estrelas em todo preparo e em alertas fora da câmera,
  e apresentação correta nos ingredientes e pratos finais.
- Preservar receitas, rendimento, rotas e funções de equipe, salvo necessidade
  explicitamente especificada para esse sistema.
- Tratar migrações sem apagar ou substituir indevidamente a partida original.

## 20. Vertical slice, experiência e validação

O vertical slice deve demonstrar preparação, almoço, intervalo, jantar e
fechamento. A validação operacional vem primeiro; metas sociais e de eventos
são posteriores e não bloqueiam o teste do restaurante.

| Elemento | Escopo sugerido pelo PDF, ainda proposto |
| --- | --- |
| Restaurante | 3–4 mesas, duas estações e 3–5 receitas. |
| Cidade | Uma rua ou praça, três NPCs significativos e um fornecedor. |
| Trabalho | Dois serviços com pedidos, preparo, serviço e pagamento. |
| Gestão | Compras, estoque simplificado, relatório e uma melhoria. |
| Relações | Uma amizade que altera oferta ou oportunidade. |
| Equipe | Uma tarefa contínua com feedback de impedimentos. |
| Evento | Uma situação local com efeito visível na demanda. |

### Critérios de Game Design

- Completar um dia sem instruções externas extensas.
- Entender por que pedidos disputam um recurso e perceber ao menos duas escolhas
  com consequências diferentes e observáveis.
- Cozinhar sem microcliques repetidos que não acrescentam decisão.
- Reconhecer no relatório as principais causas do resultado.
- Na etapa social, perceber o efeito concreto de um morador ou evento no negócio.
- Registrar interesse real em jogar outro dia, clareza, erros, espera e tempo em
  transferências. Testes automatizados não comprovam diversão.

### Cobertura funcional herdada do PDF

Os critérios COZ-01 a COZ-10 pedem: encaixes compatíveis; ingredientes completos
antes do consumo; confirmação sem duplicar lote; retirada sem espaço conservando
comida; empratamento sem perda; bloqueios explícitos ao mover/guardar; save e
migração preservando progresso; regressão de serviços, garçom e limpeza; estados
operacionais claros; playtest do fluxo. A ausência de espaço conserva itens,
mas não interrompe automaticamente a degradação de comida que continua no fogo.

GRID-01 a GRID-09 pedem: dimensões e encaixe corretos; ausência de sobreposição
indevida; passagem unitária; resolução de impasses; rotas alternativas; atualização
dos caminhos após reformas; colocação inválida sem cobrança/perda; acessibilidade
das áreas essenciais; diferença perceptível entre layouts.

CA-01 a CA-08 incluem abertura vazia sem clientes inválidos, requisitos por tarefa,
estoque opcional, compatibilidade de receitas, distinção dos serviços, conservação
ao comprar/remover, melhorias mensuráveis e proteção de pontos indispensáveis.

Esses são critérios a verificar na versão atual, não resultados novos de QA.
O PDF relata testes da 0.10.3; os registros Godot relatam verificações posteriores
em Linux/4.6.3. Nenhum deles comprova execução na 4.7.2 informada pelo proprietário.

## 21. Conciliação entre PDF e repositório

| Assunto | PDF v1.4 e adendos | Registro atual / tratamento nesta revisão |
| --- | --- | --- |
| Base | 0.10.3, save 4 | Godot derivada da 0.21.2, save 9. Preservar registro atual; não retroceder formato. |
| Editor | Não estabelece a versão atual do proprietário | Godot 4.7.2 informada nesta conversa; histórico de testes em 4.6.3 preservado. |
| Referências | Stardew Valley, Travellers Rest e Chef RPG | Restaurada a visão completa, além da referência de movimento. |
| Fogão | Retirar inventário genérico; slot de panela e consumo da mochila | Simplificação já documentada; manter conservação e ações contextuais. |
| Modelo híbrido C | Intervenções e presença ainda pendentes | Cozimento autônomo documentado. Não considerar que isso resolve ou aprova todas as intervenções do híbrido. |
| Comida transportável | Mochila como destino; panela instalada entre receitas; representação ainda pendente | Panela cheia móvel documentada. Diferença de design a confirmar antes de eventual mudança; não criar recipiente novo nem apagar o atual. |
| Bancada | Slot de pratos; utensílio e fonte do garçom pendentes | Pratos, talher instalado e pratos prontos documentados. Registrar solução atual sem eliminar a rastreabilidade da diferença. |
| Empratamento | Ação imediata na base antiga | Dois segundos junto à bancada no registro atual; parâmetro provisório. |
| Horários e calendário | Propostos ou pendentes na base antiga | Horários configuráveis, calendário e reputação já documentados; não retornar ao avanço de dia pelo jantar. |
| Satisfação | Pesos da qualidade por definir | 35%/35%/30% documentados como teste, sem aprovação de balanceamento final. |
| Qualidade/queima | Aprovadas em adendo; estrelas apenas nos itens | Requisitos detalhados incorporados; verificar conformidade visual e sonora na versão atual. |
| Construção e navegação | Prévia, rotação e regras de circulação parcialmente propostas | Preservar evoluções registradas e manter QA de gargalos/impasses. |
| Cidade e relações | Parte central da visão; desenvolvimento progressivo | Rua demonstrativa atual não equivale ao ecossistema completo. |
| Plataforma | PC principal | Windows/Linux previstos; não assumir Android, web ou macOS prontos na migração. |

Pendências antigas não devem ser repetidas como ausência técnica quando o
repositório já registra uma solução. Tampouco uma solução existente deve apagar
uma divergência de design sem decisão identificada.

## 22. Decisões, prioridades e riscos

### Registro consolidado

- D01: almoço e jantar, abertura voluntária sem estrutura mínima; a versão atual
  acrescenta janelas de horário documentadas.
- D02: estoque opcional para abrir, integrado e acessível pela cozinha.
- D03: mochila de dez espaços, pilhas compatíveis até 99 e armazenamento dividido.
- D04: organização por grade com movimento livre e fluido.
- D05: simplificação do fogão/bancada e modelo híbrido C aprovados no PDF;
  diferenças e intervenções ainda por conciliar na seção 21.
- D06: comida recolhida vai à mochila, sem desaparecimento por falta de espaço;
  representação transportável permanece diferença rastreada.
- D07: 0.10.3 era a base histórica selecionada no PDF; a base desta consolidação
  é o repositório Godot derivado da 0.21.2.
- D08: diversão do restaurante primeiro; cidade e narrativa avançam progressivamente.
- D09: adendo de 04/11 aprova qualidade e queima, com estrelas somente nos itens.
- D10: em 07/11, Dener informa uso de Godot 4.7.2 e solicita esta atualização
  documental diretamente no repositório.

### Backlog recomendado, sem implementação nesta revisão

1. Validar importação, extensão nativa, execução, saves e exportação na Godot
   4.7.2 utilizada pelo proprietário.
2. Conciliar as diferenças de cozinha da seção 21 e especificar o que ainda
   exigir decisão, sem refazer sistemas já documentados.
3. Verificar cozinha, qualidade, conservação, circulação e interface; fazer
   playtest de um dia com almoço, intervalo, jantar e fechamento.
4. Ajustar ritmo, capacidade e economia com evidência; definir upgrades do MVP.
5. Desenvolver poucos vínculos e um evento com efeitos comerciais verificáveis,
   antes de ampliar narrativa e cidade.

### Riscos e mitigação

| Risco | Mitigação recomendada |
| --- | --- |
| Escopo excessivo | Marcos pequenos por dependência e um dia jogável antes de ampliar sistemas. |
| Cozinha cansativa | Lotes, sequência e ações com decisão, medindo transferências e repetição. |
| Cidade decorativa | Relações e acontecimentos com efeitos concretos e causas legíveis. |
| Automação sem escolhas | Trocar esforço manual por decisões gerenciais relevantes. |
| Economia opaca | Relatório com receitas, custos e causas do resultado. |
| IA cara ou impasses | Simulação proporcional ao valor percebido e testes de fluxo em corredores. |
| Alteração de inventários e recipientes | Rastrear identidade, conteúdo, garçom e migração sem perda/duplicação. |
| Mudança de versão da Godot | Validar extensão e exportações na versão efetivamente utilizada. |

Relatos antigos, como travamento ao posicionar prateleira, exigem reprodução na
base atual antes de serem classificados como bugs confirmados. Otimizações
posteriores registradas não substituem esse teste específico.

## 23. Ideias potenciais e histórico documental

### IP-001 — Levar a câmera ao fogão pelo aviso

**NÃO APROVADA para implementação.** Origem: 04/11/2026, adendo do PDF.

Ideia: tocar no aviso de comida pronta ou passando do ponto levaria a câmera ao
fogão correspondente, sem retirar automaticamente a panela. Benefício possível:
localizar equipamento fora da tela. Risco: interromper o controle e a leitura do
cenário.

**Regra de design vigente no PDF:** avisos não deslocam a câmera, nem por toque
nem automaticamente. Retomada depende de nova aprovação explícita do proprietário,
com retorno da câmera e teste de usabilidade definidos. Guardar a ideia não a
transforma em requisito aprovado.

### Histórico e fontes

| Data | Registro |
| --- | --- |
| 30/10/2026 | Direção de grade e circulação referenciada no PDF. |
| 31/10/2026 | Decisões de layout e inventário referenciadas no PDF. |
| 03/11/2026 | GDD v1.4 consolidado sobre a base 0.10.3. |
| 04/11/2026 | Adendo de qualidade, ponto e queima; IP-001 preservada sem aprovação. |
| 07/11/2026 | Integração do PDF ao GDD do repositório, preservando evoluções Godot e registrando uso da versão 4.7.2. |

Fonte primária desta integração: PDF enviado pelo proprietário,
`GDD_Entre_Esquinas_Restaurante_v1_4.pdf`. O arquivo PDF não foi adicionado ao
repositório nesta revisão; seu conteúdo de design foi consolidado neste Markdown.
Fontes técnicas complementares permanecem vinculadas na seção 14.

Esta revisão altera somente o GDD. Não executa migração de engine, mudanças de
mecânica ou novos testes; os estados e resultados anteriores permanecem
atribuídos às suas respectivas bases.

## 24. Reformulação física posterior ao PDF

Decisão expressa do proprietário nesta conversa: implementar somente na Godot o
plano de reformulação enviado, com aprovação de **uma porção por cozimento**,
**remoção da exigência de talher** e **catálogo do computador como exceção** às
ações sem janela. Esta decisão substitui descrições históricas conflitantes de
lotes de quatro, consumo direto de receita da mochila e transporte automático de
panela cheia para a mochila presentes nas seções 2, 18, 21 e 22.

A seção 7 descreve o fluxo novo. O objetivo e as demais propostas do PDF seguem
preservados. A mesa de preparo corta; a nova mesa de cozinha emprata. Armazenamentos
abrem por um clique após aproximação e não pausam. Ações alternativas usam controles
junto ao objeto, sem painéis de receita ou empratamento.

O formato de save passa a 10. A migração conserva refeições, utensílios e panelas
antigas com suas porções, converte bancadas antigas em mesas de cozinha sem alterar
suas posições e não adiciona móveis em locais potencialmente bloqueados. A mesa
de corte pode ser comprada em partidas migradas. O cenário mobiliado novo contém
as duas mesas. Corte, panela apoiada e itens nas mãos são persistidos.

Tempos e preços são parâmetros de teste. A implementação foi verificada em Linux
com Godot 4.6.3 e QuickJS; a Godot 4.7.2 usada pelo proprietário continua sendo o
ambiente a validar por ele. HTML não recebe esta alteração. Detalhes e comandos de
QA: [COZINHA-FISICA.md](godot/COZINHA-FISICA.md).

## 25. Inventário permanente — cinco slots

Decisão posterior do proprietário: remover o botão da mochila e mostrar o inventário permanentemente, em barra inspirada na organização de Stardew Valley, com **apenas cinco slots reais**. Clique ou teclas 1–5 selecionam o item; a seleção não pausa nem abre janela. Quantidade, ícone, tooltip e destaque identificam o conteúdo e o slot ativo. O atalho I e a janela de mochila deixam de fazer parte do acesso normal. A barra fica oculta no início e na construção; nos demais menus permanece na camada do jogo.

Geladeiras e prateleiras mantêm dez espaços. Na migração para formato 11, os excedentes do inventário antigo são preservados para recolhimento na própria barra, respeitando capacidade e qualidade. Esses registros de migração não ampliam a capacidade de cinco slots no gameplay. Esta decisão prevalece sobre referências históricas a dez espaços de mochila nas seções anteriores.

## 26. Item selecionado visível na mão

O item do slot selecionado é mostrado na mão do jogador e acompanha a direção e o deslocamento do personagem. A troca por clique ou pelas teclas 1–5 atualiza a imagem; slot vazio não mostra item. Ingredientes inteiros/cortados, utensílios, panelas e pratos usam a representação correspondente.

A apresentação do slot não transfere, reserva, consome ou duplica o item e não impede ações por si só. Se o jogador já transporta fisicamente uma panela ou prato, essa carga tem prioridade visual sobre o slot para não mostrar dois itens nas mesmas mãos. NPCs mostram apenas suas próprias cargas. Estrelas continuam restritas aos ingredientes e pratos, sem estrelas em panelas/preparo.

Verificação nativa: `qa/ItemNaMaoUI.gd`, Godot 4.7.2 Linux sem janela, `FALHAS: 0`.

## 27. Animação nas diagonais

Nas diagonais, a animação prioriza cima ou baixo enquanto houver deslocamento vertical efetivo, sem alternar a direção por pequenas diferenças numéricas entre os eixos. Quando o eixo vertical está bloqueado e resta somente movimento horizontal, a animação acompanha o deslizamento lateral. A alteração é visual e preserva velocidade, colisões e controles.

Regressão verificada na Godot 4.7.2 Linux, sem janela: as quatro diagonais foram reproduzidas com falha antes da correção e passaram depois, com variação de duração dos quadros. `MovimentoUI.gd`: `FALHAS: 0`; `movimento.test.cjs`: 13 cenários passaram.

## 28. Painel de posicionamento na construção

O painel exibe apenas quatro opções organizadas em uma linha horizontal: **Girar**, **Confirmar posição**, **Guardar e reembolsar** e **Cancelar**. O nome do móvel e os textos de posição válida, exploração do mapa e orientação da cadeira deixam de aparecer nesse painel. Ao comprar um móvel novo, a opção de guardar continua oculta. A prévia e as regras de validade permanecem ativas.
